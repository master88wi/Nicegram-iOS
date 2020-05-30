//
//  NiceFeaturesController.swift
//  TelegramUI
//
//  Created by Sergey on 10/07/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext
import TelegramNotices
import SyncCore
import NicegramLib


private final class NicegramSettingsControllerArguments {
    let togglePinnedMessage: (Bool) -> Void
    let toggleMuteSilent: (Bool) -> Void
    let toggleHideNotifyAccount: (Bool) -> Void
    let toggleShowContactsTab: (Bool) -> Void
    let toggleFixNotifications: (Bool) -> Void
    let updateShowCallsTab: (Bool) -> Void
    let toggleHidePhone: (Bool, String) -> Void
    let backupSettings: () -> Void
    let toggletgFilters: (Bool) -> Void
    let toggleClassicInfoUi: (Bool) -> Void
    let toggleSendWithKb: (Bool) -> Void
    let toggleshowGmodIcon: (Bool) -> Void
    let toggleRearCam: (Bool) -> Void
    let showTabNames: (Bool, String) -> Void
    
    init(togglePinnedMessage: @escaping (Bool) -> Void, toggleMuteSilent: @escaping (Bool) -> Void, toggleHideNotifyAccount: @escaping (Bool) -> Void,toggleShowContactsTab: @escaping (Bool) -> Void,toggleFixNotifications: @escaping (Bool) -> Void,updateShowCallsTab: @escaping (Bool) -> Void, toggleHidePhone: @escaping (Bool, String) -> Void, backupSettings: @escaping () -> Void, toggletgFilters: @escaping (Bool) -> Void,toggleClassicInfoUi: @escaping (Bool) -> Void,toggleSendWithKb: @escaping (Bool) -> Void,toggleshowGmodIcon: @escaping (Bool) -> Void, toggleRearCam: @escaping (Bool) -> Void, showTabNames: @escaping (Bool, String) -> Void) {
        self.togglePinnedMessage = togglePinnedMessage
        self.toggleMuteSilent = toggleMuteSilent
        self.toggleHideNotifyAccount = toggleHideNotifyAccount
        self.toggleShowContactsTab = toggleShowContactsTab
        self.toggleFixNotifications = toggleFixNotifications
        self.updateShowCallsTab = updateShowCallsTab
        self.toggleHidePhone = toggleHidePhone
        self.backupSettings = backupSettings
        self.toggletgFilters = toggletgFilters
        self.toggleClassicInfoUi = toggleClassicInfoUi
        self.toggleSendWithKb = toggleSendWithKb
        self.toggleshowGmodIcon = toggleshowGmodIcon
        self.toggleRearCam = toggleRearCam
        self.showTabNames = showTabNames
    }
}


private enum NicegramSettingsSection: Int32 {
    case notifications
    case tabs
    case folders
    case roundVideos
    case other
    
}

private enum NicegramSettingsEntry: ItemListNodeEntry {
    case messageNotificationsHeader(String)
    case muteSilentNotifications(String, Bool)
    case muteSilentNotificationsNotice(String)
    case hideNotifyAccount(String, Bool)
    case hideNotifyAccountNotice(String)
    
    case fixNotifications(String, Bool)
    case fixNotificationsNotice(String)
    
    case tabsHeader(String)
    case showContactsTab(String, Bool)
    case duplicateShowCalls(String, Bool)
    case showTabNames(String, Bool, String)
    
    case foldersHeader(String)
    case alternativeTgFolders(String, Bool)
    case alternativeTgFoldersNotice(String)
    
    case roundVideosHeader(String)
    case roundVideosRearCamera(String, Bool)
    
    case otherHeader(String)
    case hideNumber(String, Bool, String)
    case sendWithKb(String, Bool)
    
    case useClassicInfoUi(String, Bool)
    case showGmodIcon(String, Bool)
    
    case backupSettings(String)
    case backupNotice(String)
    
    var section: ItemListSectionId {
        switch self {
        case .messageNotificationsHeader, .muteSilentNotifications, .muteSilentNotificationsNotice, .hideNotifyAccount, .hideNotifyAccountNotice, .fixNotifications, .fixNotificationsNotice:
            return NicegramSettingsSection.notifications.rawValue
        case .tabsHeader, .showContactsTab, .duplicateShowCalls, .showTabNames:
            return NicegramSettingsSection.tabs.rawValue
        case .foldersHeader, .alternativeTgFolders, .alternativeTgFoldersNotice:
            return NicegramSettingsSection.folders.rawValue
        case .roundVideosHeader, .roundVideosRearCamera:
            return NicegramSettingsSection.roundVideos.rawValue
        default:
            return NicegramSettingsSection.other.rawValue
        }
        
    }
    
    var stableId: Int32 {
        switch self {
        case .messageNotificationsHeader:
            return 100000
        case .muteSilentNotifications:
            return 200000
        case .muteSilentNotificationsNotice:
            return 300000
        case .hideNotifyAccount:
            return 400000
        case .hideNotifyAccountNotice:
            return 500000
        case .fixNotifications:
            return 600000
        case .fixNotificationsNotice:
            return 700000
        case .tabsHeader:
            return 800000
        case .showContactsTab:
            return 900000
        case .duplicateShowCalls:
            return 1000000
        case .showTabNames:
            return 1100000
            
        case .foldersHeader:
            return 1200000
        case .alternativeTgFolders:
            return 1300000
        case .alternativeTgFoldersNotice:
            return 1400000
            
        case .roundVideosHeader:
            return 1500000
        case .roundVideosRearCamera:
            return 1600000
            
        case .otherHeader:
            return 1700000
        case .hideNumber:
            return 1800000
        case .sendWithKb:
            return 1900000
            
        case .useClassicInfoUi:
            return 2100000
        case .showGmodIcon:
            return 2200000
        case .backupSettings:
            return 2300000
        case .backupNotice:
            return 2400000
        }
    }
    
    
    static func ==(lhs: NicegramSettingsEntry, rhs: NicegramSettingsEntry) -> Bool {
        switch lhs {
            case let .messageNotificationsHeader(lhsValue):
            if case let .messageNotificationsHeader(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .muteSilentNotifications(lhsValue, lhsValue1):
            if case let .muteSilentNotifications(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .muteSilentNotificationsNotice(lhsValue):
            if case let .muteSilentNotificationsNotice(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .hideNotifyAccount(lhsValue, lhsValue1):
            if case let .hideNotifyAccount(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .hideNotifyAccountNotice(lhsValue):
            if case let .hideNotifyAccountNotice(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .fixNotifications(lhsValue, lhsValue1):
            if case let .fixNotifications(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .fixNotificationsNotice(lhsValue):
            if case let .fixNotificationsNotice(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .tabsHeader(lhsValue):
            if case let .tabsHeader(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .showContactsTab(lhsValue, lhsValue1):
            if case let .showContactsTab(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .duplicateShowCalls(lhsValue, lhsValue1):
            if case let .duplicateShowCalls(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .showTabNames(lhsValue, lhsValue1, lhsValue2):
            if case let .showTabNames(rhsValue, rhsValue1, rhsValue2) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2 {
                return true
            } else {
                return false
            }
            case let .foldersHeader(lhsValue):
            if case let .foldersHeader(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .alternativeTgFolders(lhsValue, lhsValue1):
            if case let .alternativeTgFolders(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .alternativeTgFoldersNotice(lhsValue):
            if case let .alternativeTgFoldersNotice(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .roundVideosHeader(lhsValue):
            if case let .roundVideosHeader(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .roundVideosRearCamera(lhsValue, lhsValue1):
            if case let .roundVideosRearCamera(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .otherHeader(lhsValue):
            if case let .otherHeader(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .hideNumber(lhsValue, lhsValue1, lhsValue2):
            if case let .hideNumber(rhsValue, rhsValue1, rhsValue2) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1, lhsValue2 == rhsValue2 {
                return true
            } else {
                return false
            }
            case let .sendWithKb(lhsValue, lhsValue1):
            if case let .sendWithKb(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }

            case let .useClassicInfoUi(lhsValue, lhsValue1):
            if case let .useClassicInfoUi(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .showGmodIcon(lhsValue, lhsValue1):
            if case let .showGmodIcon(rhsValue, rhsValue1) = rhs, lhsValue == rhsValue, lhsValue1 == rhsValue1 {
                return true
            } else {
                return false
            }
            case let .backupSettings(lhsValue):
            if case let .backupSettings(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .backupNotice(lhsValue):
            if case let .backupNotice(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: NicegramSettingsEntry, rhs: NicegramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NicegramSettingsControllerArguments
        switch self {
        case let .messageNotificationsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .muteSilentNotifications(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
                    arguments.toggleMuteSilent(value)
                })
        case let .muteSilentNotificationsNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .hideNotifyAccount(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
                            arguments.toggleHideNotifyAccount(value)
                        })
        case let .hideNotifyAccountNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .fixNotifications(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                            arguments.toggleFixNotifications(value)
                        })
        case let .fixNotificationsNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .tabsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .showContactsTab(text, value):
          return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
              arguments.toggleShowContactsTab(value)
          })
        case let .duplicateShowCalls(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                            arguments.updateShowCallsTab(value)
                        })
        case let .showTabNames(text, value, locale):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                            arguments.showTabNames(value, locale)
                        })
        case let .foldersHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .alternativeTgFolders(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggletgFilters(value)
            })
        case let .alternativeTgFoldersNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .roundVideosHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .roundVideosRearCamera(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleRearCam(value)
                        })
        case let .otherHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hideNumber(text, value, locale):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
                            arguments.toggleHidePhone(value, locale)
                        })
        case let .sendWithKb(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
            arguments.toggleSendWithKb(value)
        })
        case let .useClassicInfoUi(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
            arguments.toggleClassicInfoUi(value)
        })
        case let .showGmodIcon(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: false, sectionId: self.section, style: .blocks, updated: { value in
            arguments.toggleshowGmodIcon(value)
        })
        case let .backupSettings(text):
                return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.backupSettings()
            })
        case let .backupNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
    
}

private func nicegramSettingsControllerEntries(showCalls: Bool, useTgFolders: Bool, presentationData: PresentationData) -> [NicegramSettingsEntry] {
    var entries: [NicegramSettingsEntry] = []
    
    let locale = presentationData.strings.baseLanguageCode

    entries.append(.messageNotificationsHeader(presentationData.strings.Notifications_Title.uppercased()))
        entries.append(.hideNotifyAccount(l("NiceFeatures.Notifications.HideNotifyAccount", locale), NGSettings.hideNotifyAccount))
        entries.append(.hideNotifyAccountNotice( l("NiceFeatures.Notifications.HideNotifyAccountNotice", locale)))
        entries.append(.fixNotifications( l("NiceFeatures.Notifications.Fix", locale), NGSettings.fixNotifications))
        entries.append(.fixNotificationsNotice( l("NiceFeatures.Notifications.FixNotice", locale)))
        
    
    entries.append(.tabsHeader( l("NiceFeatures.Tabs.Header", locale)))
        entries.append(.showContactsTab( l("NiceFeatures.Tabs.ShowContacts", locale), NGSettings.showContactsTab))
        entries.append(.duplicateShowCalls( presentationData.strings.CallSettings_TabIcon, showCalls))
        entries.append(.showTabNames( l("NiceFeatures.Tabs.ShowNames", locale), NGSettings.showTabNames, locale))
        
    entries.append(.foldersHeader(l("NiceFeatures.Folders.Header", locale)))
        entries.append(.alternativeTgFolders(l("NiceFeatures.Folders.TgFolders", locale), useTgFolders))
        entries.append(.alternativeTgFoldersNotice(l("NiceFeatures.Folders.TgFolders.Notice", locale)))
    
    entries.append(.roundVideosHeader(l("NiceFeatures.RoundVideos.Header")))
        entries.append(.roundVideosRearCamera(l("NiceFeatures.RoundVideos.UseRearCamera", locale), NGSettings.useRearCamTelescopy))
    
    
    
    entries.append(.otherHeader( presentationData.strings.ChatSettings_Other))
        entries.append(.hideNumber( l("NiceFeatures.HideNumber", locale), NGSettings.hidePhoneSettings, locale))
        entries.append(.useClassicInfoUi( l("NiceFeatures.UseClassicInfoUi", locale), NGSettings.classicProfileUI))
        entries.append(.showGmodIcon( l("NiceFeatures.ShowGmodIcon", locale), false /*NGSettings.showGmodIcon*/))
    
        // entries.append(.backupSettings( l("NiceFeatures.BackupSettings", locale)))
        // entries.append(.backupNotice( l("NiceFeatures.BackupSettings.Notice", locale)))
    
    
    return entries
}


private struct NiceFeaturesSelectionState: Equatable {
    var updatingFiltersAmountValue: Int32? = nil
}


public func dummyCompleteDisposable() -> Signal<Void, NoError> {
    return .complete()
}

public enum FakeEntryTag: ItemListItemTag {
    public func isEqual(to other: ItemListItemTag) -> Bool {
        return true
    }

}


public func nicegramSettingsController(context: AccountContext) -> ViewController {
    var dismissImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?
    let presentationData = context.sharedContext.currentPresentationData.with {
            $0
        }
    
    func updateTabs() {
        let _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
            var settings = settings
            settings.showTab = !settings.showTab
            return settings
        }).start(completed: {
            let _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.showTab = !settings.showTab
                return settings
            }).start(completed: {
                print("TABS REFRESHED")
            })
        })
    }
    
    let locale = presentationData.strings.baseLanguageCode
    
    let arguments = NicegramSettingsControllerArguments(
    togglePinnedMessage: { value in
        // 
    }, toggleMuteSilent: { value in
        // 
    }, toggleHideNotifyAccount: { value in
        NGSettings.hideNotifyAccount = value
    }, toggleShowContactsTab: { value in
        NGSettings.showContactsTab = value
        updateTabs()
    }, toggleFixNotifications: { value in
        NGSettings.fixNotifications = value
        context.sharedContext.updateNotificationTokensRegistration()
    }, updateShowCallsTab: { value in
        let _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager, {
                $0.withUpdatedShowTab(value)
            }).start()
    
            if value {
                let _ = ApplicationSpecificNotice.incrementCallsTabTips(accountManager: context.sharedContext.accountManager, count: 4).start()
            }
    }, toggleHidePhone: { value, strLocale in
        NGSettings.hidePhoneSettings = value
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/*TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
    }, backupSettings: {
        //
    }, toggletgFilters: { value in
        let _ = context.sharedContext.accountManager.transaction ({ transaction in
            transaction.updateSharedData(ApplicationSpecificSharedDataKeys.experimentalUISettings, { settings in
                var settings = settings as? ExperimentalUISettings ?? ExperimentalUISettings.defaultSettings
                settings.foldersTabAtBottom = value
                return settings
            })
        }).start()
    }, toggleClassicInfoUi: { value in
        NGSettings.classicProfileUI = value
    }, toggleSendWithKb: { value in
        NGSettings.sendWithEnter = value
    }, toggleshowGmodIcon: { value in
        NGSettings.showGmodIcon = value
    }, toggleRearCam: { value in
        NGSettings.useRearCamTelescopy = value
    }, showTabNames: { value, strLocale in
        NGSettings.showTabNames = value
        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/* TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
        presentControllerImpl?(controller, nil)
    })
    
    let showCallsTab = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings])
        |> map { sharedData -> Bool in
            var value = true
            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings] as? CallListSettings {
                value = settings.showTab
            }
            return value
    }
    
    
    let experimentalUISettingsKey: ValueBoxKey = ApplicationSpecificSharedDataKeys.experimentalUISettings
    let displayTabsAtBottom = context.sharedContext.accountManager.sharedData(keys: Set([experimentalUISettingsKey]))
    |> map { sharedData -> Bool in
        let settings: ExperimentalUISettings = sharedData.entries[experimentalUISettingsKey] as? ExperimentalUISettings ?? ExperimentalUISettings.defaultSettings
        return settings.foldersTabAtBottom
    }
    
    let signal = combineLatest(context.sharedContext.presentationData, showCallsTab, displayTabsAtBottom)
        |> map { presentationData, showCalls, tgBottomTabs -> (ItemListControllerState, (ItemListNodeState, Any)) in

            let entries = nicegramSettingsControllerEntries(showCalls: showCalls, useTgFolders: tgBottomTabs, presentationData: presentationData)

            var index = 0
            var scrollToItem: ListViewScrollToItem?
            // workaround
            let focusOnItemTag: FakeEntryTag? = nil
            if let focusOnItemTag = focusOnItemTag {
                for entry in entries {
                    if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
                        scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
                    }
                    index += 1
                }
            }

            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("NiceFeatures.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: focusOnItemTag, initialScrollToItem: scrollToItem)

            return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}

//
//public func niceFeaturesController(context: AccountContext) -> ViewController {
//    // let statePromise = ValuePromise(NiceFeaturesSelectionState(), ignoreRepeated: true)
//    var dismissImpl: (() -> Void)?
//    var presentControllerImpl: ((ViewController, Any?) -> Void)?
//    let presentationData = context.sharedContext.currentPresentationData.with {
//        $0
//    }
//
//    var currentBrowser = Browser(rawValue: VarSimplyNiceSettings.browser) ?? Browser.Safari
//    let statePromise = ValuePromise(BrowserSelectionState(selectedBrowser: currentBrowser), ignoreRepeated: true)
//    let stateValue = Atomic(value: BrowserSelectionState(selectedBrowser: currentBrowser))
//    let updateState: ((BrowserSelectionState) -> BrowserSelectionState) -> Void = { f in
//        statePromise.set(stateValue.modify {
//            f($0)
//        })
//    }
//    var lastTabsCounter: Int32? = nil
//
//
//    func updateTabs() {
//        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//            var settings = settings
//            settings.showContactsTab = !settings.showContactsTab
//            return settings
//        }).start(completed: {
//            let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//                var settings = settings
//                settings.showContactsTab = !settings.showContactsTab
//                return settings
//            }).start(completed: {
//                print("TABS REFRESHED")
//            })
//        })
//    }
//
//    let arguments = NiceFeaturesControllerArguments(togglePinnedMessage: { value in
//        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//            var settings = settings
//            settings.pinnedMessagesNotification = value
//            return settings
//        }).start()
//    }, toggleMuteSilent: { value in
//        VarNicegramSettings.muteSoundSilent = value
//    }, toggleHideNotifyAccount: { value in
//        VarNicegramSettings.hideNotifyAccountName = value
//    }, toggleShowContactsTab: { value in
//        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//            var settings = settings
//            settings.showContactsTab = value
//            return settings
//        }).start()
//    }, toggleFixNotifications: { value in
//        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//            var settings = settings
//            settings.fixNotifications = value
//            return settings
//        }).start()
//        context.sharedContext.updateNotificationTokensRegistration()
//    }, updateShowCallsTab: { value in
//        let _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager, {
//            $0.withUpdatedShowTab(value)
//        }).start()
//
//        if value {
//            let _ = ApplicationSpecificNotice.incrementCallsTabTips(accountManager: context.sharedContext.accountManager, count: 4).start()
//        }
//    }, changeFiltersAmount: { value in
//        if lastTabsCounter != nil {
//            if Int32(value) == VarSimplyNiceSettings.maxFilters {
//                //print("Same value, returning")
//                return
//            } else {
//                lastTabsCounter = Int32(value)
//            }
//        }
//        VarSimplyNiceSettings.maxFilters = Int32(value)
//        if VarSimplyNiceSettings.maxFilters > VarSimplyNiceSettings.chatFilters.count {
//            let delta = Int(VarSimplyNiceSettings.maxFilters) - VarSimplyNiceSettings.chatFilters.count
//
//            for _ in 0...delta {
//                VarSimplyNiceSettings.chatFilters.append(.onlyNonMuted)
//            }
//        }
//        let _ = updateNiceSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
//            var settings = settings
//            settings.foo = !settings.foo
//            return settings
//        }).start()
//
//        lastTabsCounter = Int32(value)
//        updateTabs()
//
//    }, toggleShowTabNames: { value, locale in
//        VarSimplyNiceSettings.showTabNames = value
//        updateTabs()
//        // NSUbiquitousKeyValueStore.default.synchronize()
//
//        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/* TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
//
//        presentControllerImpl?(controller, nil)
//    }, toggleHidePhone: { value, locale in
//        VarSimplyNiceSettings.hideNumber = value
//        // NSUbiquitousKeyValueStore.default.synchronize()
//
//        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", locale), actions: [/*TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
//
//        presentControllerImpl?(controller, nil)
//    }, toggleUseBrowser: { value in
//        VarSimplyNiceSettings.useBrowser = value
//    }, customizeBrowser: { value in
//        VarSimplyNiceSettings.browser = value.rawValue
//        updateState { state in
//            return BrowserSelectionState(selectedBrowser: value)
//        }
//        print("CUSTOMIZE BROWSER")
//    }, openBrowserSelection: {
//        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.Use.DataStorage", presentationData.strings.baseLanguageCode).replacingOccurrences(of: "%1", with: presentationData.strings.Settings_ChatSettings, range: nil), actions: [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
//        presentControllerImpl?(controller, nil)
//        //        let controller = webBrowserSettingsController(context: context)
//        //        presentControllerImpl?(controller, nil)
//    }, backupSettings: {
//        if let exportPath = VarNicegramSettings.exportSettings() {
//            var messages: [EnqueueMessage] = []
//            let id = arc4random64()
//            let file = TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: id), partialReference: nil, resource: LocalFileReferenceMediaResource(localFilePath: exportPath, randomId: id), previewRepresentations: [], immediateThumbnailData: nil, mimeType: "application/json", size: nil, attributes: [.FileName(fileName: BACKUP_NAME)])
//            messages.append(.message(text: "", attributes: [], mediaReference: .standalone(media: file), replyToMessageId: nil, localGroupingKey: nil))
//            let _ = enqueueMessages(account: context.account, peerId: context.account.peerId, messages: messages).start()
//            let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.BackupSettings.Done", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
//            })])
//            presentControllerImpl?(controller, nil)
//        } else {
//            let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("NiceFeatures.BackupSettings.Error", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
//            })])
//            presentControllerImpl?(controller, nil)
//        }
//    }, toggleFiltersBadge: { value in
//        VarSimplyNiceSettings.filtersBadge = value
//        updateTabs()
//    }, toggleBackupIcloud: { value in
//        setUseIcloud(value)
//        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", presentationData.strings.baseLanguageCode), actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
//        })])
//        presentControllerImpl?(controller, nil)
//    }, togglebackCam: { value in
//        VarNicegramSettings.useBackCam = value
//    }, toggletgFilters: { value in
//        VarNicegramSettings.useTgFilters = value
//    }, toggleClassicInfoUi: { value in
//        VarNicegramSettings.useClassicInfoUi = value
//    }, toggleSendWithKb: { value in
//        VarNicegramSettings.sendWithKb = value
//    }, toggleshowTopChats: { value in
//        VarNicegramSettings.showTopChats = value
//        updateTabs()
//    }, toggleshowGmodIcon: { value in
//        VarNicegramSettings.showGmodIcon = value
//        let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: presentationData), title: nil, text: l("Common.RestartRequired", presentationData.strings.baseLanguageCode), actions: [/* TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
//
//        presentControllerImpl?(controller, nil)
//    }
//    )
//
//    let showCallsTab = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings])
//        |> map { sharedData -> Bool in
//            var value = true
//            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings] as? CallListSettings {
//                value = settings.showTab
//            }
//            return value
//    }
//
//    let niceSettings = getNiceSettings(accountManager: context.sharedContext.accountManager)
//
//    let signal = combineLatest(context.sharedContext.presentationData, context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.niceSettings]), showCallsTab, statePromise.get())
//        |> map { presentationData, sharedData, showCalls, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
//
//            let entries = niceFeaturesControllerEntries(niceSettings: niceSettings, showCalls: showCalls, presentationData: presentationData, simplyNiceSettings: VarSimplyNiceSettings, nicegramSettings: VarNicegramSettings, defaultWebBrowser: "")
//
//            var index = 0
//            var scrollToItem: ListViewScrollToItem?
//            // workaround
//            let focusOnItemTag: FakeEntryTag? = nil
//            if let focusOnItemTag = focusOnItemTag {
//                for entry in entries {
//                    if entry.tag?.isEqual(to: focusOnItemTag) ?? false {
//                        scrollToItem = ListViewScrollToItem(index: index, position: .top(0.0), animated: false, curve: .Default(duration: 0.0), directionHint: .Up)
//                    }
//                    index += 1
//                }
//            }
//
//            let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("NiceFeatures.Title", presentationData.strings.baseLanguageCode)), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
//            let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, ensureVisibleItemTag: focusOnItemTag, initialScrollToItem: scrollToItem)
//
//            return (controllerState, (listState, arguments))
//    }
//
//    let controller = ItemListController(context: context, state: signal)
//    dismissImpl = { [weak controller] in
//        controller?.dismiss()
//    }
//    presentControllerImpl = { [weak controller] c, a in
//        controller?.present(c, in: .window(.root), with: a)
//    }
//    return controller
//}
//Test
