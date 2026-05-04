import Foundation

public struct QuantumCorral2DExperiment: Experiment {
    public let id = "quantum-corral-2d"
    public let title = "2D Quantum Corral"
    public let category = ExperimentCategory.twoD
    public let summary = "A wavepacket confined within a circular ring of potential, forming complex standing waves."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "radius", label: "Corral Radius", value: 5, range: 2...8),
            ExperimentParameter(id: "thickness", label: "Wall Thickness", value: 0.5, range: 0.2...2),
            ExperimentParameter(id: "height", label: "Wall Height", value: 50, range: 10...100)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "standing-waves", title: "Confinement and Ripples", body: "The circular boundary acts as a mirror, reflecting the wavepacket back toward the center and creating intricate interference ripples.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid2D()
        let radius = parameters.value(for: "radius", default: 5)
        let thickness = parameters.value(for: "thickness", default: 0.5)
        let height = parameters.value(for: "height", default: 50)

        let values = (0..<grid.height).flatMap { row in
            (0..<grid.width).map { column in
                let x = grid.xValue(at: column)
                let y = grid.yValue(at: row)
                let r = sqrt(x * x + y * y)
                if abs(r - radius) < thickness / 2 {
                    return height
                } else if r > radius + thickness / 2 {
                    return 10.0 // Slightly raised outside to keep it contained
                }
                return 0.0
            }
        }

        return TwoDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            centerX: -2,
            centerY: 0,
            width: 0.8,
            momentumX: 4,
            momentumY: 3,
            potential: PotentialBuffer(values: values)
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] { [] }
}
