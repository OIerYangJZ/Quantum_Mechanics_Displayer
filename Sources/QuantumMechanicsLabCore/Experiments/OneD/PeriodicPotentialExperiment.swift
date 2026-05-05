import Foundation

public struct PeriodicPotentialExperiment: Experiment {
    public let id = "periodic-potential"
    public let title = "Periodic Lattice"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket moving through a periodic crystal lattice potential (Kronig-Penney model)."






    public var explanation: String {
        """
        The Kronig-Penney model demonstrates electrons moving through a crystal lattice. The periodic arrangement of barriers creates energy bands and gaps. If the particle energy falls into a conduction band, it will travel through the entire lattice almost freely, despite the barriers. If it falls into a band gap, it will suffer Bragg reflection and be completely repelled.
        """
    }
    public var builtInPresets: [ExperimentPreset] {
        [
            ExperimentPreset(experimentID: "periodic-potential", name: "Conduction Band (Transmission)", parameters: [
                ExperimentParameter(id: "latticeSpacing", label: "Lattice Spacing", value: 1.5, range: 0.5...4),
                ExperimentParameter(id: "barrierWidth", label: "Barrier Width", value: 0.2, range: 0.05...1),
                ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 5, range: 0...40),
                ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 8, range: 0...15)
            ]),
            ExperimentPreset(experimentID: "periodic-potential", name: "Band Gap (Bragg Reflection)", parameters: [
                ExperimentParameter(id: "latticeSpacing", label: "Lattice Spacing", value: 1.5, range: 0.5...4),
                ExperimentParameter(id: "barrierWidth", label: "Barrier Width", value: 0.2, range: 0.05...1),
                ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 15, range: 0...40),
                ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 2, range: 0...15)
            ])
        ]
    }

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "latticeSpacing", label: "Lattice Spacing", value: 1.5, range: 0.5...4),
            ExperimentParameter(id: "barrierWidth", label: "Barrier Width", value: 0.2, range: 0.05...1),
            ExperimentParameter(id: "barrierHeight", label: "Barrier Height", value: 10, range: 0...40),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 6, range: 0...15)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "band-structure", title: "Band Structure effects", body: "Depending on its momentum, the wavepacket will either propagate freely (conduction band) or reflect (band gap).")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let spacing = parameters.value(for: "latticeSpacing", default: 1.5)
        let barrierWidth = parameters.value(for: "barrierWidth", default: 0.2)
        let barrierHeight = parameters.value(for: "barrierHeight", default: 10)
        let momentum = parameters.value(for: "momentum", default: 6)

        let potential = PotentialBuffer(values: grid.xValues.map { x in
            // Create a periodic potential starting from x > -1
            if x < -1 { return 0.0 }
            let modX = (x + 1).truncatingRemainder(dividingBy: spacing)
            if modX < barrierWidth {
                return barrierHeight
            }
            return 0.0
        })

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -5,
            width: 1.0,
            momentum: momentum,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        let spacing = parameters.value(for: "latticeSpacing", default: 1.5)
        let barrierWidth = parameters.value(for: "barrierWidth", default: 0.2)
        if barrierWidth >= spacing {
            return [ParameterIssue(id: "width-overlap", message: "Barrier width must be less than lattice spacing.")]
        }
        return []
    }
}
