import Foundation

public struct FreeWavepacketExperiment: Experiment {
    public let id = "free-wavepacket"
    public let title = "Free Gaussian Wavepacket"
    public let category = ExperimentCategory.oneD
    public let summary = "A free packet that translates and spreads over time."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "center", label: "Initial Center", value: -5, range: -8...8),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 3, range: -10...10),
            ExperimentParameter(id: "width", label: "Packet Width", value: 0.8, range: 0.2...3)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "spreading", title: "Spreading", body: "A free packet spreads because it contains multiple momentum components.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        OneDInitialStates.snapshot(
            experimentID: id,
            center: parameters.value(for: "center", default: -5),
            width: parameters.value(for: "width", default: 0.8),
            momentum: parameters.value(for: "momentum", default: 3)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
