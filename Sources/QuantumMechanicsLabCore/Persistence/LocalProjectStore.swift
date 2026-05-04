import Foundation

public struct LocalProjectState: Codable, Sendable, Equatable {
    public var selectedExperimentID: String
    public var presets: [ExperimentPreset]

    public init(selectedExperimentID: String, presets: [ExperimentPreset] = []) {
        self.selectedExperimentID = selectedExperimentID
        self.presets = presets
    }
}

public protocol LocalProjectStore: Sendable {
    func load() throws -> LocalProjectState?
    func save(_ state: LocalProjectState) throws
}
