import Foundation

public struct BarrierScattering2DExperiment: Experiment {
    public let id = "barrier-scattering-2d"
    public let title = "2D Barrier Scattering"
    public let category = ExperimentCategory.twoD
    public let summary = "A 2D packet reflecting, diffracting, and transmitting around a barrier."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 5, range: 0...20),
            ExperimentParameter(id: "barrierRadius", label: "Barrier Radius", value: 2, range: 0.2...5),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 4, range: 0...12)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "scatter", title: "Scattering", body: "The barrier reshapes the packet into reflected and transmitted wavefronts.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let barrierHeight = parameters.value(for: "barrierHeight", default: 5)
        let barrierRadius = parameters.value(for: "barrierRadius", default: 2)
        let momentum = parameters.value(for: "momentum", default: 4)
        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                let distance = sqrt(x * x + y * y)
                return distance < barrierRadius ? barrierHeight : 0
            }
        }

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -6,
            centerY: 0,
            width: 0.9,
            momentumX: momentum,
            potential: PotentialBuffer(values: values)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
