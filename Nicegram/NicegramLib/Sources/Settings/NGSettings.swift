import Foundation

@propertyWrapper
public struct NGStorage<T: Codable> {
    private let key: String
    private let defaultValue: T

    public init(key: String, defaultValue: T) {
        self.key = "ng:" + key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            // Read value from UserDefaults
            guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
                // Return defaultValue when no data in UserDefaults
                return defaultValue
            }

            // Convert data to the desire data type
            let value = try? JSONDecoder().decode(T.self, from: data)
            return value ?? defaultValue
        }
        set {
            // Convert newValue to data
            let data = try? JSONEncoder().encode(newValue)
            
            // Set value to UserDefaults
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

//@propertyWrapper
//struct EncryptedStringStorage {
//
//    private let key: String
//
//    init(key: String) {
//        self.key = key
//    }
//
//    var wrappedValue: String {
//        get {
//            // Get encrypted string from UserDefaults
//            return UserDefaults.standard.string(forKey: key) ?? ""
//        }
//        set {
//            // Encrypt newValue before set to UserDefaults
//            let encrypted = encrypt(value: newValue)
//            UserDefaults.standard.set(encrypted, forKey: key)
//        }
//    }
//
//    private func encrypt(value: String) -> String {
//        // Encryption logic here
//        return String(value.reversed())
//    }
//}

//struct AppData {
//    @Storage(key: "username_key", defaultValue: "")
//    static var username: String
//
//    @Storage(key: "enable_auto_login_key", defaultValue: false)
//    static var enableAutoLogin: Bool
//
//    // Declare a User object
//    @Storage(key: "user_key", defaultValue: User(firstName: "", lastName: "", lastLogin: nil))
//    static var user: User
//
////    @EncryptedStringStorage(key: "password_key")
////    static var password: String
//}


public struct NGSettings {
    // MARK: Premium
    @NGStorage(key: "premium", defaultValue: false)
    public static var premium: Bool
    
    @NGStorage(key: "oneTapTr", defaultValue: true)
    public static var oneTapTr: Bool
    
    @NGStorage(key: "ignoreTranslate", defaultValue: [])
    public static var ignoreTranslate: [String]
    
    // MARK: App Settings
    @NGStorage(key: "showContactsTab", defaultValue: true)
    public static var showContactsTab: Bool
    
    @NGStorage(key: "sendWithEnter", defaultValue: false)
    public static var sendWithEnter: Bool
    
    @NGStorage(key: "hidePhoneSettings", defaultValue: false)
    public static var hidePhoneSettings: Bool
    
    @NGStorage(key: "useRearCamTelescopy", defaultValue: false)
    public static var useRearCamTelescopy: Bool
    
    @NGStorage(key: "hideNotifyAccount", defaultValue: false)
    public static var hideNotifyAccount: Bool
    
    @NGStorage(key: "fixNotifications", defaultValue: false)
    public static var fixNotifications: Bool
    
    @NGStorage(key: "showTabNames", defaultValue: true)
    public static var showTabNames: Bool
    
    @NGStorage(key: "classicProfileUI", defaultValue: false)
    public static var classicProfileUI: Bool
    
    @NGStorage(key: "showGmodIcon", defaultValue: true)
    public static var showGmodIcon: Bool
    
    
}

public struct NGWebSettings {
    // MARK: Remote Settings
    @NGStorage(key: "syncPins", defaultValue: false)
    static var syncPins: Bool
    
    @NGStorage(key: "restricted", defaultValue: [])
    static var resticted: [Int64]
    
    @NGStorage(key: "RR", defaultValue: [])
    static var RR: [String]
    
    @NGStorage(key: "allowed", defaultValue: [])
    static var allowed: [Int64]
      
}


public func isPremium() -> Bool {
    //return true
    #if DEBUG
        return NGSettings.premium
    #endif
    
    if (NicegramProducts.Premium.isEmpty) {
        return false
    }
    
    let bb = (Bundle.main.infoDictionary?[kCFBundleVersionKey as String] ?? "") as! String
    if bb.last != "1" {
        return false
    }
    
    return NGSettings.premium
}

public func usetrButton() -> [(Bool, [String])] {
    if isPremium() {
        return [(NGSettings.oneTapTr, NGSettings.ignoreTranslate)]
    }
    return [(false, [])]
}
