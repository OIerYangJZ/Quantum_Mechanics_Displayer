import Foundation

public struct SingleSlit2DExperiment: Experiment {
    public let id = "single-slit-2d"
    public let title = "2D Single Slit"
    public let category = ExperimentCategory.twoD
    public let summary = "A two-dimensional packet undergoing diffraction after passing through a single slit."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "slitWidth", label: "Slit Width", value: 1.0, range: 0.2...4),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 5, range: 0...12)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "diffraction", title: "Diffraction", body: "As the wavepacket passes through the narrow opening, it spreads out spatially, demonstrating the wave nature of the particle.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let slitWidth = parameters.value(for: "slitWidth", default: 1.0)
        let momentum = parameters.value(for: "momentum", default: 5)
        let barrierHeight = 80.0
        let barrierHalfThickness = 0.18

        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                let inBarrier = abs(x) < barrierHalfThickness
                let inSlit = abs(y) < slitWidth / 2
                return inBarrier && !inSlit ? barrierHeight : 0
            }
        }

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -6,
            centerY: 0,
            width: 0.85,
            momentumX: momentum,
            potential: PotentialBuffer(values: values)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
