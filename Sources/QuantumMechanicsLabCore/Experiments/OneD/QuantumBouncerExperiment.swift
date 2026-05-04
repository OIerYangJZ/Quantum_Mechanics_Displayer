import Foundation

public struct QuantumBouncerExperiment: Experiment {
    public let id = "quantum-bouncer"
    public let title = "Quantum Bouncer"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket bouncing on a hard floor under a constant linear force (like gravity)."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "gravity", label: "Gravity (Force)", value: 5, range: 0.5...20),
            ExperimentParameter(id: "initialHeight", label: "Drop Height", value: 5, range: 1...9),
            ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "bouncing", title: "Quantum Bouncing", body: "Unlike a classical ball, the quantum wavepacket spreads out and its different components interfere as they bounce against the hard floor, creating complex interference patterns."),
            StoryStep(id: "airy", title: "Airy Functions", body: "The exact stationary states for this linear potential are described by Airy functions.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let g = parameters.value(for: "gravity", default: 5)
        let height = parameters.value(for: "initialHeight", default: 5)
        let mass = parameters.value(for: "mass", default: 1)

        // Hard wall at x = 0 (or some origin), linear potential V(x) = mgx for x > 0
        let floorX: Double = -5.0 // Shift floor a bit to the left so it looks nice on screen

        let potential = PotentialBuffer(values: grid.xValues.map { x in
            if x <= floorX {
                return 80 // Infinite wall (floor)
            } else {
                return mass * g * (x - floorX) // Linear ramp V(x) = mgx
            }
        })

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: floorX + height,
            width: 0.7,
            momentum: 0, // Dropping from rest
            potential: potential,
            mass: mass
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
