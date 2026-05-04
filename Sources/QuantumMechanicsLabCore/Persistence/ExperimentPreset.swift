import Foundation

public struct ExperimentPreset: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var experimentID: String
    public var name: String
    public var parameters: [ExperimentParameter]
    public var customPotentialValues: [Double]?

    public init(
        id: UUID = UUID(),
        experimentID: String,
        name: String,
        parameters: [ExperimentParameter],
        customPotentialValues: [Double]? = nil
    ) {
        self.id = id
        self.experimentID = experimentID
        self.name = name
        self.parameters = parameters
        self.customPotentialValues = customPotentialValues
    }
}
