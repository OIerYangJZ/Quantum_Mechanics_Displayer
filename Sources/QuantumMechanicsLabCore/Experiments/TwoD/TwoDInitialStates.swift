import Foundation

enum TwoDInitialStates {
    static func gaussianWavepacket(
        on grid: Grid2D,
        centerX: Double,
        centerY: Double,
        width: Double,
        momentumX: Double,
        momentumY: Double = 0
    ) -> ComplexBuffer {
        var values: [ComplexValue] = []
        values.reserveCapacity(grid.pointCount)

        for row in 0..<grid.height {
            let y = grid.yValue(at: row)
            for column in 0..<grid.width {
                let x = grid.xValue(at: column)
                let distanceSquared = pow(x - centerX, 2) + pow(y - centerY, 2)
                let envelope = exp(-distanceSquared / (4 * width * width))
                let phase = momentumX * x + momentumY * y
                values.append(
                    ComplexValue(
                        real: envelope * cos(phase),
                        imaginary: envelope * sin(phase)
                    )
                )
            }
        }

        return ComplexBuffer(values: values).normalized(spacing: grid.spacingX * grid.spacingY)
    }

    static func snapshot(
        experimentID: String,
        grid: Grid2D = Grid2D(),
        centerX: Double = -6,
        centerY: Double = 0,
        width: Double = 0.9,
        momentumX: Double = 5,
        momentumY: Double = 0,
        potential: PotentialBuffer? = nil,
        mass: Double = SimulationUnits.defaultMass
    ) -> SimulationSnapshot {
        let psi = gaussianWavepacket(
            on: grid,
            centerX: centerX,
            centerY: centerY,
            width: width,
            momentumX: momentumX,
            momentumY: momentumY
        )
        let observables = ObservablesCalculator.twoD(psi: psi, grid: grid, potential: potential, mass: mass)
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
            grid: .twoD(grid),
            psi: psi,
            potential: potential,
            observables: observables,
            diagnostics: diagnostics
        )
    }
}
