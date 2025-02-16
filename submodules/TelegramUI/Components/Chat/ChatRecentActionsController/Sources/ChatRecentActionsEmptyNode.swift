// MARK: Nicegram Unblock
import SolidRoundedButtonNode
//
import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import TelegramPresentationData
import WallpaperBackgroundNode
import ChatPresentationInterfaceState

private let titleFont = Font.medium(16.0)
private let textFont = Font.regular(15.0)

public final class ChatRecentActionsEmptyNode: ASDisplayNode {
    private var theme: PresentationTheme
    private var chatWallpaper: TelegramWallpaper
        
    private let backgroundNode: NavigationBackgroundNode
    private let titleNode: TextNode
    private let textNode: TextNode
    
    private var wallpaperBackgroundNode: WallpaperBackgroundNode?
    private var backgroundContent: WallpaperBubbleBackgroundNode?
    
    private var absolutePosition: (CGRect, CGSize)?
    
    private var layoutParams: (CGSize, ChatPresentationData)?
    
    // MARK: Nicegram Unblock
    private let buttonNode: SolidRoundedButtonNode
    //
    
    private var title: String = ""
    private var text: String = ""
    
    public init(theme: PresentationTheme, chatWallpaper: TelegramWallpaper, chatBubbleCorners: PresentationChatBubbleCorners) {
        self.theme = theme
        self.chatWallpaper = chatWallpaper
        
        self.backgroundNode = NavigationBackgroundNode(color: .clear)
        
        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        
        self.textNode = TextNode()
        self.textNode.isUserInteractionEnabled = false
        
        // MARK: Nicegram Unblock
        self.buttonNode = SolidRoundedButtonNode(theme: SolidRoundedButtonTheme(theme: self.theme), height: 50.0, cornerRadius: 11.0, gloss: true)
        //
        
        super.init()
        
        self.allowsGroupOpacity = true
                
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.textNode)
        // MARK: Nicegram Unblock
        self.addSubnode(self.buttonNode)
        //
    }
    
    public func update(rect: CGRect, within containerSize: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        self.absolutePosition = (rect, containerSize)
        if let backgroundContent = self.backgroundContent {
            var backgroundFrame = backgroundContent.frame
            backgroundFrame.origin.x += rect.minX
            backgroundFrame.origin.y += rect.minY
            backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: transition)
        }
    }
    
    public func updateLayout(presentationData: ChatPresentationData, backgroundNode: WallpaperBackgroundNode, size: CGSize, transition: ContainedViewLayoutTransition) {
        self.wallpaperBackgroundNode = backgroundNode
        self.layoutParams = (size, presentationData)
        
        self.theme = presentationData.theme.theme
        self.chatWallpaper = presentationData.theme.wallpaper
    
        self.backgroundNode.updateColor(color: selectDateFillStaticColor(theme: presentationData.theme.theme, wallpaper: presentationData.theme.wallpaper), enableBlur: dateFillNeedsBlur(theme: presentationData.theme.theme, wallpaper: presentationData.theme.wallpaper), transition: .immediate)
        
        let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        
        let maxTextWidth = size.width - insets.left - insets.right - 18.0 * 2.0
        
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeTextLayout = TextNode.asyncLayout(self.textNode)
        
        let serviceColor = serviceMessageColorComponents(theme: self.theme, wallpaper: self.chatWallpaper)
        
        let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: self.title, font: titleFont, textColor: serviceColor.primaryText), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
        let spacing: CGFloat = titleLayout.size.height.isZero ? 0.0 : 5.0
        let (textLayout, textApply) = makeTextLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: self.text, font: textFont, textColor: serviceColor.primaryText), backgroundColor: nil, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets()))
        
        let contentSize = CGSize(width: max(titleLayout.size.width, textLayout.size.width) + insets.left + insets.right, height: insets.top + insets.bottom + titleLayout.size.height + spacing + textLayout.size.height)
        let backgroundFrame = CGRect(origin: CGPoint(x: floor((size.width - contentSize.width) / 2.0), y: floor((size.height - contentSize.height) / 2.0)), size: contentSize)
        transition.updateFrame(node: self.backgroundNode, frame: backgroundFrame)
        self.backgroundNode.update(size: self.backgroundNode.bounds.size, cornerRadius: min(14.0, self.backgroundNode.bounds.height / 2.0), transition: transition)
        
        transition.updateFrame(node: self.titleNode, frame: CGRect(origin: CGPoint(x: backgroundFrame.minX + floor((contentSize.width - titleLayout.size.width) / 2.0), y: backgroundFrame.minY + insets.top), size: titleLayout.size))
        transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: backgroundFrame.minX + floor((contentSize.width - textLayout.size.width) / 2.0), y: backgroundFrame.minY + insets.top + titleLayout.size.height + spacing), size: textLayout.size))
        
        // MARK: Nicegram Unblock
        let buttonSize = CGSize(
            width: size.width - insets.left - insets.right,
            height: 50
        )
        let buttonFrame = CGRect(
            origin: CGPoint(
                x: (size.width - buttonSize.width) / 2,
                y: backgroundFrame.maxY + 50
            ),
            size: buttonSize
        )
        transition.updateFrame(node: self.buttonNode, frame: buttonFrame)
        let _ = self.buttonNode.updateLayout(width: buttonFrame.width, transition: transition)
        //
        
        let _ = titleApply()
        let _ = textApply()
        
        if backgroundNode.hasExtraBubbleBackground() == true {
            if self.backgroundContent == nil, let backgroundContent = backgroundNode.makeBubbleBackground(for: .free) {
                backgroundContent.clipsToBounds = true

                self.backgroundContent = backgroundContent
                self.insertSubnode(backgroundContent, at: 0)
            }
        } else {
            self.backgroundContent?.removeFromSupernode()
            self.backgroundContent = nil
        }
        
        if let backgroundContent = self.backgroundContent {
            self.backgroundNode.isHidden = true
            backgroundContent.cornerRadius = 14.0
            backgroundContent.frame = backgroundFrame
            if let (rect, containerSize) = self.absolutePosition {
                var backgroundFrame = backgroundContent.frame
                backgroundFrame.origin.x += rect.minX
                backgroundFrame.origin.y += rect.minY
                backgroundContent.update(rect: backgroundFrame, within: containerSize, transition: .immediate)
            }
        } else {
            self.backgroundNode.isHidden = false
        }
    }
    
    // MARK: Nicegram Unblock
    public func setupButton(title: String?, handler: (() -> Void)?) {
        self.buttonNode.title = title
        self.buttonNode.isHidden = (title == nil)
        self.buttonNode.pressed = handler
    }
    //
    
    public func setup(title: String, text: String) {
        if self.title != title || self.text != text {
            self.title = title
            self.text = text
            if let (size, presentationData) = self.layoutParams, let wallpaperBackgroundNode = self.wallpaperBackgroundNode {
                self.updateLayout(presentationData: presentationData, backgroundNode: wallpaperBackgroundNode, size: size, transition: .immediate)
            }
        }
    }
}
