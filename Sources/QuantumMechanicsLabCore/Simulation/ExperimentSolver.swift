import Accelerate
import Foundation

public protocol ExperimentSolver: Sendable {
    var currentSnapshot: SimulationSnapshot { get }

    mutating func step(count: Int) -> SimulationSnapshot
    mutating func step(deltaTime: Double) -> SimulationSnapshot
    mutating func reset(to snapshot: SimulationSnapshot)
}

public struct SchrodingerSolver1D: ExperimentSolver {
    public private(set) var currentSnapshot: SimulationSnapshot
    public var timeStep: Double
    public var mass: Double
    private var initialEnergy: Double?

    public init(
        initialSnapshot: SimulationSnapshot,
        timeStep: Double = 0.002,
        mass: Double = SimulationUnits.defaultMass
    ) {
        self.currentSnapshot = initialSnapshot
        self.timeStep = timeStep
        self.mass = mass
        self.initialEnergy = initialSnapshot.observables.totalEnergy
    }

    public mutating func step(count: Int) -> SimulationSnapshot {
        guard case let .oneD(grid) = currentSnapshot.grid else {
            currentSnapshot = currentSnapshot.advanced(
                by: Double(count) * timeStep,
                stepCount: count
            )
            return currentSnapshot
        }

        for _ in 0..<max(count, 0) {
            stepOnce(on: grid, deltaTime: timeStep)
        }

        return currentSnapshot
    }

    public mutating func step(deltaTime: Double) -> SimulationSnapshot {
        guard deltaTime > 0 else { return currentSnapshot }

        guard case let .oneD(grid) = currentSnapshot.grid else {
            let substeps = max(1, Int(ceil(deltaTime / timeStep)))
            currentSnapshot = currentSnapshot.advanced(by: deltaTime, stepCount: substeps)
            return currentSnapshot
        }

        let substeps = max(1, Int(ceil(deltaTime / timeStep)))
        let substepTime = deltaTime / Double(substeps)
        for _ in 0..<substeps {
            stepOnce(on: grid, deltaTime: substepTime)
        }

        return currentSnapshot
    }

    public mutating func reset(to snapshot: SimulationSnapshot) {
        currentSnapshot = snapshot
        initialEnergy = snapshot.observables.totalEnergy
    }

    private mutating func stepOnce(on grid: Grid1D, deltaTime: Double) {
        var psi = currentSnapshot.psi
        let potential = currentSnapshot.potential

        applyPotentialPhase(to: &psi, potential: potential, deltaTime: deltaTime / 2)
        psi = applyKineticPhase(to: psi, grid: grid, deltaTime: deltaTime)
        applyPotentialPhase(to: &psi, potential: potential, deltaTime: deltaTime / 2)

        let observables = ObservablesCalculator.oneD(
            psi: psi,
            grid: grid,
            potential: potential,
            mass: mass
        )
        let density = psi.probabilityDensity()
        let energyDrift = observables.totalEnergy.flatMap { energy in
            initialEnergy.map { energy - $0 }
        }
        let warning = warning(for: observables, energyDrift: energyDrift)

        currentSnapshot = SimulationSnapshot(
            experimentID: currentSnapshot.experimentID,
            time: currentSnapshot.time + deltaTime,
            grid: currentSnapshot.grid,
            psi: psi,
            potential: potential,
            observables: observables,
            diagnostics: NumericalDiagnostics(
                norm: observables.norm,
                energy: observables.totalEnergy,
                energyDrift: energyDrift,
                maxProbabilityDensity: density.max() ?? 0,
                stepCount: currentSnapshot.diagnostics.stepCount + 1,
                warning: warning
            )
        )
    }

    private func applyPotentialPhase(
        to psi: inout ComplexBuffer,
        potential: PotentialBuffer?,
        deltaTime: Double
    ) {
        guard let potential, potential.values.count == psi.count else {
            return
        }

        for index in psi.values.indices {
            let phase = -potential.values[index] * deltaTime / SimulationUnits.hbar
            psi[index] = psi[index] * ComplexValue(real: cos(phase), imaginary: sin(phase))
        }
    }

    private func applyKineticPhase(to psi: ComplexBuffer, grid: Grid1D, deltaTime: Double) -> ComplexBuffer {
        let frequencySpace = FourierTransform.complexForward(psi.values)
        let phased = frequencySpace.enumerated().map { index, value in
            let k = momentumWaveNumber(for: index, count: grid.pointCount, length: grid.length)
            let phase = -k * k * deltaTime / (2 * mass)
            return value * ComplexValue(real: cos(phase), imaginary: sin(phase))
        }

        return ComplexBuffer(values: FourierTransform.complexInverse(phased))
    }

    private func momentumWaveNumber(for index: Int, count: Int, length: Double) -> Double {
        let centeredIndex = index <= count / 2 ? index : index - count
        return 2 * .pi * Double(centeredIndex) / length
    }

    private func warning(for observables: Observables, energyDrift: Double?) -> NumericalWarning? {
        if abs(observables.norm - 1) > 0.01 {
            return .normDrift
        }

        if let energyDrift, let initialEnergy, abs(initialEnergy) > .ulpOfOne {
            let relativeDrift = abs(energyDrift / initialEnergy)
            if relativeDrift > 0.05 {
                return .energyDrift
            }
        }

        return nil
    }
}

public struct SchrodingerSolver2D: ExperimentSolver {
    public private(set) var currentSnapshot: SimulationSnapshot
    public var timeStep: Double
    public var mass: Double
    private var initialEnergy: Double?

    public init(
        initialSnapshot: SimulationSnapshot,
        timeStep: Double = 0.002,
        mass: Double = SimulationUnits.defaultMass
    ) {
        self.currentSnapshot = initialSnapshot
        self.timeStep = timeStep
        self.mass = mass
        self.initialEnergy = initialSnapshot.observables.totalEnergy
    }

    public mutating func step(count: Int) -> SimulationSnapshot {
        guard case let .twoD(grid) = currentSnapshot.grid else {
            currentSnapshot = currentSnapshot.advanced(
                by: Double(count) * timeStep,
                stepCount: count
            )
            return currentSnapshot
        }

        for _ in 0..<max(count, 0) {
            stepOnce(on: grid, deltaTime: timeStep)
        }

        return currentSnapshot
    }

    public mutating func step(deltaTime: Double) -> SimulationSnapshot {
        guard deltaTime > 0 else { return currentSnapshot }

        guard case let .twoD(grid) = currentSnapshot.grid else {
            let substeps = max(1, Int(ceil(deltaTime / timeStep)))
            currentSnapshot = currentSnapshot.advanced(by: deltaTime, stepCount: substeps)
            return currentSnapshot
        }

        let substeps = max(1, Int(ceil(deltaTime / timeStep)))
        let substepTime = deltaTime / Double(substeps)
        for _ in 0..<substeps {
            stepOnce(on: grid, deltaTime: substepTime)
        }

        return currentSnapshot
    }

    public mutating func reset(to snapshot: SimulationSnapshot) {
        currentSnapshot = snapshot
        initialEnergy = snapshot.observables.totalEnergy
    }

    private mutating func stepOnce(on grid: Grid2D, deltaTime: Double) {
        var psi = currentSnapshot.psi
        let potential = currentSnapshot.potential

        applyPotentialPhase(to: &psi, potential: potential, deltaTime: deltaTime / 2)
        psi = applyKineticPhase(to: psi, grid: grid, deltaTime: deltaTime)
        applyPotentialPhase(to: &psi, potential: potential, deltaTime: deltaTime / 2)
        applyAbsorbingBoundary(to: &psi, grid: grid)

        let observables = ObservablesCalculator.twoD(
            psi: psi,
            grid: grid,
            potential: potential,
            mass: mass
        )
        let density = psi.probabilityDensity()
        let energyDrift = observables.totalEnergy.flatMap { energy in
            initialEnergy.map { energy - $0 }
        }
        let warning = warning(for: observables, energyDrift: energyDrift)

        currentSnapshot = SimulationSnapshot(
            experimentID: currentSnapshot.experimentID,
            time: currentSnapshot.time + deltaTime,
            grid: currentSnapshot.grid,
            psi: psi,
            potential: potential,
            observables: observables,
            diagnostics: NumericalDiagnostics(
                norm: observables.norm,
                energy: observables.totalEnergy,
                energyDrift: energyDrift,
                maxProbabilityDensity: density.max() ?? 0,
                stepCount: currentSnapshot.diagnostics.stepCount + 1,
                warning: warning
            )
        )
    }

    private func applyPotentialPhase(
        to psi: inout ComplexBuffer,
        potential: PotentialBuffer?,
        deltaTime: Double
    ) {
        guard let potential, potential.values.count == psi.count else {
            return
        }

        for index in psi.values.indices {
            let phase = -potential.values[index] * deltaTime / SimulationUnits.hbar
            psi[index] = psi[index] * ComplexValue(real: cos(phase), imaginary: sin(phase))
        }
    }

    private func applyAbsorbingBoundary(to psi: inout ComplexBuffer, grid: Grid2D) {
        let spongeWidth = 2.0
        for row in 0..<grid.height {
            let y = grid.yValue(at: row)
            let dy = max(0, abs(y) - (grid.lengthY / 2 - spongeWidth))
            let maskY = dy > 0 ? cos(.pi / 2 * dy / spongeWidth) : 1.0

            for column in 0..<grid.width {
                let x = grid.xValue(at: column)
                let dx = max(0, abs(x) - (grid.lengthX / 2 - spongeWidth))
                let maskX = dx > 0 ? cos(.pi / 2 * dx / spongeWidth) : 1.0

                let index = grid.linearIndex(column: column, row: row)
                let mask = maskX * maskY
                psi[index] = psi[index] * ComplexValue(real: mask, imaginary: 0)
            }
        }
    }

    private func applyKineticPhase(to psi: ComplexBuffer, grid: Grid2D, deltaTime: Double) -> ComplexBuffer {
        let rowForward = transformRows(psi.values, grid: grid, inverse: false)
        let frequencySpace = transformColumns(rowForward, grid: grid, inverse: false)
        let phased = frequencySpace.enumerated().map { index, value in
            let column = index % grid.width
            let row = index / grid.width
            let kx = waveNumber(for: column, count: grid.width, length: grid.lengthX)
            let ky = waveNumber(for: row, count: grid.height, length: grid.lengthY)
            let phase = -(kx * kx + ky * ky) * deltaTime / (2 * mass)
            return value * ComplexValue(real: cos(phase), imaginary: sin(phase))
        }
        let columnInverse = transformColumns(phased, grid: grid, inverse: true)
        return ComplexBuffer(values: transformRows(columnInverse, grid: grid, inverse: true))
    }

    private func transformRows(_ values: [ComplexValue], grid: Grid2D, inverse: Bool) -> [ComplexValue] {
        guard values.count == grid.pointCount else {
            return values
        }

        var output = values
        for row in 0..<grid.height {
            let start = row * grid.width
            let rowValues = Array(values[start..<(start + grid.width)])
            let transformed = inverse
                ? FourierTransform.complexInverse(rowValues)
                : FourierTransform.complexForward(rowValues)
            for column in 0..<grid.width {
                output[start + column] = transformed[column]
            }
        }
        return output
    }

    private func transformColumns(_ values: [ComplexValue], grid: Grid2D, inverse: Bool) -> [ComplexValue] {
        guard values.count == grid.pointCount else {
            return values
        }

        var output = values
        for column in 0..<grid.width {
            var columnValues: [ComplexValue] = []
            columnValues.reserveCapacity(grid.height)
            for row in 0..<grid.height {
                columnValues.append(values[grid.linearIndex(column: column, row: row)])
            }
            let transformed = inverse
                ? FourierTransform.complexInverse(columnValues)
                : FourierTransform.complexForward(columnValues)
            for row in 0..<grid.height {
                output[grid.linearIndex(column: column, row: row)] = transformed[row]
            }
        }
        return output
    }

    private func waveNumber(for index: Int, count: Int, length: Double) -> Double {
        let centeredIndex = index <= count / 2 ? index : index - count
        return 2 * .pi * Double(centeredIndex) / length
    }

    private func warning(for observables: Observables, energyDrift: Double?) -> NumericalWarning? {
        if abs(observables.norm - 1) > 0.02 {
            return .normDrift
        }

        if let energyDrift, let initialEnergy, abs(initialEnergy) > .ulpOfOne {
            let relativeDrift = abs(energyDrift / initialEnergy)
            if relativeDrift > 0.10 {
                return .energyDrift
            }
        }

        return nil
    }
}

public struct OrbitalSolver: ExperimentSolver {
    public private(set) var currentSnapshot: SimulationSnapshot
    public var timeStep: Double

    public init(initialSnapshot: SimulationSnapshot, timeStep: Double = 0.05) {
        self.currentSnapshot = initialSnapshot
        self.timeStep = timeStep
    }

    public mutating func step(count: Int) -> SimulationSnapshot {
        guard case .orbital = currentSnapshot.grid,
              let energy = currentSnapshot.observables.totalEnergy else {
            currentSnapshot = currentSnapshot.advanced(by: Double(count) * timeStep, stepCount: count)
            return currentSnapshot
        }

        let dt = Double(count) * timeStep
        return evolveOrbital(deltaTime: dt, stepCount: count, energy: energy)
    }

    public mutating func step(deltaTime: Double) -> SimulationSnapshot {
        guard deltaTime > 0 else { return currentSnapshot }

        guard case .orbital = currentSnapshot.grid,
              let energy = currentSnapshot.observables.totalEnergy else {
            let substeps = max(1, Int(ceil(deltaTime / timeStep)))
            currentSnapshot = currentSnapshot.advanced(by: deltaTime, stepCount: substeps)
            return currentSnapshot
        }

        let substeps = max(1, Int(ceil(deltaTime / timeStep)))
        return evolveOrbital(deltaTime: deltaTime, stepCount: substeps, energy: energy)
    }

    private mutating func evolveOrbital(deltaTime dt: Double, stepCount: Int, energy: Double) -> SimulationSnapshot {
        var psi = currentSnapshot.psi
        let phase = -energy * dt / SimulationUnits.hbar
        let multiplier = ComplexValue(real: cos(phase), imaginary: sin(phase))

        for i in 0..<psi.count {
            psi[i] = psi[i] * multiplier
        }

        currentSnapshot = SimulationSnapshot(
            experimentID: currentSnapshot.experimentID,
            time: currentSnapshot.time + dt,
            grid: currentSnapshot.grid,
            psi: psi,
            potential: currentSnapshot.potential,
            observables: currentSnapshot.observables,
            diagnostics: NumericalDiagnostics(
                norm: currentSnapshot.diagnostics.norm,
                energy: currentSnapshot.diagnostics.energy,
                energyDrift: currentSnapshot.diagnostics.energyDrift,
                maxProbabilityDensity: currentSnapshot.diagnostics.maxProbabilityDensity,
                stepCount: currentSnapshot.diagnostics.stepCount + stepCount,
                warning: currentSnapshot.diagnostics.warning
            )
        )
        return currentSnapshot
    }

    public mutating func reset(to snapshot: SimulationSnapshot) {
        currentSnapshot = snapshot
    }
}

private enum FourierTransform {
    static func complexForward(_ input: [ComplexValue]) -> [ComplexValue] {
        transform(input, direction: vDSP_DFT_Direction(rawValue: 1)!, normalize: false)
    }

    static func complexInverse(_ input: [ComplexValue]) -> [ComplexValue] {
        transform(input, direction: vDSP_DFT_Direction(rawValue: -1)!, normalize: true)
    }

    private static func transform(
        _ input: [ComplexValue],
        direction: vDSP_DFT_Direction,
        normalize: Bool
    ) -> [ComplexValue] {
        let count = input.count
        guard count > 0 else {
            return []
        }

        var realIn = input.map(\.real)
        var imaginaryIn = input.map(\.imaginary)
        var realOut = Array(repeating: 0.0, count: count)
        var imaginaryOut = Array(repeating: 0.0, count: count)

        guard let setup = vDSP_DFT_zop_CreateSetupD(nil, vDSP_Length(count), direction) else {
            return input
        }

        vDSP_DFT_ExecuteD(setup, &realIn, &imaginaryIn, &realOut, &imaginaryOut)
        vDSP_DFT_DestroySetupD(setup)

        let scale = normalize ? 1 / Double(count) : 1
        return zip(realOut, imaginaryOut).map { real, imaginary in
            ComplexValue(real: real * scale, imaginary: imaginary * scale)
        }
    }
}
