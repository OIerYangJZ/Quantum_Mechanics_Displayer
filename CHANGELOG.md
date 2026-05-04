# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- True Metal Texture rendering (`MTKView` / `MTLTexture`) for the 2D Wavefunction Canvas, significantly improving performance.
- Custom potential preset persistence using `UserDefaults` (`UserDefaultsProjectStore`).
- Data Export capabilities: Export simulation snapshots to JSON and 1D simulation data (density/potential) to CSV.
- Xcode unit test target generation via `scripts/generate_xcode_project.swift`.
- Numerical regression tests for 1D wavepackets, harmonic oscillator energy drift, and 2D potential structures.
- Automated and manual validation plans (`docs/local_validation.md`, `UITestPlan.md`).

### Fixed
- Sendable conformance warning in `UserDefaultsProjectStore`.
- Type-checking bug in `AppModel` preset loader when evaluating grid point counts.

### Changed
- Upgraded the 1D custom potential tool to debounce drawing and update the solver smoothly.
