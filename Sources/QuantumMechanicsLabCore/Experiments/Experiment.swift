import Foundation

public enum ExperimentCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case oneD
    case twoD
    case orbitals

    public var id: String {
        rawValue
    }

    public var title: String {
        switch self {
        case .oneD:
            "1D Experiments"
        case .twoD:
            "2D Experiments"
        case .orbitals:
            "Hydrogen Orbitals"
        }
    }
}

public struct StoryStep: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var body: String

    public init(id: String, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

public struct ParameterIssue: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var message: String

    public init(id: String, message: String) {
        self.id = id
        self.message = message
    }
}

public struct ExperimentParameter: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var label: String
    public var value: Double
    public var range: ClosedRange<Double>
    public var unit: String?

    public init(id: String, label: String, value: Double, range: ClosedRange<Double>, unit: String? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.range = range
        self.unit = unit
    }
}

public protocol Experiment: Identifiable, Sendable {
    var id: String { get }
    var title: String { get }
    var category: ExperimentCategory { get }
    var summary: String { get }
    var explanation: String { get }
    var builtInPresets: [ExperimentPreset] { get }
    var defaultParameters: [ExperimentParameter] { get }
    var story: [StoryStep] { get }

    func makeInitialSnapshot() -> SimulationSnapshot
    func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot
    func validate(parameters: [ExperimentParameter]) -> [ParameterIssue]
}

public extension Experiment {
    var explanation: String {
        "This experiment demonstrates fundamental quantum mechanical principles. Adjust the parameters to observe how the wavefunction evolves over time."
    }
    
    var builtInPresets: [ExperimentPreset] {
        []
    }
    
    func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        makeInitialSnapshot()
    }
}

public struct AnyExperiment: Identifiable, Sendable {
    public var id: String
    public var title: String
    public var category: ExperimentCategory
    public var summary: String
    public var explanation: String
    public var builtInPresets: [ExperimentPreset]
    public var defaultParameters: [ExperimentParameter]
    public var story: [StoryStep]
    private var initialSnapshotFactory: @Sendable () -> SimulationSnapshot
    private var parameterizedSnapshotFactory: @Sendable ([ExperimentParameter]) -> SimulationSnapshot
    private var validation: @Sendable ([ExperimentParameter]) -> [ParameterIssue]

    public init<E: Experiment>(_ experiment: E) {
        self.id = experiment.id
        self.title = experiment.title
        self.category = experiment.category
        self.summary = experiment.summary
        self.explanation = experiment.explanation
        self.builtInPresets = experiment.builtInPresets
        self.defaultParameters = experiment.defaultParameters
        self.story = experiment.story
        self.initialSnapshotFactory = { experiment.makeInitialSnapshot() }
        self.parameterizedSnapshotFactory = { experiment.makeInitialSnapshot(parameters: $0) }
        self.validation = { experiment.validate(parameters: $0) }
    }

    public func makeInitialSnapshot() -> SimulationSnapshot {
        initialSnapshotFactory()
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        parameterizedSnapshotFactory(parameters)
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        validation(parameters)
    }
}

public extension Collection where Element == ExperimentParameter {
    func value(for id: String, default defaultValue: Double) -> Double {
        first { $0.id == id }?.value ?? defaultValue
    }
}
