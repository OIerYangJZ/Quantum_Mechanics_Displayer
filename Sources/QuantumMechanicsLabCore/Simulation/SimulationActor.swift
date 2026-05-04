import Foundation

public actor SimulationActor {
    private var solver: any ExperimentSolver
    private var isRunning = false

    public init(solver: any ExperimentSolver) {
        self.solver = solver
    }

    public func snapshot() -> SimulationSnapshot {
        solver.currentSnapshot
    }

    public func setRunning(_ running: Bool) {
        isRunning = running
    }

    public func step(count: Int = 1) -> SimulationSnapshot {
        solver.step(count: count)
    }

    public func reset(to snapshot: SimulationSnapshot) {
        solver.reset(to: snapshot)
    }
}
