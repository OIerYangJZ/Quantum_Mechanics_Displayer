import Darwin
import Foundation
import QuantumMechanicsLabCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("Smoke test failed: \(message)\n", stderr)
        exit(1)
    }
}

let catalog = ExperimentCatalog.all
expect(catalog.count == 20, "catalog should contain the current experiment set")
expect(ExperimentCatalog.experiment(id: "infinite-square-well") != nil, "missing infinite square well")
expect(ExperimentCatalog.experiment(id: "hydrogen-orbitals") != nil, "missing hydrogen orbitals")

let squareWellSnapshot = InfiniteSquareWellExperiment().makeInitialSnapshot()
expect(abs(squareWellSnapshot.observables.norm - 1) < 1e-10, "square well initial state should be normalized")
expect(abs(squareWellSnapshot.diagnostics.norm - 1) < 1e-10, "diagnostic norm should match observable norm")

var oneDSolver = SchrodingerSolver1D(initialSnapshot: squareWellSnapshot)
let evolvedSquareWell = oneDSolver.step(count: 10)
expect(evolvedSquareWell.diagnostics.stepCount == 10, "1D solver should advance step count")
expect(evolvedSquareWell.time > squareWellSnapshot.time, "1D solver should advance time")
expect(abs(evolvedSquareWell.observables.norm - 1) < 1e-6, "1D split-operator step should preserve norm")

let doubleSlitSnapshot = DoubleSlit2DExperiment().makeInitialSnapshot()
expect(doubleSlitSnapshot.psi.count > 0, "2D double-slit initial state should contain samples")
expect((doubleSlitSnapshot.potential?.values.count ?? 0) == doubleSlitSnapshot.psi.count, "2D double-slit potential should match psi count")
expect(doubleSlitSnapshot.diagnostics.maxProbabilityDensity > 0, "2D double-slit density should be nonzero")
expect(abs(doubleSlitSnapshot.observables.norm - 1) < 1e-10, "2D double-slit initial state should be normalized")

var twoDSolver = SchrodingerSolver2D(initialSnapshot: doubleSlitSnapshot)
let evolvedDoubleSlit = twoDSolver.step(count: 1)
expect(evolvedDoubleSlit.diagnostics.stepCount == 1, "2D solver should advance step count")
expect(evolvedDoubleSlit.time > doubleSlitSnapshot.time, "2D solver should advance time")
expect(abs(evolvedDoubleSlit.observables.norm - 1) < 1e-3, "2D split-operator step should preserve norm within sponge-layer tolerance")

let hydrogen = HydrogenOrbitalExperiment()
let orbitalSnapshot = hydrogen.makeInitialSnapshot(parameters: [
    ExperimentParameter(id: "n", label: "n", value: 2, range: 1...5),
    ExperimentParameter(id: "l", label: "l", value: 1, range: 0...4),
    ExperimentParameter(id: "m", label: "m", value: 1, range: -4...4)
])
expect(orbitalSnapshot.psi.count > 1, "hydrogen orbital should contain a renderable slice")
expect(orbitalSnapshot.diagnostics.maxProbabilityDensity > 0, "hydrogen orbital density should be nonzero")

let invalidHydrogenParameters = [
    ExperimentParameter(id: "n", label: "n", value: 2, range: 1...5),
    ExperimentParameter(id: "l", label: "l", value: 2, range: 0...4),
    ExperimentParameter(id: "m", label: "m", value: 0, range: -4...4)
]
expect(!hydrogen.validate(parameters: invalidHydrogenParameters).isEmpty, "invalid hydrogen quantum numbers should be rejected")

print("QuantumMechanicsLabCore smoke tests passed.")
