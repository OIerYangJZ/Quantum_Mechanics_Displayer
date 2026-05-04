import Foundation

public struct HarmonicOscillator2DExperiment: Experiment {
    public let id = "harmonic-oscillator-2d"
    public let title = "2D Harmonic Oscillator"
    public let category = ExperimentCategory.twoD
    public let summary = "A 2D wavepacket oscillating within a parabolic potential well."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "omega", label: "Stiffness", value: 2, range: 0.5...5),
            ExperimentParameter(id: "momentumX", label: "Momentum X", value: 2, range: -8...8),
            ExperimentParameter(id: "momentumY", label: "Momentum Y", value: 3, range: -8...8)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "oscillation", title: "2D Oscillation", body: "The wavepacket undergoes periodic motion in both X and Y directions, creating Lissajous-like trajectories.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let omega = parameters.value(for: "omega", default: 2)
        let momentumX = parameters.value(for: "momentumX", default: 2)
        let momentumY = parameters.value(for: "momentumY", default: 3)

        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                // V(x, y) = 1/2 m w^2 (x^2 + y^2) (mass is assumed 1 in TwoDInitialStates.snapshot defaults)
                return 0.5 * omega * omega * (x * x + y * y)
            }
        }

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -3,
            centerY: -2,
            width: 0.8,
            momentumX: momentumX,
            momentumY: momentumY,
            potential: PotentialBuffer(values: values)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
