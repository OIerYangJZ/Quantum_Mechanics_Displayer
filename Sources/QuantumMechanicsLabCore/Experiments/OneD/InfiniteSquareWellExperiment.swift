import Foundation

public struct InfiniteSquareWellExperiment: Experiment {
    public let id = "infinite-square-well"
    public let title = "Infinite Square Well"
    public let category = ExperimentCategory.oneD
    public let summary = "Gaussian wavepacket reflected by steep wall potentials inside a larger FFT domain."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5),
            ExperimentParameter(id: "width", label: "Packet Width", value: 0.8, range: 0.2...3),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 4, range: -10...10)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(
                id: "norm",
                title: "Probability stays normalized",
                body: "The total probability should stay near one while the packet moves."
            ),
            StoryStep(
                id: "reflection",
                title: "Reflection changes momentum",
                body: "The packet reflects from the high wall while probability remains inside the box."
            )
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D(pointCount: 2_048, length: 20)
        let xValues = grid.xValues
        let wallStart = 8.5
        let mass = parameters.value(for: "mass", default: 1)
        let width = parameters.value(for: "width", default: 0.8)
        let momentum = parameters.value(for: "momentum", default: 4)
        let potential = PotentialBuffer(
            values: xValues.map { abs($0) > wallStart ? 80 : 0 }
        )
        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -4,
            width: width,
            momentum: momentum,
            potential: potential,
            mass: mass
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
