# Local Validation Guide

This document outlines the procedures for validating the Quantum Mechanics Lab application locally on macOS or iOS simulators.

## 1. Automated Testing

The project includes a comprehensive suite of unit tests. Run them from the command line using Swift Package Manager or through Xcode.

### Command Line
```bash
scripts/verify_release_candidate.sh
```

### Xcode
1. Open `QuantumMechanicsLab.xcodeproj`.
2. Select the `QuantumMechanicsLab` scheme.
3. Press `Cmd + U` to run the test suite.

The test suite (`QuantumMechanicsLabCoreTests`) covers:
- Core numerical accuracy.
- 1D free wavepacket momentum evolution.
- Harmonic oscillator energy conservation (drift bounds).
- 2D double-slit potential structure.
- 2D barrier scattering symmetry.
- Analytical hydrogen orbital validation.

## 2. UI and Interaction Testing

Refer to `UITestPlan.md` for a comprehensive manual UI test plan. Key validation areas include:
- **Experiment Selection:** Switching between 1D, 2D, and Orbital experiments without crashing.
- **Playback Controls:** Starting, pausing, and resetting the time evolution.
- **Parameters:** Adjusting sliders (e.g., Mass, Momentum) and observing instant visual updates.
- **Custom Potentials:** Drawing potentials, saving them as presets, loading presets, and deleting them.

## 3. Export Capabilities

To validate the export functions:
1. Open the inspector panel.
2. Select **Export JSON** to verify the snapshot state serializes correctly.
3. For 1D experiments, select **Export CSV** to verify the generation of density and potential values.
4. Try to save these files locally to ensure the `fileExporter` workflow behaves correctly in macOS/iOS.

## 4. TestFlight Candidate Gate

Before creating a TestFlight beta archive, run:

```bash
scripts/verify_release_candidate.sh
```

This command runs SwiftPM tests, the core smoke executable, regenerates the Xcode project, checks generator drift, and builds the iOS simulator test bundle with signing disabled.

See `docs/testflight_release.md` for the signed archive and optional upload flow.
