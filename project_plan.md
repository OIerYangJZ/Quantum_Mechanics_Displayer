# Specific Project Plan

## Product Definition

**Working title:** Quantum Mechanics Lab.

**Audience:** iPad users who are learning or teaching undergraduate quantum mechanics. The app should make time evolution, measurement intuition, tunneling, interference, uncertainty, and orbital structure directly inspectable rather than only described in equations.

**Primary product loop:**

1. Pick an experiment from a catalog.
2. Adjust a small set of meaningful physical parameters.
3. Run, pause, scrub, and reset the simulation.
4. Inspect the wavefunction, potential, expectation values, and conservation diagnostics.
5. Switch visualization modes without losing the current state.

**v1 goals:**

- Ship a single iPadOS app with no account system and no backend.
- Provide stable 1D simulations, a tactile Apple Pencil custom-potential workflow, 2D interference experiments, and analytic hydrogen orbitals.
- Make correctness visible through norm, energy, expectation-value overlays, and textbook reference cases.
- Keep the app responsive on supported iPads by degrading resolution before dropping UI responsiveness.

**v1 non-goals:**

- No many-body simulations, field theory, general PDE editor, cloud projects, social sharing, or research-grade solver claims.
- No symbolic algebra engine.
- No LLM tutor in v1. Treat tutoring as a post-launch extension only if the core app lands well.

## Stack And Constraints

**Stack:** Swift 6, SwiftUI, Accelerate (vDSP for FFT and linear algebra), Metal (for 2D rendering), SceneKit (for 3D orbitals), Swift Charts (for energy diagrams). Target iPadOS 18+. No backend at v1.

**Device assumptions:**

- Baseline target: recent iPad Air / iPad Pro hardware capable of 60fps SwiftUI and Metal rendering.
- 1D simulations should run comfortably at 1024 to 4096 grid points.
- 2D simulations should default to 256 x 256 and expose a performance setting for 128 x 128 / 256 x 256 / 512 x 512.
- If a frame budget is missed repeatedly, reduce simulation publish rate or grid resolution before blocking touch input.

**Quality bars:**

- Main-thread work stays under 4ms for normal frames.
- 1D simulation step batches stay under 8ms on target hardware.
- 2D simulation plus texture upload stays under the frame budget at 256 x 256.
- Pencil drawing latency target is below 20ms from stroke update to potential preview update.
- The app never displays a normalized-looking simulation if norm or energy diagnostics indicate numerical failure.

## Architecture

**Architecture:** Single iPad app, on-device simulation, MVVM with the `@Observable` macro. Simulation runs on a background actor, publishes psi snapshots to the main actor at the display refresh rate. Experiments are modular: each experiment is a self-contained module conforming to an `Experiment` protocol so adding new ones is mechanical.

### Suggested Folder Layout

```text
QuantumMechanicsLab/
  App/
    QuantumMechanicsLabApp.swift
    AppModel.swift
    NavigationShell.swift
  Experiments/
    Experiment.swift
    ExperimentCatalog.swift
    OneD/
      InfiniteSquareWellExperiment.swift
      HarmonicOscillatorExperiment.swift
      FiniteBarrierExperiment.swift
      FreeWavepacketExperiment.swift
      CustomPotentialExperiment.swift
    TwoD/
      DoubleSlit2DExperiment.swift
      BarrierScattering2DExperiment.swift
    Orbitals/
      HydrogenOrbitalExperiment.swift
  Simulation/
    ComplexBuffer.swift
    Grid1D.swift
    Grid2D.swift
    SchrodingerSolver1D.swift
    SchrodingerSolver2D.swift
    SimulationActor.swift
    SimulationSnapshot.swift
    Observables.swift
    Units.swift
  Rendering/
    WavefunctionCanvas1D.swift
    PotentialCanvas1D.swift
    PhaseColorMap.swift
    MetalWavefunctionView2D.swift
    OrbitalSceneView.swift
  Controls/
    InspectorPanel.swift
    TimelineControls.swift
    ParameterControls.swift
    DebugOverlay.swift
  Persistence/
    ExperimentPreset.swift
    LocalProjectStore.swift
  Tests/
    NumericalReferenceTests.swift
    ExperimentConfigurationTests.swift
```

### Core Data Flow

1. `NavigationShell` owns the selected experiment ID and shows the catalog, viewport, and inspector.
2. `ExperimentViewModel` creates the experiment configuration and starts or stops `SimulationActor`.
3. `SimulationActor` owns mutable solver state and runs in batches. It emits `SimulationSnapshot` values through `AsyncStream`.
4. The view model receives snapshots on the main actor and updates render-facing state.
5. Renderers consume immutable snapshot data. Views never mutate solver internals directly.
6. Inspector edits create typed parameter updates. The actor applies updates at a step boundary to avoid tearing.

### Protocol Shape

```swift
protocol Experiment: Identifiable, Sendable {
    associatedtype Parameters: Codable & Sendable
    associatedtype Snapshot: Sendable

    var id: String { get }
    var title: String { get }
    var category: ExperimentCategory { get }
    var defaultParameters: Parameters { get }
    var story: [StoryStep] { get }

    func makeInitialState(parameters: Parameters) throws -> ExperimentInitialState
    func makeSolver(parameters: Parameters) throws -> any ExperimentSolver
    func validate(parameters: Parameters) -> [ParameterIssue]
}
```

Keep the concrete protocol simple in implementation. If associated types become awkward for the catalog, wrap experiments in an `AnyExperiment` type at the app boundary.

### Snapshot Shape

```swift
struct SimulationSnapshot: Sendable {
    let experimentID: String
    let time: Double
    let grid: GridDescriptor
    let psi: ComplexBuffer
    let potential: PotentialBuffer?
    let observables: Observables
    let diagnostics: NumericalDiagnostics
}

struct NumericalDiagnostics: Sendable {
    let norm: Double
    let energy: Double?
    let energyDrift: Double?
    let maxProbabilityDensity: Double
    let stepCount: Int
    let warning: NumericalWarning?
}
```

Snapshots should be value-like and render-safe. Avoid exposing solver-owned mutable arrays directly to SwiftUI or Metal.

### Persistence

- Store user presets and last-opened experiment state locally as Codable JSON.
- Use `UserDefaults` or `AppStorage` for small settings such as color map, units, and preferred 2D resolution.
- Defer SwiftData until there is a clear need for a searchable project library.
- Export/import can be a post-v1 feature unless beta users strongly ask for it.

## Numerical Design

### Units

Use dimensionless simulation units in v1:

- `hbar = 1`
- default mass `m = 1`
- 1D domain `x in [-L/2, L/2]`
- energy and time displayed as dimensionless by default

Add an educational units label in the inspector, but avoid promising SI-unit physical calibration in v1.

### 1D Split-Operator Solver

Use the split-operator method:

```text
psi(t + dt) =
  exp(-i V dt / 2 hbar)
  FFT^-1[exp(-i p^2 dt / 2m hbar) FFT[exp(-i V dt / 2 hbar) psi(t)]]
```

Implementation details:

- Precompute the momentum grid and kinetic phase factors for each `(N, L, m, dt)` tuple.
- Precompute potential half-step phase factors whenever `V(x)` or `dt` changes.
- Use power-of-two grid sizes for FFT performance.
- Normalize the initial wavefunction exactly. Do not silently renormalize every frame unless a debug setting is enabled, because continuous renormalization can hide solver mistakes.
- Apply absorbing boundaries only for experiments that explicitly need open-space behavior.
- Parameter changes should be applied at solver step boundaries. For large discontinuous parameter changes, show a short diagnostic warning rather than pretending the prior energy should remain conserved.

### Boundary Conditions

The FFT split-operator method naturally assumes periodic boundaries. Treat this as an implementation detail that must be hidden from the physics shown to the user:

- For open-space experiments, place the packet far from the seam and use optional absorbing boundary masks near the edges.
- For finite barriers and custom potentials, keep the physically interesting region away from the periodic seam.
- For the infinite square well, model the box with steep wall potentials inside a larger computational domain so probability density is negligible at the FFT seam.
- Do not use the periodic seam as a reflecting wall.
- For strict textbook validation of infinite-square-well eigenstates, add a small reference solver using a sine-basis / Dirichlet-boundary formulation or compare against analytic states only in the region where the wall-potential approximation is valid.

Default values:

```text
N = 2048
L = 20
dt = 0.001 to 0.005 depending on experiment
snapshotPublishRate = display refresh rate, usually 60Hz
stepsPerSnapshot = derived from dt and playback speed
```

### Observables

Compute and expose:

- Norm: `sum |psi|^2 dx`
- Position expectation: `<x>`
- Momentum expectation: `<p>`
- Position variance: `Delta x`
- Momentum variance: `Delta p`
- Uncertainty product: `Delta x * Delta p`
- Total energy: `<T> + <V>`
- Energy drift from initial energy

Use these diagnostics both for UI overlays and automated tests.

### Reference Cases

Use textbook cases as regression checks:

| Case | Expected behavior | Test tolerance |
| --- | --- | --- |
| Infinite square well eigenstate | Probability density stationary, phase rotates in Dirichlet reference or validated wall model | norm error < 1e-6, energy drift < 1e-4 |
| Gaussian free packet | Center moves linearly, packet spreads | `<x>` slope within 1 percent |
| Harmonic oscillator coherent state | `<x>` oscillates sinusoidally | period within 1 percent |
| Finite barrier | Reflection + transmission, total norm conserved | norm error < 1e-5 |
| 2D double slit | Interference fringes form downstream | visual + statistical fringe spacing check |

## UX Structure

### Main App Layout

- Use `NavigationSplitView`.
- Sidebar: experiment catalog grouped by 1D, 2D, and 3D analytic orbitals.
- Center: primary viewport. It should always be the largest visual element.
- Right inspector: parameters, visualization mode, observables, and debug diagnostics.
- Bottom overlay: play/pause, reset, speed, and time scrubber.

### Visualization Modes

1D:

- Probability density `|psi|^2`
- Real part
- Imaginary part
- Phase color
- Potential overlay
- Expectation markers for `<x>` and uncertainty band

2D:

- Probability heatmap
- Phase hue with density brightness
- Potential mask overlay
- Optional contour lines for high-density regions

3D orbitals:

- Density isosurface
- Phase coloring for signed/complex orbitals
- Energy-level diagram beside the scene

### Inspector Controls

Use the smallest useful controls:

- Sliders for continuous values such as mass, packet width, barrier height, and playback speed.
- Steppers for quantum numbers `(n, l, m)` where legal values are discrete.
- Segmented controls for visualization mode.
- Toggle controls for overlays.
- Preset menu for common configurations.
- Reset button for returning an experiment to its default state.

Parameter labels should use physics notation where helpful, but every control also needs an accessibility label with a plain-language name.

### Story Mode

Each experiment should have a short story script:

- 3 to 6 steps per experiment.
- Each step sets or highlights a parameter, points to a region of the viewport, and names the concept being shown.
- Story mode should be optional and dismissible.
- Story scripts are local data, not hard-coded inside view bodies.

## Phase 1 - Foundation (Weeks 1-3)

**Goal:** Prove the full app pipeline with one correct and inspectable experiment.

### Week 1: App Shell And Numerical Skeleton

- Create the Xcode project with SwiftUI lifecycle.
- Add the `NavigationSplitView` shell with placeholder catalog, viewport, inspector, and timeline controls.
- Implement `ComplexBuffer`, `Grid1D`, and unit helpers.
- Build `SimulationActor` with start, pause, reset, speed, and cancellation.
- Add a minimal `Experiment` protocol and `ExperimentCatalog`.
- Add a placeholder debug overlay with time, step count, and FPS.

Deliverable: selecting "Infinite Square Well" starts a placeholder simulation and publishes snapshots without blocking UI.

### Week 2: 1D Solver

- Implement `SchrodingerSolver1D` using the split-operator method.
- Add vDSP FFT setup and plan reuse.
- Implement Gaussian wavepacket initialization.
- Implement infinite square well wall potentials with a guard region that keeps probability density away from the FFT seam.
- Compute norm and energy diagnostics.
- Add unit tests for normalization, FFT round trip, wall reflection, and stationary-state behavior in the validated region.

Deliverable: a Gaussian wavepacket evolves in a box with stable norm.

### Week 3: First Usable Experiment

- Render `|psi|^2` as a line plot in SwiftUI `Canvas`.
- Overlay the potential boundary and expectation marker.
- Add play, pause, reset, speed, and scrubber controls.
- Add debug overlay with norm, energy, and energy drift.
- Add one guided story for the infinite square well.
- Tune default `N`, `dt`, and speed so the motion reads well visually.

**Exit criteria:** a Gaussian wavepacket bouncing in a box at 60fps, with energy and norm conservation visible in a debug overlay. Norm should stay near `1.000`, and energy should be flat except after intentional parameter changes.

## Phase 2 - Core 1D Experiments (Weeks 4-6)

**Goal:** Build the reusable 1D experiment system and prove it across several canonical cases.

### Experiments

1. Harmonic oscillator:
   - Potential: `V(x) = 0.5 m omega^2 x^2`
   - Parameters: mass, omega, initial center, initial momentum, packet width
   - Reference behavior: coherent-state-like packet oscillation

2. Finite barrier:
   - Potential: rectangular barrier with editable width and height
   - Parameters: barrier height, barrier width, packet momentum, packet width
   - Reference behavior: reflection plus tunneling

3. Free Gaussian wavepacket:
   - Potential: zero or optional absorbing boundary
   - Parameters: initial center, momentum, width, mass
   - Reference behavior: linear motion and spreading

4. Infinite square well:
   - Keep as the stable baseline and test target

### Shared Features

- Inspector panel with live parameter binding.
- Parameter validation with clear bounds and reset behavior.
- Visualization modes: probability density, real part, imaginary part, and phase color.
- Expectation overlays: `<x>`, `<p>`, `Delta x`, `Delta p`, and `Delta x * Delta p`.
- Energy chart showing drift over time.
- Presets for each experiment, such as "low energy", "near barrier top", and "wide packet".

### Live Parameter Rules

- Changes to visual-only settings apply immediately.
- Changes to physical parameters update the solver at the next step boundary.
- Changes that invalidate the current wavefunction, such as domain size or grid resolution, require a reset.
- For barrier and potential changes during playback, keep the wavefunction but reset the energy-drift baseline because the Hamiltonian changed.

**Exit criteria:** four working 1D experiments, parameters adjustable live where physically and numerically valid, all stable under normal presets, and reference tests passing.

## Phase 3 - Apple Pencil Custom Potential (Weeks 7-8)

**Goal:** Make the app feel tactile and distinctive.

### Custom Potential Editor

- Build a drawing canvas where horizontal position maps to `x` and vertical position maps to `V(x)`.
- Sample Pencil strokes into the potential array at solver resolution.
- Smooth strokes with a configurable low-pass filter so accidental jitter does not create extreme high-frequency potentials.
- Clamp potential to visible and numerically safe bounds.
- Show the potential curve while drawing, even if the simulation is paused.
- Add undo, clear, and preset actions.

### Presets

- Square well
- Double well
- Ramp
- Barrier
- Soft harmonic trap
- Random smooth landscape

### Release Wavepacket Gesture

- Tap places the packet center.
- Flick sets initial momentum from gesture velocity.
- Pinch or inspector slider sets packet width.
- Show a short ghost preview of center, direction, and width before release.

### Latency Plan

- Pencil stroke updates should update a lightweight preview immediately on the main actor.
- The solver receives coalesced potential updates, not every raw Pencil event.
- Potential phase factors are recomputed on the simulation actor after a short debounce, targeting 30 to 60 updates per second while drawing.
- If recomputation falls behind, keep drawing smooth and apply the newest potential only.

**Exit criteria:** drawing a potential and seeing the wavefunction respond feels immediate, with no perceptible lag between Pencil input and simulation feedback on target hardware.

## Phase 4 - 2D And Metal (Weeks 9-12)

**Goal:** Add 2D interference and scattering without sacrificing responsiveness.

### Solver

- Implement `Grid2D` and `SchrodingerSolver2D`.
- Use separable 2D FFT operations: transform rows, then columns, then inverse columns and rows.
- Default grid is `256 x 256`; support `128 x 128` for older devices and `512 x 512` for high-end devices.
- Precompute `kx`, `ky`, and kinetic phase values.
- Keep 2D snapshots compact. Avoid copying unnecessary intermediate buffers to the main actor.

### Metal Renderer

- Store probability density and phase in Metal textures.
- Use density as brightness and phase as hue.
- Add color-map options designed for both classroom projection and color-vision accessibility.
- Support pinch-zoom and pan without forcing a simulation reset.
- Keep the primary scene full-screen within the center viewport rather than placing it inside a decorative frame.

### Experiments

1. 2D double slit:
   - Editable slit separation, slit width, barrier thickness, packet momentum, and packet width.
   - Show the interference pattern building downstream.
   - Add optional detector-line profile chart.

2. 2D barrier scattering:
   - Editable rectangular or circular barrier.
   - Show reflection, diffraction, and transmitted wavefronts.

### Performance Strategy

- Simulation actor advances in batches.
- Renderer uses the latest available snapshot and drops stale snapshots.
- Provide a resolution selector in settings.
- Add an internal performance HUD for FPS, simulation milliseconds per batch, texture upload time, and memory.

**Exit criteria:** 2D double-slit runs at 60fps on a 256 x 256 grid, with a visibly building interference pattern and no touch-input lag.

## Phase 5 - Hydrogen Orbitals In 3D (Weeks 13-15)

**Goal:** Add analytic 3D visualizations that complement the solver-based experiments.

### Analytic Model

- No time-dependent solver is required.
- Evaluate hydrogen wavefunctions from radial functions and spherical harmonics.
- Valid quantum numbers:
  - `n >= 1`
  - `0 <= l < n`
  - `-l <= m <= l`
- Energy display: `E_n` depends only on `n` in the ideal hydrogen model.
- Use dimensionless Bohr-radius units by default.

### Rendering

- Generate a 3D density grid for selected `(n, l, m)`.
- Build an isosurface mesh from density using a marching-cubes implementation or a simpler fixed-threshold mesh if performance is sufficient.
- Color the surface by phase or sign where meaningful.
- Use SceneKit for rotation, zoom, lighting, and camera control.
- Cache generated meshes by `(n, l, m, resolution, threshold)`.
- Use lower mesh resolution while the user drags controls, then refine when interaction stops.

### UI

- Quantum-number steppers enforce valid combinations.
- Presets: `1s`, `2s`, `2p`, `3s`, `3p`, `3d`.
- Energy diagram shows the selected shell and nearby levels.
- Story mode explains nodes, angular momentum, and degeneracy.

**Exit criteria:** `1s`, `2s`, `2p`, and `3d` orbitals are renderable and rotatable, with shapes matching standard textbook images.

## Phase 6 - Beta Polish And Distribution (Weeks 16-18)

**Goal:** Convert the prototype into a stable GitHub-hosted beta that can be distributed through TestFlight to a focused group of learners, teachers, and technical reviewers.

### Product Polish

- First-run onboarding that launches directly into one simple experiment.
- Story mode for each shipped experiment.
- Settings screen:
  - color scheme
  - units display
  - performance mode
  - default grid resolution
  - accessibility options
- Saved presets for user-created custom potentials.
- App icon, launch screen, beta screenshots, and a concise TestFlight release note template.

### Accessibility

- VoiceOver labels for every control and important visualization region.
- Dynamic Type for inspector text and story content.
- Reduce Motion support for users who do not want continuous animation.
- Color maps with non-color-only cues where possible.
- Large touch targets for classroom and Pencil use.

### QA

- Run numerical reference tests on every build.
- Add manual test scripts for each experiment.
- Test rotation, split view, Stage Manager resizing, and low-power mode.
- Test at least two iPad sizes.
- Test Pencil and non-Pencil interaction paths.
- Run memory leak checks during long simulations.

### Beta

- TestFlight with 10 to 20 physics students, teachers, or technically literate learners.
- Collect feedback on:
  - which experiments are most understandable
  - which parameters feel confusing
  - whether the story mode helps or distracts
  - performance on real devices
  - missing classroom workflows
- Track all feedback in GitHub issues and close or explicitly defer the highest-impact usability, correctness, and performance problems before tagging the next beta.

**Exit criteria:** a tagged GitHub beta and TestFlight build are available, simulations are stable, educational value is clear, and there are no known blocking numerical or interaction bugs.

## Phase 7 - Optional LLM Tutor (Post-Launch)

Only if v1 lands well. Build a Cloudflare Worker that proxies to the Anthropic API, holds the key, and accepts a structured payload describing the current experiment and the user's question. In-app, add an "Ask about this" button that opens a chat sheet with context about the current state. This is the only piece that needs a backend, and it should stay small.

### Tutor Scope

- The tutor answers questions about the currently visible experiment.
- It receives structured state, not raw screenshots:
  - experiment ID
  - current parameters
  - time
  - selected visualization mode
  - key observables
  - active story step
- It should not claim the numerical model is exact beyond the app's documented assumptions.

### Backend Guardrails

- Keep API keys only in the worker.
- Add rate limiting.
- Avoid storing chat logs by default.
- Add a clear privacy note before enabling the feature.
- Include an off switch in settings.

## Testing Strategy

### Unit Tests

- Complex arithmetic helpers.
- FFT round trip.
- Grid spacing and momentum-grid construction.
- Initial-state normalization.
- Potential generation.
- Observable calculations.
- Parameter validation.

### Numerical Regression Tests

- Infinite square well eigenstate stationarity.
- Free Gaussian packet center and spread.
- Harmonic oscillator period.
- Barrier norm conservation.
- 2D double-slit smoke test at low resolution.
- Orbital quantum-number validation and known shape sanity checks.

### UI Tests

- Launch app and select each experiment.
- Start, pause, reset, and scrub timeline.
- Change common parameters.
- Switch visualization modes.
- Save and reload a custom potential preset.
- Rotate a 3D orbital.

### Manual Acceptance Checklist

- No simulation keeps running after leaving its view.
- Reset always returns to a known default.
- Parameter changes cannot crash the solver.
- Debug overlay reports warnings instead of silently failing.
- Long-running simulation does not leak memory.
- App remains usable when iPad is rotated or resized.

## Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| 2D simulation misses 60fps | Core visual feature feels weak | Add resolution scaling, snapshot dropping, and performance mode early |
| Pencil potential updates cause solver stalls | Differentiator feels laggy | Separate drawing preview from solver updates; debounce potential recomputation |
| Numerical diagnostics are misleading | Users learn wrong behavior | Use reference tests and show warnings when assumptions break |
| SceneKit orbital mesh generation is slow | 3D feature feels heavy | Cache meshes and use progressive refinement |
| Inspector becomes too complex | Learners get lost | Keep presets prominent and expose advanced values gradually |
| Story content delays shipping | v1 slips | Write short scripts, not textbook chapters |

## Milestone Summary

| Phase | Weeks | Main deliverable | Ship value |
| --- | --- | --- | --- |
| 1 | 1-3 | Infinite square well end-to-end | Proves architecture and solver |
| 2 | 4-6 | Four canonical 1D experiments | Core educational value |
| 3 | 7-8 | Apple Pencil custom potential | Distinctive interaction |
| 4 | 9-12 | 2D double slit and scattering | High-impact visualization |
| 5 | 13-15 | Hydrogen orbitals | Completes common QM curriculum coverage |
| 6 | 16-18 | Beta, polish, GitHub + TestFlight | Reviewable v1 beta |
| 7 | Post-launch | Optional contextual tutor | Extension, not v1 dependency |

## Definition Of Done For v1

- All Phase 1 through Phase 6 exit criteria are met.
- Numerical reference tests pass.
- Manual QA checklist is complete on at least two iPad configurations.
- The app has no backend dependency.
- The app can run a 10-minute continuous simulation without visible drift, memory growth, or UI stalls under default settings.
- TestFlight feedback has been reviewed and blocking issues have been fixed or explicitly deferred.
- GitHub release notes, beta screenshots, privacy notes, and TestFlight tester instructions are ready.
