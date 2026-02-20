import ServiceManagement

final class LoginItemManager {

    private let key = "LaunchAtLogin"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            if newValue {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    /// Sync persisted preference with the system on launch.
    init() {
        let persisted = UserDefaults.standard.bool(forKey: key)
        let registered = SMAppService.mainApp.status == .enabled
        if persisted && !registered {
            try? SMAppService.mainApp.register()
        } else if !persisted && registered {
            try? SMAppService.mainApp.unregister()
        }
    }
}
