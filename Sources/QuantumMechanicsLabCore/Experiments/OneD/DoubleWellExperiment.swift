import Foundation

public struct DoubleWellExperiment: Experiment {
    public let id = "double-well"
    public let title = "Double Well Potential"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket tunneling back and forth between two adjacent potential wells."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 15, range: 0...50),
            ExperimentParameter(id: "barrierWidth", label: "Barrier Width", value: 0.5, range: 0.1...2),
            ExperimentParameter(id: "wellWidth", label: "Well Width", value: 2, range: 1...5)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "tunneling", title: "Quantum Tunneling", body: "If placed entirely in one well, the packet will slowly leak through the barrier and oscillate between the two wells.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let barrierHeight = parameters.value(for: "barrierHeight", default: 15)
        let barrierWidth = parameters.value(for: "barrierWidth", default: 0.5)
        let wellWidth = parameters.value(for: "wellWidth", default: 2)

        let potential = PotentialBuffer(values: grid.xValues.map { x in
            let absX = abs(x)
            if absX < barrierWidth / 2 {
                return barrierHeight
            } else if absX < barrierWidth / 2 + wellWidth {
                return 0
            } else {
                return 80 // Outer walls
            }
        })

        // Start in the left well
        let center = -(barrierWidth / 2 + wellWidth / 2)

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: center,
            width: wellWidth * 0.3,
            momentum: 0, // Stationary initial state to observe tunneling
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
