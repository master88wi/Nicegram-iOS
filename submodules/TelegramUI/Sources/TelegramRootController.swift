// MARK: Nicegram Assistant
import CoreSwiftUI
import NGAssistantUI
import let NGCoreUI.images
import var NGCoreUI.strings
import NGUI
import SwiftUI
//
// MARK: Nicegram Grum
import NGGrumUI
//
// MARK: Nicegram imports
import NGData
//
import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContactListUI
import CallListUI
import ChatListUI
import SettingsUI
import AppBundle
import DatePickerNode
import DebugSettingsUI
import TabBarUI
import WallpaperBackgroundNode
import ChatPresentationInterfaceState
import CameraScreen
import MediaEditorScreen
import LegacyComponents
import LegacyMediaPickerUI
import LegacyCamera
import AvatarNode
import LocalMediaResources
import ImageCompression
import TextFormat
import MediaEditor

private class DetailsChatPlaceholderNode: ASDisplayNode, NavigationDetailsPlaceholderNode {
    private var presentationData: PresentationData
    private var presentationInterfaceState: ChatPresentationInterfaceState
    
    let wallpaperBackgroundNode: WallpaperBackgroundNode
    let emptyNode: ChatEmptyNode
    
    init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.presentationInterfaceState = ChatPresentationInterfaceState(chatWallpaper: self.presentationData.chatWallpaper, theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameDisplayOrder: self.presentationData.nameDisplayOrder, limitsConfiguration: context.currentLimitsConfiguration.with { $0 }, fontSize: self.presentationData.chatFontSize, bubbleCorners: self.presentationData.chatBubbleCorners, accountPeerId: context.account.peerId, mode: .standard(previewing: false), chatLocation: .peer(id: context.account.peerId), subject: nil, peerNearbyData: nil, greetingData: nil, pendingUnpinnedAllMessages: false, activeGroupCallInfo: nil, hasActiveGroupCall: false, importState: nil, threadData: nil, isGeneralThreadClosed: nil, replyMessage: nil, accountPeerColor: nil)
        
        self.wallpaperBackgroundNode = createWallpaperBackgroundNode(context: context, forChatDisplay: true, useSharedAnimationPhase: true)
        self.emptyNode = ChatEmptyNode(context: context, interaction: nil)
        
        super.init()
        
        self.addSubnode(self.wallpaperBackgroundNode)
        self.addSubnode(self.emptyNode)
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        self.presentationInterfaceState = ChatPresentationInterfaceState(chatWallpaper: self.presentationData.chatWallpaper, theme: self.presentationData.theme, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, nameDisplayOrder: self.presentationData.nameDisplayOrder, limitsConfiguration: self.presentationInterfaceState.limitsConfiguration, fontSize: self.presentationData.chatFontSize, bubbleCorners: self.presentationData.chatBubbleCorners, accountPeerId: self.presentationInterfaceState.accountPeerId, mode: .standard(previewing: false), chatLocation: self.presentationInterfaceState.chatLocation, subject: nil, peerNearbyData: nil, greetingData: nil, pendingUnpinnedAllMessages: false, activeGroupCallInfo: nil, hasActiveGroupCall: false, importState: nil, threadData: nil, isGeneralThreadClosed: nil, replyMessage: nil, accountPeerColor: nil)
        
        self.wallpaperBackgroundNode.update(wallpaper: presentationData.chatWallpaper)
    }
    
    func updateLayout(size: CGSize, needsTiling: Bool, transition: ContainedViewLayoutTransition) {
        let contentBounds = CGRect(origin: .zero, size: size)
        self.wallpaperBackgroundNode.updateLayout(size: size, displayMode: needsTiling ? .aspectFit : .aspectFill, transition: transition)
        transition.updateFrame(node: self.wallpaperBackgroundNode, frame: contentBounds)
        
        self.emptyNode.updateLayout(interfaceState: self.presentationInterfaceState, subject: .detailsPlaceholder, loadingNode: nil, backgroundNode: self.wallpaperBackgroundNode, size: contentBounds.size, insets: .zero, transition: transition)
        transition.updateFrame(node: self.emptyNode, frame: CGRect(origin: .zero, size: size))
        self.emptyNode.update(rect: contentBounds, within: contentBounds.size, transition: transition)
    }
}

public final class TelegramRootController: NavigationController, TelegramRootControllerInterface {
    
    // MARK: Nicegram Assistant
    public var assistantController: ViewController?
    //
    
    private let context: AccountContext
    
    public var rootTabController: TabBarController?
    
    public var contactsController: ContactsController?
    public var callListController: CallListController?
    public var chatListController: ChatListController?
    public var accountSettingsController: PeerInfoScreen?
    
    private var permissionsDisposable: Disposable?
    private var presentationDataDisposable: Disposable?
    private var presentationData: PresentationData
    
    private var detailsPlaceholderNode: DetailsChatPlaceholderNode?
    
    private var applicationInFocusDisposable: Disposable?
    private var storyUploadEventsDisposable: Disposable?
        
    public init(context: AccountContext) {
        self.context = context
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(mode: .automaticMasterDetail, theme: NavigationControllerTheme(presentationTheme: self.presentationData.theme))
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            if let strongSelf = self {
                strongSelf.detailsPlaceholderNode?.updatePresentationData(presentationData)
                
                let previousTheme = strongSelf.presentationData.theme
                strongSelf.presentationData = presentationData
                if previousTheme !== presentationData.theme {
                    (strongSelf.rootTabController as? TabBarControllerImpl)?.updateTheme(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData), theme: TabBarControllerTheme(rootControllerTheme: presentationData.theme))
                    strongSelf.rootTabController?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
                }
            }
        })
        
        if context.sharedContext.applicationBindings.isMainApp {
            self.applicationInFocusDisposable = (context.sharedContext.applicationBindings.applicationIsActive
            |> distinctUntilChanged
            |> deliverOn(Queue.mainQueue())).startStrict(next: { value in
                context.sharedContext.mainWindow?.setForceBadgeHidden(!value)
            })
            
            self.storyUploadEventsDisposable = (context.engine.messages.allStoriesUploadEvents()
            |> deliverOnMainQueue).startStrict(next: { [weak self] event in
                guard let self else {
                    return
                }
                let (stableId, id) = event
                moveStorySource(engine: self.context.engine, peerId: self.context.account.peerId, from: Int64(stableId), to: Int64(id))
            })
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.permissionsDisposable?.dispose()
        self.presentationDataDisposable?.dispose()
        self.applicationInFocusDisposable?.dispose()
        self.storyUploadEventsDisposable?.dispose()
    }
    
    // MARK: Nicegram Assistant
    private var didAppear = false
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 15.0, *), !didAppear {
            Task {
                let canPresent = { [weak self] in
                    guard let window = self?.context.sharedContext.mainWindow else {
                        return false
                    }
                    return !window.hasOverlayController()
                }
                await AssistantUITgHelper.showAlertsFromHomeIfNeeded(
                    canPresent: canPresent,
                    showAssitantTooltip: { [weak self] in
                        self?.showNicegramTooltip(
                            backgroundColor: .secondarySystemBackground,
                            content: { AssistantPopover() }
                        )
                    },
                    showGrumTooltip: { [weak self] in
                        self?.showNicegramTooltip(
                            backgroundColor: .grumBg,
                            content: {
                                GrumPopover(
                                    openAssistant: {
                                        AssistantUITgHelper.routeToAssistant(
                                            source: .generic
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
            }
        }
        
        didAppear = true
    }
    //
    
    public func getContactsController() -> ViewController? {
        return self.contactsController
    }
    
    public func getChatsController() -> ViewController? {
        return self.chatListController
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let needsRootWallpaperBackgroundNode: Bool
        if case .regular = layout.metrics.widthClass {
            needsRootWallpaperBackgroundNode = true
        } else {
            needsRootWallpaperBackgroundNode = false
        }
        
        if needsRootWallpaperBackgroundNode {
            let detailsPlaceholderNode: DetailsChatPlaceholderNode
            if let current = self.detailsPlaceholderNode {
                detailsPlaceholderNode = current
            } else {
                detailsPlaceholderNode = DetailsChatPlaceholderNode(context: self.context)
                detailsPlaceholderNode.wallpaperBackgroundNode.update(wallpaper: self.presentationData.chatWallpaper)
                self.detailsPlaceholderNode = detailsPlaceholderNode
            }
            self.updateDetailsPlaceholderNode(detailsPlaceholderNode)
        } else if let _ = self.detailsPlaceholderNode {
            self.detailsPlaceholderNode = nil
            self.updateDetailsPlaceholderNode(nil)
        }
    
        super.containerLayoutUpdated(layout, transition: transition)
    }
    
    public func addRootControllers(showCallsTab: Bool) {
        // MARK: Nicegram (showTabNames)
        let tabBarController = TabBarControllerImpl(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), theme: TabBarControllerTheme(rootControllerTheme: self.presentationData.theme), showTabNames: NGSettings.showTabNames)
        tabBarController.navigationPresentation = .master
        let chatListController = self.context.sharedContext.makeChatListController(context: self.context, location: .chatList(groupId: .root), controlsHistoryPreload: true, hideNetworkActivityStatus: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            chatListController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
        }
        let callListController = CallListController(context: self.context, mode: .tab)
        
        var controllers: [ViewController] = []
        
        let contactsController = ContactsController(context: self.context)
        contactsController.switchToChatsController = {  [weak self] in
            self?.openChatsController(activateSearch: false)
        }
        // MARK: Nicegram
        if NGSettings.showContactsTab {
            controllers.append(contactsController)
        }
        //
        
        if showCallsTab {
            controllers.append(callListController)
        }
        controllers.append(chatListController)
        
        // MARK: Nicegram Assistant
        if #available(iOS 15.0, *) {
            let assistantController = NativeControllerWrapper(
                controller: AssistantUITgHelper.assistantTab(
                    close: nil
                ),
                accountContext: self.context,
                adjustSafeArea: true
            )
            assistantController.tabBarItem = UITabBarItem(
                title: NGCoreUI.strings.assistantTabTitle(),
                image: NGCoreUI.images.logoNicegram(),
                tag: 0
            )
            
            self.assistantController = assistantController
            
            if NGSettings.showNicegramTab {
                controllers.append(assistantController)
            }
            
            AssistantUITgHelper.routeToAssistantImpl = { [weak self] source in
                guard let self, let rootTabController else {
                    return
                }
                
                let assistantIndex = rootTabController.controllers.firstIndex {
                    $0 === assistantController
                }
                
                if let assistantIndex {
                    AssistantUITgHelper.assistantSource = source
                    
                    popToRoot(animated: true)
                    rootTabController.selectedIndex = assistantIndex
                } else {
                    AssistantUITgHelper.presentAssistantModally(
                        source: source
                    )
                }
            }
        }
        //
        
        var restoreSettignsController: (ViewController & SettingsController)?
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            restoreSettignsController = sharedContext.switchingData.settingsController
        }
        restoreSettignsController?.updateContext(context: self.context)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            sharedContext.switchingData = (nil, nil, nil)
        }
        
        let accountSettingsController = PeerInfoScreenImpl(context: self.context, updatedPresentationData: nil, peerId: self.context.account.peerId, avatarInitiallyExpanded: false, isOpenedFromChat: false, nearbyPeerDistance: nil, reactionSourceMessageId: nil, callMessages: [], isSettings: true)
        accountSettingsController.tabBarItemDebugTapAction = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.pushViewController(debugController(sharedContext: strongSelf.context.sharedContext, context: strongSelf.context))
        }
        accountSettingsController.parentController = self
        controllers.append(accountSettingsController)
                
        // MARK: Nicegram Assistant
        // calculate chatListControllerIndex (instead of (controllers.count - 2))
        let chatListControllerIndex = controllers.firstIndex {
            $0 is ChatListController
        } ?? 0
        tabBarController.setControllers(controllers, selectedIndex: restoreSettignsController != nil ? (controllers.count - 1) : chatListControllerIndex)
        
        self.contactsController = contactsController
        self.callListController = callListController
        self.chatListController = chatListController
        self.accountSettingsController = accountSettingsController
        self.rootTabController = tabBarController
        self.pushViewController(tabBarController, animated: false)
    }
        
    public func updateRootControllers(showCallsTab: Bool) {
        guard let rootTabController = self.rootTabController as? TabBarControllerImpl else {
            return
        }
        var controllers: [ViewController] = []
        // MARK: Nicegram
        if NGSettings.showContactsTab {
            controllers.append(self.contactsController!)
        }
        //
        if showCallsTab {
            controllers.append(self.callListController!)
        }
        controllers.append(self.chatListController!)
        
        // MARK: Nicegram Assistant
        if let assistantController,
           NGSettings.showNicegramTab {
            controllers.append(assistantController)
        }
        //
        
        controllers.append(self.accountSettingsController!)
        
        rootTabController.setControllers(controllers, selectedIndex: nil)
    }
    
    // MARK: Nicegram Assistant
    @available(iOS 13.0, *)
    public func showNicegramTooltip<Content: View>(
        backgroundColor: UIColor,
        content: () -> Content
    ) {
        guard let rootTabController = rootTabController as? TabBarControllerImpl else {
            return
        }
        
        let index = rootTabController.controllers.firstIndex {
            $0 === assistantController
        }
        guard let index else {
            return
        }
        
        let tabBarView = rootTabController.tabBarView
        let tabWidth = tabBarView.frame.width / CGFloat(rootTabController.controllers.count)
        
        let sourceRect = CGRect(
            x: tabWidth * CGFloat(index),
            y: 0,
            width: tabWidth,
            height: tabBarView.frame.height
        )
        
        Popover.show(
            on: rootTabController,
            sourceView: tabBarView,
            sourceRect: sourceRect,
            backgroundColor: backgroundColor,
            permittedArrowDirections: .down,
            content: content
        )
    }
    //
    
    public func openChatsController(activateSearch: Bool, filter: ChatListSearchFilter = .chats, query: String? = nil) {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        if activateSearch {
            self.popToRoot(animated: false)
        }
        
        if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
            rootTabController.selectedIndex = index
        }
        
        if activateSearch {
            self.chatListController?.activateSearch(filter: filter, query: query)
        }
    }
    
    public func openRootCompose() {
        self.chatListController?.activateCompose()
    }
    
    public func openRootCamera() {
        guard let controller = self.viewControllers.last as? ViewController else {
            return
        }
        controller.view.endEditing(true)
        presentedLegacyShortcutCamera(context: self.context, saveCapturedMedia: false, saveEditedPhotos: false, mediaGrouping: true, parentController: controller)
    }
    
    @discardableResult
    public func openStoryCamera(customTarget: EnginePeer.Id?, transitionIn: StoryCameraTransitionIn?, transitionedIn: @escaping () -> Void, transitionOut: @escaping (Stories.PendingTarget?, Bool) -> StoryCameraTransitionOut?) -> StoryCameraTransitionInCoordinator? {
        guard let controller = self.viewControllers.last as? ViewController else {
            return nil
        }
        controller.view.endEditing(true)
        
        let context = self.context
        
        var storyTarget: Stories.PendingTarget?
        var isPeerArchived = false
        var updatedTransitionOut: ((Stories.PendingTarget?, Bool) -> StoryCameraTransitionOut?)?
        
        var presentImpl: ((ViewController) -> Void)?
        var returnToCameraImpl: (() -> Void)?
        var dismissCameraImpl: (() -> Void)?
        var showDraftTooltipImpl: (() -> Void)?
        let cameraController = CameraScreen(
            context: context,
            transitionIn: transitionIn.flatMap {
                if let sourceView = $0.sourceView {
                    return CameraScreen.TransitionIn(
                        sourceView: sourceView,
                        sourceRect: $0.sourceRect,
                        sourceCornerRadius: $0.sourceCornerRadius
                    )
                } else {
                    return nil
                }
            },
            transitionOut: { finished in
                if let transitionOut = (updatedTransitionOut ?? transitionOut)(finished ? storyTarget : nil, isPeerArchived), let destinationView = transitionOut.destinationView {
                    return CameraScreen.TransitionOut(
                        destinationView: destinationView,
                        destinationRect: transitionOut.destinationRect,
                        destinationCornerRadius: transitionOut.destinationCornerRadius
                    )
                } else {
                    return nil
                }
            },
            completion: { result, resultTransition, dismissed in
                let subject: Signal<MediaEditorScreen.Subject?, NoError> = result
                |> map { value -> MediaEditorScreen.Subject? in
                    func editorPIPPosition(_ position: CameraScreen.PIPPosition) -> MediaEditorScreen.PIPPosition {
                        switch position {
                        case .topLeft:
                            return .topLeft
                        case .topRight:
                            return .topRight
                        case .bottomLeft:
                            return .bottomLeft
                        case .bottomRight:
                            return .bottomRight
                        }
                    }
                    switch value {
                    case .pendingImage:
                        return nil
                    case let .image(image):
                        return .image(image.image, PixelDimensions(image.image.size), image.additionalImage, editorPIPPosition(image.additionalImagePosition))
                    case let .video(video):
                        return .video(video.videoPath, video.coverImage, video.mirror, video.additionalVideoPath, video.additionalCoverImage, video.dimensions, video.duration, video.positionChangeTimestamps, editorPIPPosition(video.additionalVideoPosition))
                    case let .asset(asset):
                        return .asset(asset)
                    case let .draft(draft):
                        return .draft(draft, nil)
                    }
                }
                
                var transitionIn: MediaEditorScreen.TransitionIn?
                if let resultTransition, let sourceView = resultTransition.sourceView {
                    transitionIn = .gallery(
                        MediaEditorScreen.TransitionIn.GalleryTransitionIn(
                            sourceView: sourceView,
                            sourceRect: resultTransition.sourceRect,
                            sourceImage: resultTransition.sourceImage
                        )
                    )
                } else {
                    transitionIn = .camera
                }
                
                let controller = MediaEditorScreen(
                    context: context,
                    subject: subject,
                    customTarget: customTarget,
                    isEditing: false,
                    transitionIn: transitionIn,
                    transitionOut: { finished, isNew in
                        if finished, let transitionOut = (updatedTransitionOut ?? transitionOut)(storyTarget, false), let destinationView = transitionOut.destinationView {
                            return MediaEditorScreen.TransitionOut(
                                destinationView: destinationView,
                                destinationRect: transitionOut.destinationRect,
                                destinationCornerRadius: transitionOut.destinationCornerRadius
                            )
                        } else if !finished, let resultTransition, let (destinationView, destinationRect) = resultTransition.transitionOut(isNew) {
                            return MediaEditorScreen.TransitionOut(
                                destinationView: destinationView,
                                destinationRect: destinationRect,
                                destinationCornerRadius: 0.0
                            )
                        } else {
                            return nil
                        }
                    }, completion: { [weak self] randomId, mediaResult, mediaAreas, caption, options, stickers, commit in
                        guard let self, let mediaResult else {
                            dismissCameraImpl?()
                            commit({})
                            return
                        }
                        
                        let target: Stories.PendingTarget
                        let targetPeerId: EnginePeer.Id
                        if let customTarget {
                            target = .peer(customTarget)
                            targetPeerId = customTarget
                        } else {
                            if let sendAsPeerId = options.sendAsPeerId {
                                target = .peer(sendAsPeerId)
                                targetPeerId = sendAsPeerId
                            } else {
                                target = .myStories
                                targetPeerId = context.account.peerId
                            }
                        }
                        storyTarget = target
                        
                        let _ = (self.context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: targetPeerId))
                        |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
                            guard let self, let peer else {
                                return
                            }
                            
                            if case let .user(user) = peer {
                                isPeerArchived = user.storiesHidden ?? false
                            } else if case let .channel(channel) = peer {
                                isPeerArchived = channel.storiesHidden ?? false
                            }
                            
                            let context = self.context
                            if let rootTabController = self.rootTabController {
                                if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
                                    rootTabController.selectedIndex = index
                                }
                            }
                            
                            let completionImpl: () -> Void = { [weak self] in
                                guard let self else {
                                    return
                                }
                                
                                var chatListController: ChatListControllerImpl?
                                
                                if isPeerArchived {
                                    var viewControllers = self.viewControllers
                                    
                                    let archiveController = ChatListControllerImpl(context: context, location: .chatList(groupId: .archive), controlsHistoryPreload: false, hideNetworkActivityStatus: false, previewing: false, enableDebugActions: false)
                                    updatedTransitionOut = archiveController.storyCameraTransitionOut()
                                    chatListController = archiveController
                                    viewControllers.insert(archiveController, at: 1)
                                    self.setViewControllers(viewControllers, animated: false)
                                } else {
                                    chatListController = self.chatListController as? ChatListControllerImpl
                                }
                                 
                                if let chatListController {
                                    let _ = (chatListController.hasPendingStories
                                    |> filter { $0 }
                                    |> take(1)
                                    |> timeout(isPeerArchived ? 0.5 : 0.25, queue: .mainQueue(), alternate: .single(true))
                                    |> deliverOnMainQueue).startStandalone(completed: { [weak chatListController] in
                                        guard let chatListController else {
                                            return
                                        }
                                        
                                        chatListController.scrollToStories(peerId: targetPeerId)
                                        Queue.mainQueue().justDispatch {
                                            commit({})
                                        }
                                    })
                                } else {
                                    Queue.mainQueue().justDispatch {
                                        commit({})
                                    }
                                }
                            }
                            
                            if let _ = self.chatListController as? ChatListControllerImpl {
                                switch mediaResult {
                                case let .image(image, dimensions):
                                    let tempFile = TempBox.shared.tempFile(fileName: "file")
                                    defer {
                                        TempBox.shared.dispose(tempFile)
                                    }
                                    if let imageData = compressImageToJPEG(image, quality: 0.7, tempFilePath: tempFile.path) {
                                        let entities = generateChatInputTextEntities(caption)
                                        Logger.shared.log("MediaEditor", "Calling uploadStory for image, randomId \(randomId)")
                                        let _ = (context.engine.messages.uploadStory(target: target, media: .image(dimensions: dimensions, data: imageData, stickers: stickers), mediaAreas: mediaAreas, text: caption.string, entities: entities, pin: options.pin, privacy: options.privacy, isForwardingDisabled: options.isForwardingDisabled, period: options.timeout, randomId: randomId)
                                        |> deliverOnMainQueue).startStandalone(next: { stableId in
                                            moveStorySource(engine: context.engine, peerId: context.account.peerId, from: randomId, to: Int64(stableId))
                                        })
                                        
                                        completionImpl()
                                    }
                                case let .video(content, firstFrameImage, values, duration, dimensions):
                                    let adjustments: VideoMediaResourceAdjustments
                                    if let valuesData = try? JSONEncoder().encode(values) {
                                        let data = MemoryBuffer(data: valuesData)
                                        let digest = MemoryBuffer(data: data.md5Digest())
                                        adjustments = VideoMediaResourceAdjustments(data: data, digest: digest, isStory: true)
                                        
                                        let resource: TelegramMediaResource
                                        switch content {
                                        case let .imageFile(path):
                                            resource = LocalFileVideoMediaResource(randomId: Int64.random(in: .min ... .max), path: path, adjustments: adjustments)
                                        case let .videoFile(path):
                                            resource = LocalFileVideoMediaResource(randomId: Int64.random(in: .min ... .max), path: path, adjustments: adjustments)
                                        case let .asset(localIdentifier):
                                            resource = VideoLibraryMediaResource(localIdentifier: localIdentifier, conversion: .compress(adjustments))
                                        }
                                        let tempFile = TempBox.shared.tempFile(fileName: "file")
                                        defer {
                                            TempBox.shared.dispose(tempFile)
                                        }
                                        let imageData = firstFrameImage.flatMap { compressImageToJPEG($0, quality: 0.6, tempFilePath: tempFile.path) }
                                        let firstFrameFile = imageData.flatMap { data -> TempBoxFile? in
                                            let file = TempBox.shared.tempFile(fileName: "image.jpg")
                                            if let _ = try? data.write(to: URL(fileURLWithPath: file.path)) {
                                                return file
                                            } else {
                                                return nil
                                            }
                                        }
                                        Logger.shared.log("MediaEditor", "Calling uploadStory for video, randomId \(randomId)")
                                        let entities = generateChatInputTextEntities(caption)
                                        let _ = (context.engine.messages.uploadStory(target: target, media: .video(dimensions: dimensions, duration: duration, resource: resource, firstFrameFile: firstFrameFile, stickers: stickers), mediaAreas: mediaAreas, text: caption.string, entities: entities, pin: options.pin, privacy: options.privacy, isForwardingDisabled: options.isForwardingDisabled, period: options.timeout, randomId: randomId)
                                        |> deliverOnMainQueue).startStandalone(next: { stableId in
                                            moveStorySource(engine: context.engine, peerId: context.account.peerId, from: randomId, to: Int64(stableId))
                                        })
                                        
                                        completionImpl()
                                    }
                                }
                            }
                            
                            dismissCameraImpl?()
                        })
                    } as (Int64, MediaEditorScreen.Result?, [MediaArea], NSAttributedString, MediaEditorResultPrivacy, [TelegramMediaFile], @escaping (@escaping () -> Void) -> Void) -> Void
                )
                controller.cancelled = { showDraftTooltip in
                    if showDraftTooltip {
                        showDraftTooltipImpl?()
                    }
                    returnToCameraImpl?()
                }
                controller.dismissed = {
                    dismissed()
                }
                presentImpl?(controller)
            }
        )
        cameraController.transitionedIn = transitionedIn
        controller.push(cameraController)
        presentImpl = { [weak cameraController] c in
            if let navigationController = cameraController?.navigationController as? NavigationController {
                var controllers = navigationController.viewControllers
                controllers.append(c)
                navigationController.setViewControllers(controllers, animated: false)
            }
        }
        dismissCameraImpl = { [weak cameraController] in
            cameraController?.dismiss(animated: false)
        }
        returnToCameraImpl = { [weak cameraController] in
            if let cameraController {
                cameraController.returnFromEditor()
            }
        }
        showDraftTooltipImpl = { [weak cameraController] in
            if let cameraController {
                cameraController.presentDraftTooltip()
            }
        }
        return StoryCameraTransitionInCoordinator(
            animateIn: { [weak cameraController] in
                if let cameraController {
                    cameraController.updateTransitionProgress(0.0, transition: .immediate)
                    cameraController.completeWithTransitionProgress(1.0, velocity: 0.0, dismissing: false)
                }
            },
            updateTransitionProgress: { [weak cameraController] transitionFraction in
                if let cameraController {
                    cameraController.updateTransitionProgress(transitionFraction, transition: .immediate)
                }
            },
            completeWithTransitionProgressAndVelocity: { [weak cameraController] transitionFraction, velocity in
                if let cameraController {
                    cameraController.completeWithTransitionProgress(transitionFraction, velocity: velocity, dismissing: false)
                }
            })
    }
    
    public func openSettings() {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        self.popToRoot(animated: false)
    
        if let index = rootTabController.controllers.firstIndex(where: { $0 is PeerInfoScreenImpl }) {
            rootTabController.selectedIndex = index
        }
    }
}
