import Foundation

public struct DoubleSlit2DExperiment: Experiment {
    public let id = "double-slit-2d"
    public let title = "2D Double Slit"
    public let category = ExperimentCategory.twoD
    public let summary = "A two-dimensional packet forming an interference pattern after passing through two slits."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "slitSeparation", label: "Slit Separation", value: 3, range: 0.5...8),
            ExperimentParameter(id: "slitWidth", label: "Slit Width", value: 0.5, range: 0.1...2),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 5, range: 0...12)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "interference", title: "Interference", body: "The two openings create overlapping probability amplitudes downstream.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let slitSeparation = parameters.value(for: "slitSeparation", default: 3)
        let slitWidth = parameters.value(for: "slitWidth", default: 0.5)
        let momentum = parameters.value(for: "momentum", default: 5)
        let barrierHeight = 80.0
        let barrierHalfThickness = 0.18
        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                let inBarrier = abs(x) < barrierHalfThickness
                let upperSlit = abs(y - slitSeparation / 2) < slitWidth / 2
                let lowerSlit = abs(y + slitSeparation / 2) < slitWidth / 2
                return inBarrier && !(upperSlit || lowerSlit) ? barrierHeight : 0
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
        let separation = parameters.value(for: "slitSeparation", default: 3)
        let width = parameters.value(for: "slitWidth", default: 0.5)
        guard width < separation else {
            return [ParameterIssue(id: "slit-overlap", message: "Slit width should be smaller than slit separation.")]
        }
        return []
    }
}
