import Foundation

public struct Observables: Codable, Sendable, Equatable {
    public var norm: Double
    public var expectedX: Double?
    public var expectedP: Double?
    public var deltaX: Double?
    public var deltaP: Double?
    public var uncertaintyProduct: Double?
    public var totalEnergy: Double?

    public init(
        norm: Double,
        expectedX: Double? = nil,
        expectedP: Double? = nil,
        deltaX: Double? = nil,
        deltaP: Double? = nil,
        uncertaintyProduct: Double? = nil,
        totalEnergy: Double? = nil
    ) {
        self.norm = norm
        self.expectedX = expectedX
        self.expectedP = expectedP
        self.deltaX = deltaX
        self.deltaP = deltaP
        self.uncertaintyProduct = uncertaintyProduct
        self.totalEnergy = totalEnergy
    }
}

public enum ObservablesCalculator {
    public static func oneD(
        psi: ComplexBuffer,
        grid: Grid1D,
        potential: PotentialBuffer? = nil,
        mass: Double = SimulationUnits.defaultMass
    ) -> Observables {
        let density = psi.probabilityDensity()
        let dx = grid.spacing
        let norm = density.reduce(0, +) * dx
        let xValues = grid.xValues
        let expectedX = zip(xValues, density).reduce(0) { partial, sample in
            partial + sample.0 * sample.1 * dx
        } / max(norm, .ulpOfOne)

        let varianceX = zip(xValues, density).reduce(0) { partial, sample in
            let offset = sample.0 - expectedX
            return partial + offset * offset * sample.1 * dx
        } / max(norm, .ulpOfOne)

        let potentialEnergy = potential.map { buffer in
            zip(buffer.values, density).reduce(0) { partial, sample in
                partial + sample.0 * sample.1 * dx
            } / max(norm, .ulpOfOne)
        }

        let derivativeSamples = spatialDerivativeSamples(psi: psi, dx: dx)
        let expectedP = derivativeSamples.reduce(0) { partial, sample in
            let value = psi[sample.index]
            return partial + (value.real * sample.derivativeImaginary - value.imaginary * sample.derivativeReal) * dx
        } / max(norm, .ulpOfOne)

        let kineticEnergy = derivativeSamples.reduce(0) { partial, sample in
            let gradientMagnitudeSquared = sample.derivativeReal * sample.derivativeReal + sample.derivativeImaginary * sample.derivativeImaginary
            return partial + gradientMagnitudeSquared * dx / (2 * mass)
        } / max(norm, .ulpOfOne)

        return Observables(
            norm: norm,
            expectedX: expectedX,
            expectedP: expectedP,
            deltaX: sqrt(max(varianceX, 0)),
            totalEnergy: kineticEnergy + (potentialEnergy ?? 0)
        )
    }

    public static func twoD(
        psi: ComplexBuffer,
        grid: Grid2D,
        potential: PotentialBuffer? = nil,
        mass: Double = SimulationUnits.defaultMass
    ) -> Observables {
        let density = psi.probabilityDensity()
        let area = grid.spacingX * grid.spacingY
        guard density.count == grid.pointCount else {
            return Observables(norm: 0)
        }

        let norm = density.reduce(0, +) * area
        let safeNorm = max(norm, .ulpOfOne)

        var expectedX = 0.0
        var expectedXSquared = 0.0
        for row in 0..<grid.height {
            for column in 0..<grid.width {
                let x = grid.xValue(at: column)
                let probability = density[grid.linearIndex(column: column, row: row)] * area
                expectedX += x * probability
                expectedXSquared += x * x * probability
            }
        }
        expectedX /= safeNorm
        expectedXSquared /= safeNorm

        let potentialEnergy = potential.flatMap { buffer -> Double? in
            guard buffer.values.count == density.count else {
                return nil
            }
            return zip(buffer.values, density).reduce(0) { partial, sample in
                partial + sample.0 * sample.1 * area
            } / safeNorm
        }

        var gradientEnergy = 0.0
        if grid.width >= 3, grid.height >= 3 {
            for row in 1..<(grid.height - 1) {
                for column in 1..<(grid.width - 1) {
                    let left = psi[grid.linearIndex(column: column - 1, row: row)]
                    let right = psi[grid.linearIndex(column: column + 1, row: row)]
                    let down = psi[grid.linearIndex(column: column, row: row - 1)]
                    let up = psi[grid.linearIndex(column: column, row: row + 1)]
                    let derivativeX = (right - left) * (0.5 / grid.spacingX)
                    let derivativeY = (up - down) * (0.5 / grid.spacingY)
                    gradientEnergy += (
                        derivativeX.magnitudeSquared + derivativeY.magnitudeSquared
                    ) * area / (2 * mass)
                }
            }
        }

        return Observables(
            norm: norm,
            expectedX: expectedX,
            deltaX: sqrt(max(expectedXSquared - expectedX * expectedX, 0)),
            totalEnergy: gradientEnergy / safeNorm + (potentialEnergy ?? 0)
        )
    }

    private static func spatialDerivativeSamples(
        psi: ComplexBuffer,
        dx: Double
    ) -> [(index: Int, derivativeReal: Double, derivativeImaginary: Double)] {
        guard psi.count >= 3 else {
            return []
        }

        return (1..<(psi.count - 1)).map { index in
            let left = psi[index - 1]
            let right = psi[index + 1]
            return (
                index: index,
                derivativeReal: (right.real - left.real) / (2 * dx),
                derivativeImaginary: (right.imaginary - left.imaginary) / (2 * dx)
            )
        }
    }
}
