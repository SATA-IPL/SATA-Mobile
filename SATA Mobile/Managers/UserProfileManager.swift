import Foundation

@MainActor
class UserProfileManager: ObservableObject {
    @Published private(set) var name: String
    
    init() {
        self.name = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    func setName(_ name: String) {
        self.name = name
        UserDefaults.standard.set(name, forKey: "userName")
    }
}
