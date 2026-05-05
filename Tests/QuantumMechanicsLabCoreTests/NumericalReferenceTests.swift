import XCTest
@testable import QuantumMechanicsLabCore

final class NumericalReferenceTests: XCTestCase {
    func testCatalogContainsInitialExperimentSet() {
        let experiments = ExperimentCatalog.all

        XCTAssertEqual(experiments.count, 20)
        XCTAssertNotNil(ExperimentCatalog.experiment(id: "infinite-square-well"))
        XCTAssertNotNil(ExperimentCatalog.experiment(id: "hydrogen-orbitals"))
        XCTAssertEqual(ExperimentCatalog.experiments(in: .oneD).count, 12)
        XCTAssertEqual(ExperimentCatalog.experiments(in: .twoD).count, 7)
        XCTAssertEqual(ExperimentCatalog.experiments(in: .orbitals).count, 1)
    }

    func testInfiniteSquareWellInitialStateIsNormalized() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "infinite-square-well"))
        let snapshot = experiment.makeInitialSnapshot()

        guard case let .oneD(grid) = snapshot.grid else {
            return XCTFail("Expected a 1D grid.")
        }

        XCTAssertEqual(snapshot.psi.norm(spacing: grid.spacing), 1, accuracy: 1e-10)
        XCTAssertEqual(snapshot.observables.norm, 1, accuracy: 1e-10)
        XCTAssertEqual(snapshot.diagnostics.norm, 1, accuracy: 1e-10)
        XCTAssertNil(snapshot.diagnostics.warning)
    }

    func testOneDSolverPreservesNormOverShortRun() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "infinite-square-well"))
        let initialSnapshot = experiment.makeInitialSnapshot()
        var solver = SchrodingerSolver1D(initialSnapshot: initialSnapshot, timeStep: 0.001)

        let evolved = solver.step(count: 25)

        guard case let .oneD(grid) = evolved.grid else {
            return XCTFail("Expected a 1D grid.")
        }

        XCTAssertEqual(evolved.time, 0.025, accuracy: 1e-12)
        XCTAssertEqual(evolved.diagnostics.stepCount, 25)
        XCTAssertEqual(evolved.psi.norm(spacing: grid.spacing), 1, accuracy: 1e-8)
        XCTAssertEqual(evolved.observables.norm, 1, accuracy: 1e-8)
        XCTAssertNil(evolved.diagnostics.warning)
    }

    func testOneDSolverAcceptsContinuousDeltaTime() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "infinite-square-well"))
        let initialSnapshot = experiment.makeInitialSnapshot()
        var solver = SchrodingerSolver1D(initialSnapshot: initialSnapshot, timeStep: 0.002)

        let evolved = solver.step(deltaTime: 0.0037)

        guard case let .oneD(grid) = evolved.grid else {
            return XCTFail("Expected a 1D grid.")
        }

        XCTAssertEqual(evolved.time, 0.0037, accuracy: 1e-12)
        XCTAssertEqual(evolved.diagnostics.stepCount, 2)
        XCTAssertEqual(evolved.psi.norm(spacing: grid.spacing), 1, accuracy: 1e-8)
    }

    func testDoubleSlitInitialStateHasDensityAndPotential() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "double-slit-2d"))
        let snapshot = experiment.makeInitialSnapshot()

        guard case let .twoD(grid) = snapshot.grid else {
            return XCTFail("Expected a 2D grid.")
        }

        XCTAssertEqual(snapshot.psi.count, grid.pointCount)
        XCTAssertEqual(snapshot.potential?.values.count, grid.pointCount)
        XCTAssertGreaterThan(snapshot.diagnostics.maxProbabilityDensity, 0)
        XCTAssertEqual(snapshot.psi.norm(spacing: grid.spacingX * grid.spacingY), 1, accuracy: 1e-10)
        XCTAssertEqual(snapshot.observables.norm, 1, accuracy: 1e-10)
    }

    func testTwoDSolverPreservesNormForSingleStep() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "double-slit-2d"))
        let initialSnapshot = experiment.makeInitialSnapshot()
        var solver = SchrodingerSolver2D(initialSnapshot: initialSnapshot, timeStep: 0.001)

        let evolved = solver.step(count: 1)

        guard case let .twoD(grid) = evolved.grid else {
            return XCTFail("Expected a 2D grid.")
        }

        XCTAssertEqual(evolved.time, 0.001, accuracy: 1e-12)
        XCTAssertEqual(evolved.diagnostics.stepCount, 1)
        // Relaxed tolerance because of 2D absorbing boundaries (sponge layer)
        XCTAssertEqual(evolved.psi.norm(spacing: grid.spacingX * grid.spacingY), 1, accuracy: 1e-3)
        XCTAssertEqual(evolved.observables.norm, 1, accuracy: 1e-3)
        XCTAssertNil(evolved.diagnostics.warning)
    }

    func testHydrogenQuantumNumberValidation() {
        let experiment = HydrogenOrbitalExperiment()
        var parameters = experiment.defaultParameters

        parameters[id: "n"] = 2
        parameters[id: "l"] = 2
        parameters[id: "m"] = 2

        let issues = experiment.validate(parameters: parameters)

        XCTAssertTrue(issues.contains { $0.id == "l-range" })
        XCTAssertFalse(issues.contains { $0.id == "m-range" })

        parameters[id: "l"] = 1
        parameters[id: "m"] = 2

        let mIssues = experiment.validate(parameters: parameters)

        XCTAssertFalse(mIssues.contains { $0.id == "l-range" })
        XCTAssertTrue(mIssues.contains { $0.id == "m-range" })
    }

    func testHydrogenOrbitalSnapshotContainsRenderableSlice() {
        let experiment = HydrogenOrbitalExperiment()
        var parameters = experiment.defaultParameters
        parameters[id: "n"] = 2
        parameters[id: "l"] = 1
        parameters[id: "m"] = 1

        let snapshot = experiment.makeInitialSnapshot(parameters: parameters)

        guard case let .orbital(resolution) = snapshot.grid else {
            return XCTFail("Expected an orbital grid.")
        }

        XCTAssertEqual(snapshot.psi.count, resolution * resolution)
        XCTAssertGreaterThan(snapshot.diagnostics.maxProbabilityDensity, 0)
        XCTAssertEqual(snapshot.observables.totalEnergy ?? 0, -0.125, accuracy: 1e-12)
    }

    func testFreeWavepacketMovesInMomentumDirection() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "free-wavepacket"))
        var parameters = experiment.defaultParameters
        parameters[id: "momentum"] = 3.0

        let initialSnapshot = experiment.makeInitialSnapshot(parameters: parameters)
        var solver = SchrodingerSolver1D(initialSnapshot: initialSnapshot, timeStep: 0.001)

        let evolved = solver.step(count: 50)

        let initialX = initialSnapshot.observables.expectedX ?? 0
        let finalX = evolved.observables.expectedX ?? 0

        XCTAssertGreaterThan(finalX, initialX)
        XCTAssertEqual(evolved.observables.norm, 1, accuracy: 1e-5)
    }

    func testHarmonicOscillatorEnergyDrift() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "harmonic-oscillator"))
        let initialSnapshot = experiment.makeInitialSnapshot()
        var solver = SchrodingerSolver1D(initialSnapshot: initialSnapshot, timeStep: 0.001)

        let evolved = solver.step(count: 50)

        let initialEnergy = initialSnapshot.observables.totalEnergy ?? 0
        let finalEnergy = evolved.observables.totalEnergy ?? 0

        XCTAssertEqual(finalEnergy, initialEnergy, accuracy: 1e-3)
    }

    func testDoubleSlitPotentialStructure() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "double-slit-2d"))
        var parameters = experiment.defaultParameters
        parameters[id: "slitSeparation"] = 3
        parameters[id: "slitWidth"] = 0.5
        let snapshot = experiment.makeInitialSnapshot(parameters: parameters)

        guard case let .twoD(grid) = snapshot.grid,
              let potential = snapshot.potential else {
            return XCTFail("Expected a 2D grid and potential.")
        }

        let centerCol = grid.width / 2
        let slit1Row = (0..<grid.height).first { abs(grid.yValue(at: $0) - 1.5) < 0.1 } ?? 0
        let barrierRow = grid.height / 2

        let barrierIdx = grid.linearIndex(column: centerCol, row: barrierRow)
        XCTAssertGreaterThan(potential.values[barrierIdx], 0)

        let slitIdx = grid.linearIndex(column: centerCol, row: slit1Row)
        XCTAssertEqual(potential.values[slitIdx], 0)
    }

    func testBarrierScatteringSymmetry() throws {
        let experiment = try XCTUnwrap(ExperimentCatalog.experiment(id: "barrier-scattering-2d"))
        var parameters = experiment.defaultParameters
        parameters[id: "barrierRadius"] = 2
        let snapshot = experiment.makeInitialSnapshot(parameters: parameters)

        guard case let .twoD(grid) = snapshot.grid,
              let potential = snapshot.potential else {
            return XCTFail("Expected a 2D grid and potential.")
        }

        let centerCol = grid.width / 2
        let centerRow = grid.height / 2
        let centerIdx = grid.linearIndex(column: centerCol, row: centerRow)

        XCTAssertGreaterThan(potential.values[centerIdx], 0)

        let rightRow = centerRow
        let rightCol = (0..<grid.width).first { grid.xValue(at: $0) > 2.5 } ?? grid.width - 1
        let rightIdx = grid.linearIndex(column: rightCol, row: rightRow)
        XCTAssertEqual(potential.values[rightIdx], 0)

        let upRow = (0..<grid.height).first { grid.yValue(at: $0) > 2.5 } ?? grid.height - 1
        let upCol = centerCol
        let upIdx = grid.linearIndex(column: upCol, row: upRow)
        XCTAssertEqual(potential.values[upIdx], 0)
    }
}

private extension Array where Element == ExperimentParameter {
    subscript(id id: String) -> Double {
        get {
            first { $0.id == id }?.value ?? 0
        }
        set {
            guard let index = firstIndex(where: { $0.id == id }) else {
                return
            }
            self[index].value = newValue
        }
    }
}
