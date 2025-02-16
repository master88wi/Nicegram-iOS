import Foundation
import UIKit
import TelegramCore
import Display
import SwiftSignalKit
import MonotonicTime
import AccountContext
import TelegramPresentationData
import PasscodeUI
import TelegramUIPreferences
import ImageBlur
import FastBlur
import AppLockState
import PassKit

private func isLocked(passcodeSettings: PresentationPasscodeSettings, state: LockState, isApplicationActive: Bool) -> Bool {
    if state.isManuallyLocked {
        return true
    } else if let autolockTimeout = passcodeSettings.autolockTimeout {
        var bootTimestamp: Int32 = 0
        let uptime = getDeviceUptimeSeconds(&bootTimestamp)
        let timestamp = MonotonicTimestamp(bootTimestamp: bootTimestamp, uptime: uptime)
        
        let applicationActivityTimestamp = state.applicationActivityTimestamp
        
        if let applicationActivityTimestamp = applicationActivityTimestamp {
            if timestamp.bootTimestamp != applicationActivityTimestamp.bootTimestamp {
                return true
            }
            if timestamp.uptime >= applicationActivityTimestamp.uptime + autolockTimeout {
                return true
            }
        } else {
            return true
        }
    }
    return false
}

// MARK: Nicegram DB Changes
private func getPublicCoveringViewSnapshot(window: Window1) -> UIImage? {
    let scale: CGFloat = 0.5
    let unscaledSize = window.hostView.containerView.frame.size
    
    return generateImage(CGSize(width: floor(unscaledSize.width * scale), height: floor(unscaledSize.height * scale)), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.scaleBy(x: scale, y: scale)
        UIGraphicsPushContext(context)
        window.forEachViewController { controller in
            if let tabBarController = controller as? TabBarController {
                tabBarController.controllers.forEach { controller in
                    if let controller = controller as? ChatListController {
                        controller.view.drawHierarchy(in: CGRect(origin: CGPoint(), size: unscaledSize), afterScreenUpdates: false)
                    }
                }
            }
            return true
        }
        UIGraphicsPopContext()
    }).flatMap(applyScreenshotEffectToImage)
}

private func getCoveringViewSnaphot(window: Window1) -> UIImage? {
    let scale: CGFloat = 0.5
    let unscaledSize = window.hostView.containerView.frame.size
    return generateImage(CGSize(width: floor(unscaledSize.width * scale), height: floor(unscaledSize.height * scale)), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.scaleBy(x: scale, y: scale)
        UIGraphicsPushContext(context)

        window.badgeView.alpha = 0.0
        window.forEachViewController({ controller in
            if let controller = controller as? PasscodeEntryController {
                controller.displayNode.alpha = 0.0
            }
            return true
        })
        window.hostView.containerView.drawHierarchy(in: CGRect(origin: CGPoint(), size: unscaledSize), afterScreenUpdates: false)
        window.forEachViewController({ controller in
            if let controller = controller as? PasscodeEntryController {
                controller.displayNode.alpha = 1.0
            }
            return true
        })
        window.badgeView.alpha = 1.0
        
        UIGraphicsPopContext()
    }).flatMap(applyScreenshotEffectToImage)
}

public final class AppLockContextImpl: AppLockContext {
    private let rootPath: String
    private let syncQueue = Queue()
    
    private var disposable: Disposable?
    private var autolockTimeoutDisposable: Disposable?
    
    private let applicationBindings: TelegramApplicationBindings
    private let accountManager: AccountManager<TelegramAccountManagerTypes>
    private let presentationDataSignal: Signal<PresentationData, NoError>
    private let window: Window1?
    private let rootController: UIViewController?
    // MARK: Nicegram DB Changes
    private var snapshotView: LockedWindowCoveringView?
    private var coveringView: LockedWindowCoveringView?
    private var passcodeController: PasscodeEntryController?
    
    private var timestampRenewTimer: SwiftSignalKit.Timer?
    
    private var currentStateValue: LockState
    private let currentState = Promise<LockState>()
    
    private let autolockTimeout = ValuePromise<Int32?>(nil, ignoreRepeated: true)
    private let autolockReportTimeout = ValuePromise<Int32?>(nil, ignoreRepeated: true)
    
    private let isCurrentlyLockedPromise = Promise<Bool>()
    public var isCurrentlyLocked: Signal<Bool, NoError> {
        return self.isCurrentlyLockedPromise.get()
        |> distinctUntilChanged
    }
    
    private var lastActiveTimestamp: Double?
    private var lastActiveValue: Bool = false
    // MARK: Nicegram DB Changes
    private var isCurrentAccountHidden = false
    
    private let checkCurrentAccountDisposable = MetaDisposable()
    private var hiddenAccountsAccessChallengeDataDisposable: Disposable?
    public private(set) var hiddenAccountsAccessChallengeData = [AccountRecordId:PostboxAccessChallengeData]()

    private var applicationInForegroundDisposable: Disposable?
    
    public var lockingIsCompletePromise = Promise<Bool>()
    public var onUnlockedDismiss = ValuePipe<Void>()
    public var isUnlockedAndReady: Signal<Void, NoError> {
        return self.isCurrentlyLockedPromise.get()
        |> filter { !$0 }
        |> distinctUntilChanged(isEqual: ==)
        |> mapToSignal { [weak self] _ in
            guard let strongSelf = self else { return .never() }
            
            return strongSelf.accountManager.hiddenAccountManager.unlockedAccountRecordIdPromise.get()
            |> mapToSignal { unlockedAccountRecordId in
                if unlockedAccountRecordId == nil {
                    return .single(())
                } else {
                    return strongSelf.accountManager.hiddenAccountManager.didFinishChangingAccountPromise.get() |> delay(0.1, queue: .mainQueue())
                }
            }
        }
    }
    
    public init(rootPath: String, window: Window1?, rootController: UIViewController?, applicationBindings: TelegramApplicationBindings, accountManager: AccountManager<TelegramAccountManagerTypes>, presentationDataSignal: Signal<PresentationData, NoError>, lockIconInitialFrame: @escaping () -> CGRect?) {
        assert(Queue.mainQueue().isCurrent())
        
        self.applicationBindings = applicationBindings
        self.accountManager = accountManager
        self.presentationDataSignal = presentationDataSignal
        self.rootPath = rootPath
        self.window = window
        self.rootController = rootController
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: appLockStatePath(rootPath: self.rootPath))), let current = try? JSONDecoder().decode(LockState.self, from: data) {
            self.currentStateValue = current
        } else {
            self.currentStateValue = LockState()
        }
        self.autolockTimeout.set(self.currentStateValue.autolockTimeout)
        // MARK: Nicegram DB Changes
        self.hiddenAccountsAccessChallengeDataDisposable = (accountManager.hiddenAccountManager.getHiddenAccountsAccessChallengeDataPromise.get() |> deliverOnMainQueue).start(next: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.hiddenAccountsAccessChallengeData = value
        })
        
        self.disposable = (combineLatest(queue: .mainQueue(),
            accountManager.accessChallengeData(),
            accountManager.sharedData(keys: Set([ApplicationSpecificSharedDataKeys.presentationPasscodeSettings])),
            presentationDataSignal,
            applicationBindings.applicationIsActive,
            self.currentState.get()
        )
        |> deliverOnMainQueue).startStrict(next: { [weak self] accessChallengeData, sharedData, presentationData, appInForeground, state in
            guard let strongSelf = self else {
                return
            }
            
            let passcodeSettings: PresentationPasscodeSettings = sharedData.entries[ApplicationSpecificSharedDataKeys.presentationPasscodeSettings]?.get(PresentationPasscodeSettings.self) ?? .defaultSettings
            
            let timestamp = CFAbsoluteTimeGetCurrent()
            var becameActiveRecently = false
            if appInForeground {
                if !strongSelf.lastActiveValue {
                    strongSelf.lastActiveValue = true
                    strongSelf.lastActiveTimestamp = timestamp
                    
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: appLockStatePath(rootPath: strongSelf.rootPath))), let current = try? JSONDecoder().decode(LockState.self, from: data) {
                        strongSelf.currentStateValue = current
                    }
                }
                
                if let lastActiveTimestamp = strongSelf.lastActiveTimestamp {
                    if lastActiveTimestamp + 0.5 > timestamp {
                        becameActiveRecently = true
                    }
                }
            } else {
                strongSelf.lastActiveValue = false
            }
            // MARK: Nicegram DB Changes
            strongSelf.checkCurrentAccountDisposable.set(strongSelf.updateIsCurrentAccountHiddenProperty())
            var shouldDisplayCoveringView = false
            var isCurrentlyLocked = false
            
            if !accessChallengeData.data.isLockable {
                if let passcodeController = strongSelf.passcodeController {
                    strongSelf.passcodeController = nil
                    passcodeController.dismiss()
                }
                
                strongSelf.autolockTimeout.set(nil)
                strongSelf.autolockReportTimeout.set(nil)
            } else {
                if let _ = passcodeSettings.autolockTimeout, !appInForeground {
                    shouldDisplayCoveringView = true
                }
                
                if !appInForeground {
                    if let autolockTimeout = passcodeSettings.autolockTimeout {
                        strongSelf.autolockReportTimeout.set(autolockTimeout)
                    } else if state.isManuallyLocked {
                        strongSelf.autolockReportTimeout.set(1)
                    } else {
                        strongSelf.autolockReportTimeout.set(nil)
                    }
                } else {
                    strongSelf.autolockReportTimeout.set(nil)
                }
                
                strongSelf.autolockTimeout.set(passcodeSettings.autolockTimeout)
                
                if isLocked(passcodeSettings: passcodeSettings, state: state, isApplicationActive: appInForeground) {
                    isCurrentlyLocked = true
                    
                    let biometrics: PasscodeEntryControllerBiometricsMode
                    if passcodeSettings.enableBiometrics {
                        biometrics = .enabled(passcodeSettings.biometricsDomainState)
                    } else {
                        biometrics = .none
                    }
                    
                    if let passcodeController = strongSelf.passcodeController {
                        if becameActiveRecently, case .enabled = biometrics, appInForeground {
                            passcodeController.requestBiometrics()
                        }
                        passcodeController.ensureInputFocused()
                    } else {
                        // MARK: Nicegram DB Changes
                        strongSelf.lockingIsCompletePromise.set(.single(false))

                        let passcodeController = PasscodeEntryController(applicationBindings: strongSelf.applicationBindings, accountManager: strongSelf.accountManager, appLockContext: strongSelf, presentationData: presentationData, presentationDataSignal: strongSelf.presentationDataSignal, statusBarHost: window?.statusBarHost, challengeData: accessChallengeData.data, biometrics: biometrics, arguments: PasscodeEntryControllerPresentationArguments(animated: !becameActiveRecently, lockIconInitialFrame: {
                            if let lockViewFrame = lockIconInitialFrame() {
                                return lockViewFrame
                            } else {
                                return CGRect()
                            }
                            // MARK: Nicegram DB Changes
                        }), hiddenAccountsAccessChallengeData: strongSelf.hiddenAccountsAccessChallengeData, hasPublicAccountsSignal: accountManager.hiddenAccountManager.hasPublicAccounts(accountManager: accountManager))
                        if becameActiveRecently, appInForeground {
                            // MARK: Nicegram DB Changes
                            passcodeController.presentationCompleted = { [weak passcodeController, weak self] in
                                if let strongSelf = self {
                                    strongSelf.accountManager.hiddenAccountManager.unlockedAccountRecordIdPromise.set(nil)
                                    strongSelf.lockingIsCompletePromise.set(.single(true))
                                }
                                if case .enabled = biometrics {
                                    passcodeController?.requestBiometrics()
                                }
                                passcodeController?.ensureInputFocused()
                            }
                            // MARK: Nicegram DB Changes
                        } else {
                            passcodeController.presentationCompleted = { [weak self] in
                                if let strongSelf = self {
                                    strongSelf.accountManager.hiddenAccountManager.unlockedAccountRecordIdPromise.set(nil)
                                    strongSelf.lockingIsCompletePromise.set(.single(true))
                                }
                            }
                        }
                        passcodeController.presentedOverCoveringView = true
                        passcodeController.isOpaqueWhenInOverlay = true
                        strongSelf.passcodeController = passcodeController
                        if let rootViewController = strongSelf.rootController {
                            if let _ = rootViewController.presentedViewController as? UIActivityViewController {
                            } else if let _ = rootViewController.presentedViewController as? PKPaymentAuthorizationViewController {
                            } else {
                                rootViewController.dismiss(animated: false, completion: nil)
                            }
                        }
                        // MARK: Nicegram DB Changes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if let window = strongSelf.window {
                                let coveringView = LockedWindowCoveringView(theme: presentationData.theme)
                                coveringView.updateSnapshot(getPublicCoveringViewSnapshot(window: window))
                                strongSelf.snapshotView = coveringView
                            }
                        }
                        strongSelf.window?.present(passcodeController, on: .passcode)
                    }
                } else if let passcodeController = strongSelf.passcodeController {
                    strongSelf.passcodeController = nil
                    // MARK: Nicegram DB Changes
                    passcodeController.dismiss() { [weak self] in
                        self?.onUnlockedDismiss.putNext(())
                    }
                }
            }
            
            strongSelf.updateTimestampRenewTimer(shouldRun: appInForeground && !isCurrentlyLocked)
            // MARK: Nicegram DB Changes
            strongSelf.isCurrentlyLockedPromise.set(.single(isCurrentlyLocked))
            
            if shouldDisplayCoveringView {
                if strongSelf.coveringView == nil, let window = strongSelf.window {
                    let coveringView = LockedWindowCoveringView(theme: presentationData.theme)
                    coveringView.updateSnapshot(getCoveringViewSnaphot(window: window))
                    strongSelf.coveringView = coveringView
                    window.coveringView = coveringView
                    
                    if let rootViewController = strongSelf.rootController {
                        if let _ = rootViewController.presentedViewController as? UIActivityViewController {
                        } else if let _ = rootViewController.presentedViewController as? PKPaymentAuthorizationViewController {
                        } else {
                            // MARK: Nicegram, change dismiss to alpha=0
                            // (assistant hides when app enters background)
                            rootViewController.presentedViewController?.view.alpha = 0
//                            rootViewController.dismiss(animated: false, completion: nil)
                        }
                    }
                }
            } else {
                if let _ = strongSelf.coveringView {
                    strongSelf.coveringView = nil
                    strongSelf.window?.coveringView = nil
                }
                // MARK: Nicegram, restore presentedViewController alpha
                strongSelf.rootController?.presentedViewController?.view.alpha = 1
            }
        })
        
        self.currentState.set(.single(self.currentStateValue))
        // MARK: Nicegram DB Changes
        self.applicationInForegroundDisposable = (applicationBindings.applicationInForeground
            |> distinctUntilChanged(isEqual: ==)
            |> filter { !$0 }
            |> deliverOnMainQueue).start(next: { [weak self] _ in
                guard let strongSelf = self else { return }
                
                if strongSelf.isCurrentAccountHidden {
                    strongSelf.coveringView = strongSelf.snapshotView
                    strongSelf.window?.coveringView = strongSelf.snapshotView
                }
                
            strongSelf.accountManager.hiddenAccountManager.unlockedAccountRecordIdPromise.set(nil)
        })
        
        self.autolockTimeoutDisposable = (self.autolockTimeout.get()
        |> deliverOnMainQueue).startStrict(next: { [weak self] autolockTimeout in
            self?.updateLockState { state in
                var state = state
                state.autolockTimeout = autolockTimeout
                return state
            }
        })
    }
    // MARK: Nicegram DB Changes
    private func updateIsCurrentAccountHiddenProperty() -> Disposable {
        (accountManager.currentAccountRecord(allocateIfNotExists: false)
            |> mapToQueue { [weak self] accountRecord -> Signal<Bool, NoError> in
                guard let strongSelf = self,
                      let accountRecord = accountRecord else { return .never() }
                let accountRecordId = accountRecord.0
                return strongSelf.accountManager.hiddenAccountManager.isAccountHidden(accountRecordId: accountRecordId, accountManager: strongSelf.accountManager)
            }).start() { [weak self] isAccountHidden in
                self?.isCurrentAccountHidden = isAccountHidden
            }
    }
    
    deinit {
        // MARK: Nicegram DB Changes
        self.hiddenAccountsAccessChallengeDataDisposable?.dispose()
        self.applicationInForegroundDisposable?.dispose()
        //
        
        self.disposable?.dispose()
        self.autolockTimeoutDisposable?.dispose()
    }
    
    private func updateTimestampRenewTimer(shouldRun: Bool) {
        if shouldRun {
            if self.timestampRenewTimer == nil {
                let timestampRenewTimer = SwiftSignalKit.Timer(timeout: 5.0, repeat: true, completion: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updateApplicationActivityTimestamp()
                }, queue: .mainQueue())
                self.timestampRenewTimer = timestampRenewTimer
                timestampRenewTimer.start()
            }
        } else {
            if let timestampRenewTimer = self.timestampRenewTimer {
                self.timestampRenewTimer = nil
                timestampRenewTimer.invalidate()
            }
        }
    }
    
    private func updateApplicationActivityTimestamp() {
        self.updateLockState { state in
            var bootTimestamp: Int32 = 0
            let uptime = getDeviceUptimeSeconds(&bootTimestamp)
            
            var state = state
            state.applicationActivityTimestamp = MonotonicTimestamp(bootTimestamp: bootTimestamp, uptime: uptime)
            return state
        }
    }
    
    private func updateLockState(_ f: @escaping (LockState) -> LockState) {
        Queue.mainQueue().async {
            let updatedState = f(self.currentStateValue)
            if updatedState != self.currentStateValue {
                self.currentStateValue = updatedState
                self.currentState.set(.single(updatedState))
                
                let path = appLockStatePath(rootPath: self.rootPath)
                
                self.syncQueue.async {
                    if let data = try? JSONEncoder().encode(updatedState) {
                        let _ = try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
                    }
                }
            }
        }
    }
    
    public var invalidAttempts: Signal<AccessChallengeAttempts?, NoError> {
        return self.currentState.get()
        |> map { state in
            return state.unlockAttempts.flatMap { unlockAttempts in
                return AccessChallengeAttempts(count: unlockAttempts.count, bootTimestamp: unlockAttempts.timestamp.bootTimestamp, uptime: unlockAttempts.timestamp.uptime)
            }
        }
    }
    
    public var autolockDeadline: Signal<Int32?, NoError> {
        return self.autolockReportTimeout.get()
        |> distinctUntilChanged
        |> map { value -> Int32? in
            if let value = value {
                return Int32(Date().timeIntervalSince1970) + value
            } else {
                return nil
            }
        }
    }
    
    public func lock() {
        self.updateLockState { state in
            var state = state
            state.isManuallyLocked = true
            return state
        }
    }
    
    public func unlock() {
        self.updateLockState { state in
            var state = state
            
            state.unlockAttempts = nil
            
            state.isManuallyLocked = false
            
            var bootTimestamp: Int32 = 0
            let uptime = getDeviceUptimeSeconds(&bootTimestamp)
            let timestamp = MonotonicTimestamp(bootTimestamp: bootTimestamp, uptime: uptime)
            state.applicationActivityTimestamp = timestamp
            
            return state
        }
    }
    
    public func failedUnlockAttempt() {
        self.updateLockState { state in
            var state = state
            var unlockAttempts = state.unlockAttempts ?? UnlockAttempts(count: 0, timestamp: MonotonicTimestamp(bootTimestamp: 0, uptime: 0))
            
            unlockAttempts.count += 1
            
            var bootTimestamp: Int32 = 0
            let uptime = getDeviceUptimeSeconds(&bootTimestamp)
            let timestamp = MonotonicTimestamp(bootTimestamp: bootTimestamp, uptime: uptime)
            
            unlockAttempts.timestamp = timestamp
            state.unlockAttempts = unlockAttempts
            return state
        }
    }
}
