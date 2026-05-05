import Foundation

public struct HydrogenOrbitalExperiment: Experiment {
    public let id = "hydrogen-orbitals"
    public let title = "Hydrogen Orbitals"
    public let category = ExperimentCategory.orbitals
    public let summary = "Analytic hydrogen orbital density and phase for selected quantum numbers."






    public var explanation: String {
        """
        Hydrogen orbitals are the exact 3D stationary states of an electron bound to a proton by Coulomb attraction. They are defined by three quantum numbers: principal (n) for energy/size, azimuthal (l) for orbital angular momentum (s, p, d, f shapes), and magnetic (m) for spatial orientation. This visualization shows a 2D slice through the center of the atom. Notice the radial nodes (rings of zero probability) and angular nodes (lines of zero probability) as n and l increase.
        """
    }
    public var builtInPresets: [ExperimentPreset] {
        [
            ExperimentPreset(experimentID: "hydrogen-orbitals", name: "1s Orbital (Ground State)", parameters: [
                ExperimentParameter(id: "n", label: "Principal (n)", value: 1, range: 1...5),
                ExperimentParameter(id: "l", label: "Azimuthal (l)", value: 0, range: 0...4),
                ExperimentParameter(id: "m", label: "Magnetic (m)", value: 0, range: -4...4)
            ]),
            ExperimentPreset(experimentID: "hydrogen-orbitals", name: "2p Orbital", parameters: [
                ExperimentParameter(id: "n", label: "Principal (n)", value: 2, range: 1...5),
                ExperimentParameter(id: "l", label: "Azimuthal (l)", value: 1, range: 0...4),
                ExperimentParameter(id: "m", label: "Magnetic (m)", value: 1, range: -4...4)
            ]),
            ExperimentPreset(experimentID: "hydrogen-orbitals", name: "3d Orbital", parameters: [
                ExperimentParameter(id: "n", label: "Principal (n)", value: 3, range: 1...5),
                ExperimentParameter(id: "l", label: "Azimuthal (l)", value: 2, range: 0...4),
                ExperimentParameter(id: "m", label: "Magnetic (m)", value: 0, range: -4...4)
            ])
        ]
    }

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "n", label: "n", value: 1, range: 1...5),
            ExperimentParameter(id: "l", label: "l", value: 0, range: 0...4),
            ExperimentParameter(id: "m", label: "m", value: 0, range: -4...4)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "nodes", title: "Nodes", body: "Orbital nodes are regions where the wavefunction changes sign or vanishes."),
            StoryStep(id: "energy", title: "Energy levels", body: "In the ideal hydrogen model, energy depends only on n.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let n = max(1, Int(parameters.value(for: "n", default: 1).rounded()))
        let l = max(0, Int(parameters.value(for: "l", default: 0).rounded()))
        let m = Int(parameters.value(for: "m", default: 0).rounded())
        let energy = -0.5 / Double(n * n)
        let resolution = 72
        let psi = HydrogenOrbitalSlice.makeXYPlane(n: n, l: l, m: m, resolution: resolution)
        let density = psi.probabilityDensity()
        let observables = Observables(norm: 1, totalEnergy: energy)
        let diagnostics = NumericalDiagnostics(
            norm: 1,
            energy: energy,
            maxProbabilityDensity: density.max() ?? 0,
            stepCount: 0
        )
        return SimulationSnapshot(
            experimentID: id,
            time: 0,
            grid: .orbital(resolution: resolution),
            psi: psi,
            observables: observables,
            diagnostics: diagnostics
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        let n = Int(parameters.first { $0.id == "n" }?.value ?? 1)
        let l = Int(parameters.first { $0.id == "l" }?.value ?? 0)
        let m = Int(parameters.first { $0.id == "m" }?.value ?? 0)

        var issues: [ParameterIssue] = []
        if l < 0 || l >= n {
            issues.append(ParameterIssue(id: "l-range", message: "l must satisfy 0 <= l < n."))
        }
        if abs(m) > l {
            issues.append(ParameterIssue(id: "m-range", message: "m must satisfy -l <= m <= l."))
        }
        return issues
    }
}

private enum HydrogenOrbitalSlice {
    static func makeXYPlane(n: Int, l requestedL: Int, m requestedM: Int, resolution: Int) -> ComplexBuffer {
        let l = min(max(requestedL, 0), max(n - 1, 0))
        let m = min(max(requestedM, -l), l)
        let extent = max(8.0, Double(n * n) * 1.8)
        var values: [ComplexValue] = []
        values.reserveCapacity(resolution * resolution)

        for row in 0..<resolution {
            let y = coordinate(index: row, resolution: resolution, extent: extent)
            for column in 0..<resolution {
                let x = coordinate(index: column, resolution: resolution, extent: extent)
                values.append(orbitalValue(n: n, l: l, m: m, x: x, y: y, z: 0))
            }
        }

        return ComplexBuffer(values: values)
    }

    private static func coordinate(index: Int, resolution: Int, extent: Double) -> Double {
        (Double(index) + 0.5) / Double(resolution) * 2 * extent - extent
    }

    private static func orbitalValue(n: Int, l: Int, m: Int, x: Double, y: Double, z: Double) -> ComplexValue {
        let r = sqrt(x * x + y * y + z * z)
        let theta = r > .ulpOfOne ? acos(z / r) : 0
        let phi = atan2(y, x)
        let radial = radialPart(n: n, l: l, r: r)
        let angularMagnitude = sphericalHarmonicMagnitude(l: l, m: abs(m), theta: theta)
        let phase = Double(m) * phi
        let amplitude = radial * angularMagnitude
        return ComplexValue(real: amplitude * cos(phase), imaginary: amplitude * sin(phase))
    }

    private static func radialPart(n: Int, l: Int, r: Double) -> Double {
        let rho = 2 * r / Double(n)
        let laguerreOrder = n - l - 1
        let alpha = 2 * l + 1
        guard laguerreOrder >= 0 else {
            return 0
        }

        let normalization = sqrt(
            pow(2 / Double(n), 3)
            * factorial(laguerreOrder)
            / (2 * Double(n) * factorial(n + l))
        )
        return normalization
            * exp(-rho / 2)
            * pow(rho, Double(l))
            * associatedLaguerre(order: laguerreOrder, alpha: alpha, x: rho)
    }

    private static func sphericalHarmonicMagnitude(l: Int, m: Int, theta: Double) -> Double {
        let x = cos(theta)
        let legendre = associatedLegendre(l: l, m: m, x: x)
        let normalization = sqrt(
            (2 * Double(l) + 1)
            / (4 * .pi)
            * factorial(l - m)
            / factorial(l + m)
        )
        return normalization * legendre
    }

    private static func associatedLaguerre(order: Int, alpha: Int, x: Double) -> Double {
        (0...order).reduce(0) { partial, i in
            let sign = i.isMultiple(of: 2) ? 1.0 : -1.0
            let coefficient = binomial(order + alpha, order - i) / factorial(i)
            return partial + sign * coefficient * pow(x, Double(i))
        }
    }

    private static func associatedLegendre(l: Int, m: Int, x: Double) -> Double {
        guard m >= 0, l >= m else {
            return 0
        }

        var pmm = 1.0
        if m > 0 {
            let somx2 = sqrt(max(1 - x * x, 0))
            var factor = 1.0
            for _ in 1...m {
                pmm *= -factor * somx2
                factor += 2
            }
        }

        if l == m {
            return pmm
        }

        var pmmp1 = x * Double(2 * m + 1) * pmm
        if l == m + 1 {
            return pmmp1
        }

        var pll = 0.0
        for ll in (m + 2)...l {
            pll = (
                Double(2 * ll - 1) * x * pmmp1
                - Double(ll + m - 1) * pmm
            ) / Double(ll - m)
            pmm = pmmp1
            pmmp1 = pll
        }
        return pll
    }

    private static func factorial(_ value: Int) -> Double {
        guard value > 1 else {
            return 1
        }
        return (2...value).reduce(1.0) { $0 * Double($1) }
    }

    private static func binomial(_ n: Int, _ k: Int) -> Double {
        guard k >= 0, k <= n else {
            return 0
        }
        return factorial(n) / (factorial(k) * factorial(n - k))
    }
}
