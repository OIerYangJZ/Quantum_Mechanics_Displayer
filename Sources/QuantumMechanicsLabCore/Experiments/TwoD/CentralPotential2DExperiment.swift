import Foundation

public struct CentralPotential2DExperiment: Experiment {
    public let id = "central-potential-2d"
    public let title = "2D Attractive Well"
    public let category = ExperimentCategory.twoD
    public let summary = "A 2D wavepacket scattering off an attractive central Gaussian potential well."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "depth", label: "Well Depth", value: 15, range: 0...40),
            ExperimentParameter(id: "radius", label: "Well Radius", value: 2, range: 0.5...5),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 4, range: 0...12),
            ExperimentParameter(id: "impact", label: "Impact Parameter", value: 1, range: -5...5)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "scattering", title: "Scattering and Capture", body: "The attractive well pulls the wavepacket inward. Depending on the impact parameter, it causes angular deflection, and part of the probability may be temporarily captured in resonance states.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let depth = parameters.value(for: "depth", default: 15)
        let radius = parameters.value(for: "radius", default: 2)
        let momentum = parameters.value(for: "momentum", default: 4)
        let impact = parameters.value(for: "impact", default: 1)

        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                let r2 = x * x + y * y
                // Gaussian attractive well: V(r) = -depth * exp(-r^2 / (2 * radius^2))
                return -depth * exp(-r2 / (2 * radius * radius))
            }
        }

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -6,
            centerY: impact,
            width: 0.8,
            momentumX: momentum,
            potential: PotentialBuffer(values: values)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
