import Foundation

public struct FreeWavepacket2DExperiment: Experiment {
    public let id = "free-wavepacket-2d"
    public let title = "2D Free Wavepacket"
    public let category = ExperimentCategory.twoD
    public let summary = "A free Gaussian wavepacket drifting and spreading in two dimensions."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "momentumX", label: "Momentum X", value: 3, range: -10...10),
            ExperimentParameter(id: "momentumY", label: "Momentum Y", value: 2, range: -10...10),
            ExperimentParameter(id: "width", label: "Packet Width", value: 0.8, range: 0.3...3)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "dispersion", title: "Wavepacket Spreading", body: "In a vacuum, the wavepacket naturally spreads out over time due to dispersion, while its center follows a classical trajectory.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let px = parameters.value(for: "momentumX", default: 3)
        let py = parameters.value(for: "momentumY", default: 2)
        let width = parameters.value(for: "width", default: 0.8)

        let potential = PotentialBuffer(values: Array(repeating: 0.0, count: grid.pointCount))

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -3,
            centerY: -3,
            width: width,
            momentumX: px,
            momentumY: py,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] { [] }
}
