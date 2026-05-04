import Foundation

public struct FiniteBarrierExperiment: Experiment {
    public let id = "finite-barrier"
    public let title = "Finite Barrier"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket partially reflects and partially tunnels through a finite barrier."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 3, range: 0...12),
            ExperimentParameter(id: "barrierWidth", label: "Barrier Width", value: 1, range: 0.1...4),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 5, range: 0...12)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "split", title: "Reflection and transmission", body: "The packet splits into reflected and transmitted components.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let barrierHeight = parameters.value(for: "barrierHeight", default: 3)
        let barrierWidth = parameters.value(for: "barrierWidth", default: 1)
        let momentum = parameters.value(for: "momentum", default: 5)
        let potential = PotentialBuffer(values: grid.xValues.map { abs($0) < barrierWidth / 2 ? barrierHeight : 0 })
        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -5,
            width: 0.7,
            momentum: momentum,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
