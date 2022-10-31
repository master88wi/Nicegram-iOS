import UIKit

public extension UIViewController {
    func presentShareSheet(items: [Any], sourceView: UIView?) {
        let activityVc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityVc.popoverPresentationController?.sourceView = sourceView
        
        present(activityVc, animated: true)
    }
    
    func routeToAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) ,
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
}
