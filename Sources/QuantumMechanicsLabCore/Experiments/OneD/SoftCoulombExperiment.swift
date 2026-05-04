import Foundation

public struct SoftCoulombExperiment: Experiment {
    public let id = "soft-coulomb"
    public let title = "1D Soft Coulomb Atom"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket in a 1D regularized Coulomb potential, modeling a 1D atom."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "charge", label: "Effective Charge (Z)", value: 10, range: 1...30),
            ExperimentParameter(id: "softening", label: "Softening Parameter", value: 0.5, range: 0.1...2),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 0, range: -10...10)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "bound-state", title: "Bound States", body: "The regularized Coulomb potential captures the wavepacket, similar to how a nucleus binds an electron.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let z = parameters.value(for: "charge", default: 10)
        let a = parameters.value(for: "softening", default: 0.5)
        let momentum = parameters.value(for: "momentum", default: 0)

        let potential = PotentialBuffer(values: grid.xValues.map { x in
            return -z / sqrt(x * x + a * a)
        })

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: 1.5,
            width: 0.8,
            momentum: momentum,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] { [] }
}
