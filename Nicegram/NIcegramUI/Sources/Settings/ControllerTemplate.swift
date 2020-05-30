////
////  NicegramSettingsViewController.swift
////  NicegramUI
////
////  Created by Sergey Akentev on 5/9/20.
////
//
//import Foundation
//import QuickTableViewController
//import Display
//import UIKit
//import AsyncDisplayKit
//import TelegramPresentationData
//import SwiftSignalKit
//import AccountContext
//
//
//let leftTCTableinset: CGFloat = 20
//
//
//
//final class NicegramSettingsController: QuickTableViewController
//{
//
//    private let context: AccountContext
//
//    var rootNavigationController: NavigationController?
//    var presentationData: PresentationData
//    private var presentationDataDisposable: Disposable?
//    var dismiss: (() -> Void)?
//
//    public var pushControllerImpl: ((ViewController) -> Void)?
//
//
//    public init(context: AccountContext) {
//        self.context = context
//        self.presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
//
//        super.init(nibName: nil, bundle: nil)
//
//        self.presentationDataDisposable = (context.sharedContext.presentationData
//            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
//                if let strongSelf = self {
//                    let previousTheme = strongSelf.presentationData.theme
//                    let previousStrings = strongSelf.presentationData.strings
//
//                    strongSelf.presentationData = presentationData
//
//                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
//                        strongSelf.updateThemeAndStrings()
//                    }
//                }
//            })
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override public func viewDidLoad()
//    {
//        super.viewDidLoad()
//
//
//    }
//
//    override public func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        print("APPEAR TABLEVIEW")
//        self.getNavigationController()
//    }
//
//
//    private func updateThemeAndStrings() {
//        //self.title = self.presentationData.strings.Settings_AppLanguage
//        //self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .plain, target: self, action: #selector(self.cancelPressed))
//
//        if self.isViewLoaded {
//            self.tableView.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
//            self.tableView.separatorColor = self.presentationData.theme.chatList.itemSeparatorColor
//
//            self.tableView.reloadData()
//        }
//    }
//
//    @objc func cancelPressed() {
//        self.dismiss?()
//    }
//
//    func getNavigationController() -> NavigationController? {
//        if let strongRootNavigationController = self.rootNavigationController {
//            return strongRootNavigationController
//        }
//
//        if let strongParentRootNVC = (self.parent?.parent as? NicegramSettingsViewController)?.navigationController as? NavigationController {
//            self.rootNavigationController = strongParentRootNVC
//            return strongParentRootNVC
//        }
//
//        return nil
//    }
//
//    public func scrollToTop() {
//        self.tableView.scrollToTop(true)
//    }
//
//}
//
//extension UITableView{
//
//    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
//        return indexPath.section < numberOfSections && indexPath.row < numberOfRows(inSection: indexPath.section)
//    }
//
//    func scrollToTop(_ animated: Bool = false) {
//        let indexPath = IndexPath(row: 0, section: 0)
//        if hasRowAtIndexPath(indexPath: indexPath) {
//            scrollToRow(at: indexPath, at: .top, animated: animated)
//        }
//    }
//
//}
//
//
//
//final class NicegramSettingsControllerNode: ASDisplayNode {
//    var dismiss: (() -> Void)?
//
//    override init() {
//        super.init()
//
//        self.setViewBlock({
//            return UITracingLayerView()
//        })
//
//        self.backgroundColor = UIColor.white
//    }
//
//    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
//    }
//
//}
//
//
//public class NicegramSettingsViewController: ViewController {
//    private var controllerNode: NicegramSettingsControllerNode {
//        return self.displayNode as! NicegramSettingsControllerNode
//    }
//
//    private let innerNavigationController: UINavigationController
//    private let innerController: NicegramSettingsController
//    private var presentationData: PresentationData
//    private var presentationDataDisposable: Disposable?
//
//
//
//    public var pushControllerImpl: ((ViewController) -> Void)?
//    //public var presentControllerImpl: ((ViewController, Any?) -> Void)?
//
//    public init(context: AccountContext) {
//        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
//
//        self.innerController = NicegramSettingsController(context: context)
//        self.innerNavigationController = UINavigationController(rootViewController: self.innerController)
//        //        self.innerController.pushControllerImpl = { value in
//        //            (self.innerNavigationController as? NavigationController)?.pushViewController(value)
//        //        }
//
//        super.init(navigationBarPresentationData: nil)
//
//        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
//        self.innerNavigationController.navigationBar.barTintColor = self.presentationData.theme.rootController.navigationBar.backgroundColor
//        self.innerNavigationController.navigationBar.tintColor = self.presentationData.theme.rootController.navigationBar.accentTextColor
//        self.innerNavigationController.navigationBar.shadowImage = generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
//            context.clear(CGRect(origin: CGPoint(), size: size))
//            context.setFillColor(self.presentationData.theme.rootController.navigationBar.separatorColor.cgColor)
//            context.fill(CGRect(origin: CGPoint(), size: CGSize(width: 1.0, height: UIScreenPixel)))
//        })
//
//        self.innerNavigationController.navigationBar.isTranslucent = false
//        self.innerNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: Font.semibold(17.0), NSAttributedString.Key.foregroundColor: self.presentationData.theme.rootController.navigationBar.primaryTextColor]
//        self.navigationItem.title = title
//
//        self.innerController.dismiss = { [weak self] in
//            self?.cancelPressed()
//        }
//
//        self.presentationDataDisposable = (context.sharedContext.presentationData
//            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
//                if let strongSelf = self {
//                    let previousTheme = strongSelf.presentationData.theme
//                    let previousStrings = strongSelf.presentationData.strings
//
//                    strongSelf.presentationData = presentationData
//
//                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
//                        strongSelf.updateThemeAndStrings()
//                    }
//                }
//            })
//
//        self.scrollToTopWithTabBar = { [weak self] in
//            guard let strongSelf = self else {
//                return
//            }
//            strongSelf.innerController.scrollToTop()
//        }
//
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    deinit {
//        self.presentationDataDisposable?.dispose()
//    }
//
//    private func updateThemeAndStrings() {
//        print("UPDATING COLORS")
//        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
//    }
//
//    override public func loadDisplayNode() {
//        self.displayNode = NicegramSettingsControllerNode()
//        self.displayNodeDidLoad()
//
//        self.innerNavigationController.willMove(toParent: self)
//        self.addChild(self.innerNavigationController)
//        self.displayNode.view.addSubview(self.innerNavigationController.view)
//        self.innerNavigationController.didMove(toParent: self)
//
//        self.controllerNode.dismiss = { [weak self] in
//            self?.presentingViewController?.dismiss(animated: true, completion: nil)
//        }
//    }
//
//    override public func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        self.innerNavigationController.viewWillAppear(false)
//        self.innerNavigationController.viewDidAppear(false)
//        //self.controllerNode.animateIn()
//    }
//
//    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
//        super.containerLayoutUpdated(layout, transition: transition)
//
//        // If we need to go higher than Tabbar
//        var tabBarHeight: CGFloat
//        var options: ContainerViewLayoutInsetOptions = []
//        if layout.metrics.widthClass == .regular {
//            options.insert(.input)
//        }
//        let bottomInset: CGFloat = layout.insets(options: options).bottom
//        if !layout.safeInsets.left.isZero {
//            tabBarHeight = 34.0 + bottomInset
//        } else {
//            tabBarHeight = 49.0 + bottomInset
//        }
//
//        let tabBarFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - tabBarHeight), size: CGSize(width: layout.size.width, height: tabBarHeight))
//
//        var finalLayout = layout.size
//        finalLayout.height = finalLayout.height - (tabBarFrame.height / 2.0)
//        self.innerNavigationController.view.frame = CGRect(origin: CGPoint(), size: finalLayout)
//
//        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
//    }
//
//    private func cancelPressed() {
//        //self.controllerNode.animateOut()
//    }
//
//}
