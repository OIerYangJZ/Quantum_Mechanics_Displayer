import Foundation

public struct MorsePotentialExperiment: Experiment {
    public let id = "morse-potential"
    public let title = "Morse Potential (Molecular Bond)"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket oscillating in an asymmetric well that models a diatomic molecular bond."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "depth", label: "Well Depth (De)", value: 15, range: 5...40),
            ExperimentParameter(id: "width", label: "Well Width (a)", value: 0.8, range: 0.2...3),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 0, range: -10...10)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "asymmetry", title: "Asymmetric Oscillation", body: "Unlike a perfect harmonic oscillator, the Morse potential is repulsive near the origin (atoms colliding) but flattens out at long distances (dissociation)."),
            StoryStep(id: "dissociation", title: "Dissociation", body: "If given enough energy, the wavepacket can escape the well and travel to infinity, representing a broken molecular bond.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let d = parameters.value(for: "depth", default: 15)
        let a = parameters.value(for: "width", default: 0.8)
        let momentum = parameters.value(for: "momentum", default: 0)

        let xe = -2.0 // Equilibrium distance

        // V(x) = D_e * (1 - e^{-a(x - x_e)})^2
        let potential = PotentialBuffer(values: grid.xValues.map { x in
            let term = 1.0 - exp(-a * (x - xe))
            return d * term * term
        })

        // Start slightly displaced from equilibrium
        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: xe + 1.5,
            width: 0.6,
            momentum: momentum,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
