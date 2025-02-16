//
//  NicegramSettingsController.swift
//  NicegramUI
//
//  Created by Sergey Akentev.
//  Copyright © 2020 Nicegram. All rights reserved.
//

// MARK: Imports

import AccountContext
import Display
import FeatImagesHubUI
import FeatPartners
import Foundation
import ItemListUI
import NGData
import NGLogging
import NGStrings
import Postbox
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TelegramNotices
import TelegramPresentationData
import TelegramUIPreferences
import UIKit
import class NGCoreUI.SharedLoadingView
import NGEnv
import NGWebUtils
import NGAiChatUI
import NGCardUI
import NGAppCache
import var NGCoreUI.strings
import NGDoubleBottom
import NGQuickReplies
import NGRemoteConfig
import NGSecretMenu
import NGStats

fileprivate let LOGTAG = extractNameFromPath(#file)

// MARK: Arguments struct

private final class NicegramSettingsControllerArguments {
    let context: AccountContext
    let accountsContexts: [(AccountContext, EnginePeer)]
    let presentController: (ViewController, ViewControllerPresentationArguments?) -> Void
    let pushController: (ViewController) -> Void
    let getRootController: () -> UIViewController?
    let updateTabs: () -> Void

    init(context: AccountContext, accountsContexts: [(AccountContext, EnginePeer)], presentController: @escaping (ViewController, ViewControllerPresentationArguments?) -> Void, pushController: @escaping (ViewController) -> Void, getRootController: @escaping () -> UIViewController?, updateTabs: @escaping () -> Void) {
        self.context = context
        self.accountsContexts = accountsContexts
        self.presentController = presentController
        self.pushController = pushController
        self.getRootController = getRootController
        self.updateTabs = updateTabs
    }
}

// MARK: Sections

private enum NicegramSettingsControllerSection: Int32 {
    case SecretMenu
    case Unblock
    case Tabs
    case Folders
    case RoundVideos
    case Account
    case Other
    case QuickReplies
    case ShareChannelsInfo
    case PinnedBots
}


private enum EasyToggleType {
    case sendWithEnter
    case showProfileId
    case showRegDate
    case hideReactions
    case hideStories
    case hidePartnerIntegrations
}


// MARK: ItemListNodeEntry

private enum NicegramSettingsControllerEntry: ItemListNodeEntry {
    case TabsHeader(String)
    case showContactsTab(String, Bool)
    case showCallsTab(String, Bool)
    case showNicegramTab
    case showTabNames(String, Bool)
    
    case pinnedBotsHeader
    
    @available(iOS 13.0, *)
    case aiPin
    
    @available(iOS 13.0, *)
    case pstPin
    
    @available(iOS 15.0, *)
    case imagesHubPin

    case FoldersHeader(String)
    case foldersAtBottom(String, Bool)
    case foldersAtBottomNotice(String)

    case RoundVideosHeader(String)
    case startWithRearCam(String, Bool)
    case shouldDownloadVideo(String, Bool)

    case OtherHeader(String)
    case hidePhoneInSettings(String, Bool)
    case hidePhoneInSettingsNotice(String)
    
    case easyToggle(Int32, EasyToggleType, String, Bool)
    
    case Account(String)
    case doubleBottom(String)
    
    case unblockHeader(String)
    case unblock(String, URL)
    
    case quickReplies(String)
    
    case secretMenu(String)
    
    case shareChannelsInfoToggle(String, Bool)
    case shareChannelsInfoNote(String)

    // MARK: Section

    var section: ItemListSectionId {
        switch self {
        case .TabsHeader, .showContactsTab, .showCallsTab, .showNicegramTab, .showTabNames:
            return NicegramSettingsControllerSection.Tabs.rawValue
        case .FoldersHeader, .foldersAtBottom, .foldersAtBottomNotice:
            return NicegramSettingsControllerSection.Folders.rawValue
        case .RoundVideosHeader, .startWithRearCam, .shouldDownloadVideo:
            return NicegramSettingsControllerSection.RoundVideos.rawValue
        case .OtherHeader, .hidePhoneInSettings, .hidePhoneInSettingsNotice, .easyToggle:
            return NicegramSettingsControllerSection.Other.rawValue
        case .quickReplies:
            return NicegramSettingsControllerSection.QuickReplies.rawValue
        case .unblockHeader, .unblock:
            return NicegramSettingsControllerSection.Unblock.rawValue
        case .Account, .doubleBottom:
            return NicegramSettingsControllerSection.Account.rawValue
        case .secretMenu:
            return NicegramSettingsControllerSection.SecretMenu.rawValue
        case .shareChannelsInfoToggle, .shareChannelsInfoNote:
            return NicegramSettingsControllerSection.ShareChannelsInfo.rawValue
        case .pinnedBotsHeader, .aiPin, .pstPin, .imagesHubPin:
            return NicegramSettingsControllerSection.PinnedBots.rawValue
        }
    }

    // MARK: SectionId

    var stableId: Int32 {
        switch self {
        case .secretMenu:
            return 700
            
        case .unblockHeader:
            return 800
            
        case .unblock:
            return 900
            
        case .TabsHeader:
            return 1300

        case .showContactsTab:
            return 1400

        case .showCallsTab:
            return 1500
            
        case .showNicegramTab:
            return 1550
            
        case .showTabNames:
            return 1600

        case .FoldersHeader:
            return 1700

        case .foldersAtBottom:
            return 1800

        case .foldersAtBottomNotice:
            return 1900
            
        case .pinnedBotsHeader:
            return 1950
        case .aiPin:
            return 1951
        case .pstPin:
            return 1952
        case .imagesHubPin:
            return 1953

        case .RoundVideosHeader:
            return 2000

        case .startWithRearCam:
            return 2100
            
        case .shouldDownloadVideo:
            return 2101
            
        case .OtherHeader:
            return 2200

        case .hidePhoneInSettings:
            return 2300

        case .hidePhoneInSettingsNotice:
            return 2400

        case .quickReplies:
            return 2450

        case .Account:
            return 2500
            
        case .doubleBottom:
            return 2700
            
        case let .easyToggle(index, _, _, _):
            return 5000 + Int32(index)
            
        case .shareChannelsInfoToggle:
            return 6000
        case .shareChannelsInfoNote:
            return 6001
        }
    }

    // MARK: == overload

    static func == (lhs: NicegramSettingsControllerEntry, rhs: NicegramSettingsControllerEntry) -> Bool {
        switch lhs {
        case let .TabsHeader(lhsText):
            if case let .TabsHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .showContactsTab(lhsText, lhsVar0Bool):
            if case let .showContactsTab(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .showCallsTab(lhsText, lhsVar0Bool):
            if case let .showCallsTab(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
            
        case .showNicegramTab:
            if case .showNicegramTab = rhs {
                return true
            } else {
                return false
            }

        case let .showTabNames(lhsText, lhsVar0Bool):
            if case let .showTabNames(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .FoldersHeader(lhsText):
            if case let .FoldersHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .foldersAtBottom(lhsText, lhsVar0Bool):
            if case let .foldersAtBottom(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .foldersAtBottomNotice(lhsText):
            if case let .foldersAtBottomNotice(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .RoundVideosHeader(lhsText):
            if case let .RoundVideosHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .startWithRearCam(lhsText, lhsVar0Bool):
            if case let .startWithRearCam(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
        
        case let .shouldDownloadVideo(lhsText, lhsVar0Bool):
            if case let .shouldDownloadVideo(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }
            
        case let .OtherHeader(lhsText):
            if case let .OtherHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }

        case let .hidePhoneInSettings(lhsText, lhsVar0Bool):
            if case let .hidePhoneInSettings(rhsText, rhsVar0Bool) = rhs, lhsText == rhsText, lhsVar0Bool == rhsVar0Bool {
                return true
            } else {
                return false
            }

        case let .hidePhoneInSettingsNotice(lhsText):
            if case let .hidePhoneInSettingsNotice(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .easyToggle(lhsIndex, _, lhsText, lhsValue):
            if case let .easyToggle(rhsIndex, _, rhsText, rhsValue) = rhs, lhsIndex == rhsIndex, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .unblockHeader(lhsText):
            if case let .unblockHeader(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .unblock(lhsText, lhsUrl):
            if case let .unblock(rhsText, rhsUrl) = rhs, lhsText == rhsText, lhsUrl == rhsUrl {
                return true
            } else {
                return false
            }
        case let .Account(lhsText):
            if case let .Account(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .doubleBottom(lhsText):
            if case let .doubleBottom(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .quickReplies(lhsText):
            if case let .quickReplies(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .secretMenu(lhsText):
            if case let .secretMenu(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case let .shareChannelsInfoToggle(lhsText, lhsValue):
            if case let .shareChannelsInfoToggle(rhsText, rhsValue) = rhs, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
        case let .shareChannelsInfoNote(lhsText):
            if case let .shareChannelsInfoNote(rhsText) = rhs, lhsText == rhsText {
                return true
            } else {
                return false
            }
        case .pinnedBotsHeader:
            if case .pinnedBotsHeader = rhs {
                return true
            } else {
                return false
            }
        case .aiPin:
            if case .aiPin = rhs {
                return true
            } else {
                return false
            }
        case .pstPin:
            if case .pstPin = rhs {
                return true
            } else {
                return false
            }
        case .imagesHubPin:
            if case .imagesHubPin = rhs {
                return true
            } else {
                return false
            }
        }
    }

    // MARK: < overload

    static func < (lhs: NicegramSettingsControllerEntry, rhs: NicegramSettingsControllerEntry) -> Bool {
        lhs.stableId < rhs.stableId
    }

    // MARK: ListViewItem
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NicegramSettingsControllerArguments
        let locale = presentationData.strings.baseLanguageCode
        switch self {
        case let .TabsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .showContactsTab(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showContactsTab] invoked with \(value)", LOGTAG)
                NGSettings.showContactsTab = value
                arguments.updateTabs()
            })
            
        case let .showCallsTab(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showCallsTab] invoked with \(value)", LOGTAG)
                let _ = updateCallListSettingsInteractively(accountManager: arguments.context.sharedContext.accountManager, {
                    $0.withUpdatedShowTab(value)
                }).start()
                
                if value {
                    let _ = ApplicationSpecificNotice.incrementCallsTabTips(accountManager: arguments.context.sharedContext.accountManager, count: 4).start()
                }
            })
            
        case .showNicegramTab:
            return ItemListSwitchItem(presentationData: presentationData, title: strings.showAssistantTab(), value: NGSettings.showNicegramTab, enabled: true, sectionId: section, style: .blocks, updated: { value in
                NGSettings.showNicegramTab = value
                arguments.updateTabs()
            })
            
        case let .showTabNames(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[showTabNames] invoked with \(value)", LOGTAG)
                let locale = presentationData.strings.baseLanguageCode  
                NGSettings.showTabNames = value
                let controller = standardTextAlertController(theme: AlertControllerTheme(presentationData: arguments.context.sharedContext.currentPresentationData.with {
                    $0
                }), title: nil, text: l("Common.RestartRequired", locale), actions: [/* TextAlertAction(type: .destructiveAction, title: l("Common.ExitNow", locale), action: { preconditionFailure() }),*/ TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {})])
                arguments.presentController(controller, nil)
            })
            
        case let .FoldersHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .foldersAtBottom(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[foldersAtBottom] invoked with \(value)", LOGTAG)
                let _ = arguments.context.sharedContext.accountManager.transaction ({ transaction in
                    transaction.updateSharedData(ApplicationSpecificSharedDataKeys.experimentalUISettings, { settings in
                        var settings = settings?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings
                        settings.foldersTabAtBottom = value
                        return PreferencesEntry(settings)
                    })
                }).start()
            })
            
        case let .foldersAtBottomNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
            
        case let .RoundVideosHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .startWithRearCam(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[startWithRearCam] invoked with \(value)", LOGTAG)
                NGSettings.useRearCamTelescopy = value
            })
            
        case let .shouldDownloadVideo(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, sectionId: section, style: .blocks) { value in
                NGSettings.shouldDownloadVideo = value
            }
        case let .OtherHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
            
        case let .hidePhoneInSettings(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[hidePhoneInSettings] invoked with \(value)", LOGTAG)
                NGSettings.hidePhoneSettings = value
            })
            
        case let .hidePhoneInSettingsNotice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
            
        case let .easyToggle(index, toggleType, text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                ngLog("[easyToggle] \(index) \(toggleType) invoked with \(value)", LOGTAG)
                switch (toggleType) {
                case .sendWithEnter:
                    NGSettings.sendWithEnter = value
                case .showProfileId:
                    NGSettings.showProfileId = value
                case .showRegDate:
                    NGSettings.showRegDate = value
                case .hideReactions:
                    VarSystemNGSettings.hideReactions = value
                case .hideStories:
                    NGSettings.hideStories = value
                case .hidePartnerIntegrations:
                    if #available(iOS 13.0, *) {
                        Partners.hideIntegrations = value
                    }
                }
            })
        case let .unblockHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .unblock(text, url):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                UIApplication.shared.openURL(url)
            }
        case let .Account(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .doubleBottom(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(doubleBottomListController(context: arguments.context, presentationData: arguments.context.sharedContext.currentPresentationData.with { $0 }, accountsContexts: arguments.accountsContexts))
            }
        case let .quickReplies(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(quickRepliesController(context: arguments.context))
            }
        case let .secretMenu(text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .neutral, alignment: .natural, sectionId: section, style: .blocks) {
                arguments.pushController(secretMenuController(context: arguments.context))
            }
        case let .shareChannelsInfoToggle(text, value):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: value, enabled: true, sectionId: section, style: .blocks, updated: { value in
                setShareChannelsInfo(enabled: value)
            })
        case let .shareChannelsInfoNote(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        case .pinnedBotsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: NGCoreUI.strings.ngSettingsPinnedChats().localizedUppercase,
                sectionId: section
            )
        case .aiPin:
            if #available(iOS 13.0, *) {
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    title: AiChatUITgHelper.showInChatsListToggle,
                    value: AiChatUITgHelper.getShowAiInChatsList(),
                    enabled: true,
                    sectionId: section,
                    style: .blocks,
                    updated: { value in
                        AiChatUITgHelper.set(showAiInChatsList: value)
                    }
                )
            } else {
                fatalError()
            }
        case .pstPin:
            if #available(iOS 13.0.0, *) {
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    title: CardUITgHelper.showInChatsListToggle,
                    value: CardUITgHelper.getShowCardInChatsList(),
                    enabled: true,
                    sectionId: section,
                    style: .blocks,
                    updated: { value in
                        CardUITgHelper.set(showCardInChatsList: value)
                    }
                )
            } else {
                fatalError()
            }
        case .imagesHubPin:
            if #available(iOS 15.0, *) {
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    title: ImagesHubUITgHelper.showInChatsListToggle,
                    value: ImagesHubUITgHelper.getShowImagesHubInChatsList(),
                    enabled: true,
                    sectionId: section,
                    style: .blocks,
                    updated: { value in
                        ImagesHubUITgHelper.set(showImagesHubInChatsList: value)
                    }
                )
            } else {
                fatalError()
            }
        }
    }
}

// MARK: Entries list

private func nicegramSettingsControllerEntries(presentationData: PresentationData, experimentalSettings: ExperimentalUISettings, showCalls: Bool, context: AccountContext) -> [NicegramSettingsControllerEntry] {
    var entries: [NicegramSettingsControllerEntry] = []

    let locale = presentationData.strings.baseLanguageCode
    
    if canOpenSecretMenu(context: context) {
        entries.append(.secretMenu("Secret Menu"))
    }
    
    if !hideUnblock {
        entries.append(.unblockHeader(l("NicegramSettings.Unblock.Header", locale).uppercased()))
        entries.append(.unblock(l("NicegramSettings.Unblock.Button", locale), nicegramUnblockUrl))
    }

    entries.append(.TabsHeader(l("NicegramSettings.Tabs",
                                 locale)))
    entries.append(.showContactsTab(
        l("NicegramSettings.Tabs.showContactsTab", locale),
        NGSettings.showContactsTab
    ))
    entries.append(.showCallsTab(
        presentationData.strings.CallSettings_TabIcon,
        showCalls
    ))
    if #available(iOS 15.0, *) {
        entries.append(.showNicegramTab)
    }
    entries.append(.showTabNames(
        l("NicegramSettings.Tabs.showTabNames", locale),
        NGSettings.showTabNames
    ))

    entries.append(.FoldersHeader(l("NicegramSettings.Folders",
                                    locale)))
    entries.append(.foldersAtBottom(
        l("NicegramSettings.Folders.foldersAtBottom", locale),
        experimentalSettings.foldersTabAtBottom
    ))
    entries.append(.foldersAtBottomNotice(
        l("NicegramSettings.Folders.foldersAtBottomNotice", locale)
    ))
    
    var pinnedBots: [NicegramSettingsControllerEntry] = []
    
    if #available(iOS 13.0, *),
       AiChatUITgHelper.canPinAiBot() {
        pinnedBots.append(.aiPin)
    }
    
    if #available(iOS 13.0, *),
       CardUITgHelper.canPinCardBot() {
        pinnedBots.append(.pstPin)
    }
    
    if #available(iOS 15.0, *),
       ImagesHubUITgHelper.canPinImageBot() {
        pinnedBots.append(.imagesHubPin)
    }
    
    if !pinnedBots.isEmpty {
        entries.append(.pinnedBotsHeader)
        pinnedBots.forEach { entries.append($0) }
    }

    entries.append(.RoundVideosHeader(l("NicegramSettings.RoundVideos",
                                        locale)))
    entries.append(.startWithRearCam(
        l("NicegramSettings.RoundVideos.startWithRearCam", locale),
        NGSettings.useRearCamTelescopy
    ))
    entries.append(.shouldDownloadVideo(
        l("NicegramSettings.RoundVideos.DownloadVideos", locale), 
        NGSettings.shouldDownloadVideo
    ))

    entries.append(.OtherHeader(
        presentationData.strings.ChatSettings_Other.uppercased()))
    entries.append(.hidePhoneInSettings(
        l("NicegramSettings.Other.hidePhoneInSettings", locale),
        NGSettings.hidePhoneSettings
    ))
    entries.append(.hidePhoneInSettingsNotice(
        l("NicegramSettings.Other.hidePhoneInSettingsNotice", locale)
    ))
    
    if #available(iOS 10.0, *) {
        entries.append(.quickReplies(l("NiceFeatures.QuickReplies", locale)))
    }

    
    entries.append(.Account(l("NiceFeatures.Account.Header", locale)))
    if !context.account.isHidden || !VarSystemNGSettings.inDoubleBottom {
        entries.append(.doubleBottom(l("DoubleBottom.Title", locale)))
    }
    
    var toggleIndex: Int32 = 1
    // MARK: Other Toggles (Easy)
    entries.append(.easyToggle(toggleIndex, .sendWithEnter, l("SendWithKb", locale), NGSettings.sendWithEnter))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .showProfileId, l("NicegramSettings.Other.showProfileId", locale), NGSettings.showProfileId))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .showRegDate, l("NicegramSettings.Other.showRegDate", locale), NGSettings.showRegDate))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .hideReactions, l("NicegramSettings.Other.hideReactions", locale), VarSystemNGSettings.hideReactions))
    toggleIndex += 1
    
    entries.append(.easyToggle(toggleIndex, .hideStories, l("NicegramSettings.HideStories", locale), NGSettings.hideStories))
    toggleIndex += 1
    
    if #available(iOS 13.0, *) {
        entries.append(.easyToggle(toggleIndex, .hidePartnerIntegrations, Partners.hideIntegrationsTitle, Partners.hideIntegrations))
        toggleIndex += 1
    }
    
    entries.append(.shareChannelsInfoToggle(l("NicegramSettings.ShareChannelsInfoToggle", locale), isShareChannelsInfoEnabled()))
    entries.append(.shareChannelsInfoNote(l("NicegramSettings.ShareChannelsInfoToggle.Note", locale)))
    
    return entries
}

// MARK: Controller

public func nicegramSettingsController(context: AccountContext, accountsContexts: [(AccountContext, EnginePeer)], modal: Bool = false) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    var dismissImpl: (() -> Void)?
    var getRootControllerImpl: (() -> UIViewController?)?
    var updateTabsImpl: (() -> Void)?

    let presentationData = context.sharedContext.currentPresentationData.with { $0 }

    let arguments = NicegramSettingsControllerArguments(context: context, accountsContexts: accountsContexts, presentController: { controller, arguments in
        presentControllerImpl?(controller, arguments)
    }, pushController: { controller in
        pushControllerImpl?(controller)
    }, getRootController: {
        getRootControllerImpl?()
    }, updateTabs: {
        updateTabsImpl?()
    })

    let showCallsTab = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.callListSettings])
        |> map { sharedData -> Bool in
            var value = false
            if let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.callListSettings]?.get(CallListSettings.self) {
                value = settings.showTab
            }
            return value
        }

    let sharedDataSignal = context.sharedContext.accountManager.sharedData(keys: [
        ApplicationSpecificSharedDataKeys.experimentalUISettings,
    ])

    let signal = combineLatest(context.sharedContext.presentationData, sharedDataSignal, showCallsTab) |> map { presentationData, sharedData, showCalls -> (ItemListControllerState, (ItemListNodeState, Any)) in

        let experimentalSettings: ExperimentalUISettings = sharedData.entries[ApplicationSpecificSharedDataKeys.experimentalUISettings]?.get(ExperimentalUISettings.self) ?? ExperimentalUISettings.defaultSettings

        var leftNavigationButton: ItemListNavigationButton?
        if modal {
            leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
                dismissImpl?()
            })
        }

        let entries = nicegramSettingsControllerEntries(presentationData: presentationData, experimentalSettings: experimentalSettings, showCalls: showCalls, context: context)
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(l("AppName", presentationData.strings.baseLanguageCode)), leftNavigationButton: leftNavigationButton, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    getRootControllerImpl = { [weak controller] in
        controller?.view.window?.rootViewController
    }
    updateTabsImpl = {
        _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
            var settings = settings
            settings.showTab = !settings.showTab
            return settings
        }.start(completed: {
            _ = updateCallListSettingsInteractively(accountManager: context.sharedContext.accountManager) { settings in
                var settings = settings
                settings.showTab = !settings.showTab
                return settings
            }.start(completed: {
                ngLog("Tabs refreshed", LOGTAG)
            })
        })
    }
    return controller
}
