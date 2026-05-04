import Foundation

public enum NumericalWarning: String, Codable, Sendable {
    case normDrift
    case energyDrift
    case unstableParameters
    case boundarySeamRisk
}

public struct NumericalDiagnostics: Codable, Sendable, Equatable {
    public var norm: Double
    public var energy: Double?
    public var energyDrift: Double?
    public var maxProbabilityDensity: Double
    public var stepCount: Int
    public var warning: NumericalWarning?

    public init(
        norm: Double,
        energy: Double? = nil,
        energyDrift: Double? = nil,
        maxProbabilityDensity: Double,
        stepCount: Int,
        warning: NumericalWarning? = nil
    ) {
        self.norm = norm
        self.energy = energy
        self.energyDrift = energyDrift
        self.maxProbabilityDensity = maxProbabilityDensity
        self.stepCount = stepCount
        self.warning = warning
    }
}

public struct SimulationSnapshot: Codable, Sendable, Equatable {
    public var experimentID: String
    public var time: Double
    public var grid: GridDescriptor
    public var psi: ComplexBuffer
    public var potential: PotentialBuffer?
    public var observables: Observables
    public var diagnostics: NumericalDiagnostics

    public init(
        experimentID: String,
        time: Double,
        grid: GridDescriptor,
        psi: ComplexBuffer,
        potential: PotentialBuffer? = nil,
        observables: Observables,
        diagnostics: NumericalDiagnostics
    ) {
        self.experimentID = experimentID
        self.time = time
        self.grid = grid
        self.psi = psi
        self.potential = potential
        self.observables = observables
        self.diagnostics = diagnostics
    }

    public func advanced(by deltaTime: Double, stepCount: Int = 1) -> SimulationSnapshot {
        var copy = self
        copy.time += deltaTime
        copy.diagnostics.stepCount += stepCount
        return copy
    }
}
