import Foundation

public struct CustomPotentialExperiment: Experiment {
    public let id = "custom-potential"
    public let title = "Custom Potential"
    public let category = ExperimentCategory.oneD
    public let summary = "Draw V(x) with Apple Pencil and release a packet into the landscape."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "brushSize", label: "Brush Size", value: 0.1, range: 0.01...0.3),
            ExperimentParameter(id: "smoothing", label: "Brush Smoothing", value: 0.25, range: 0...1),
            ExperimentParameter(id: "heightScale", label: "Height Scale", value: 5, range: 1...20),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 3, range: -15...15)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "draw", title: "Draw a potential", body: "The drawn curve becomes the potential energy landscape."),
            StoryStep(id: "release", title: "Release a packet", body: "Tap and flick to place the initial wavepacket and set its momentum.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let heightScale = parameters.value(for: "heightScale", default: 5)
        let potential = PotentialBuffer(values: grid.xValues.map { heightScale * (0.1 * sin($0) + 0.05 * sin(2 * $0)) })
        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -4,
            width: 0.7,
            momentum: 3,
            potential: potential
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
