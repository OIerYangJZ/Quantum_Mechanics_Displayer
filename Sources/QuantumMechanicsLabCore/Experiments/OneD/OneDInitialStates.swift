import Foundation

enum OneDInitialStates {
    static func gaussianWavepacket(
        on grid: Grid1D,
        center: Double,
        width: Double,
        momentum: Double
    ) -> ComplexBuffer {
        let values = grid.xValues.map { x in
            let envelope = exp(-pow(x - center, 2) / (4 * width * width))
            let phase = momentum * x
            return ComplexValue(
                real: envelope * cos(phase),
                imaginary: envelope * sin(phase)
            )
        }

        return ComplexBuffer(values: values).normalized(spacing: grid.spacing)
    }

    static func snapshot(
        experimentID: String,
        grid: Grid1D = Grid1D(),
        center: Double = -5,
        width: Double = 0.8,
        momentum: Double = 4,
        potential: PotentialBuffer? = nil,
        mass: Double = SimulationUnits.defaultMass
    ) -> SimulationSnapshot {
        let psi = gaussianWavepacket(on: grid, center: center, width: width, momentum: momentum)
        let observables = ObservablesCalculator.oneD(psi: psi, grid: grid, potential: potential, mass: mass)
        let density = psi.probabilityDensity()
        let diagnostics = NumericalDiagnostics(
            norm: observables.norm,
            energy: observables.totalEnergy,
            maxProbabilityDensity: density.max() ?? 0,
            stepCount: 0
        )

        return SimulationSnapshot(
            experimentID: experimentID,
            time: 0,
            grid: .oneD(grid),
            psi: psi,
            potential: potential,
            observables: observables,
            diagnostics: diagnostics
        )
    }
}
