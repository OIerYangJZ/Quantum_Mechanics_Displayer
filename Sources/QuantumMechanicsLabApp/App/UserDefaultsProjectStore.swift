import Foundation
import QuantumMechanicsLabCore

struct UserDefaultsProjectStore: LocalProjectStore, @unchecked Sendable {
    private let key = "quantum_mechanics_project_state"

    func load() throws -> LocalProjectState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(LocalProjectState.self, from: data)
    }

    func save(_ state: LocalProjectState) throws {
        let data = try JSONEncoder().encode(state)
        UserDefaults.standard.set(data, forKey: key)
    }
}
