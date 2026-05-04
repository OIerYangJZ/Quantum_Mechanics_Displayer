import Foundation

public enum ExperimentCatalog {
    public static let all: [AnyExperiment] = [
        AnyExperiment(InfiniteSquareWellExperiment()),
        AnyExperiment(FiniteSquareWellExperiment()),
        AnyExperiment(HarmonicOscillatorExperiment()),
        AnyExperiment(SoftCoulombExperiment()),
        AnyExperiment(QuantumBouncerExperiment()),
        AnyExperiment(MorsePotentialExperiment()),
        AnyExperiment(DoubleWellExperiment()),
        AnyExperiment(FiniteBarrierExperiment()),
        AnyExperiment(StepPotentialExperiment()),
        AnyExperiment(PeriodicPotentialExperiment()),
        AnyExperiment(FreeWavepacketExperiment()),
        AnyExperiment(CustomPotentialExperiment()),
        AnyExperiment(FreeWavepacket2DExperiment()),
        AnyExperiment(SingleSlit2DExperiment()),
        AnyExperiment(DoubleSlit2DExperiment()),
        AnyExperiment(BarrierScattering2DExperiment()),
        AnyExperiment(CentralPotential2DExperiment()),
        AnyExperiment(QuantumCorral2DExperiment()),
        AnyExperiment(HarmonicOscillator2DExperiment()),
        AnyExperiment(HydrogenOrbitalExperiment())
    ]

    public static func experiments(in category: ExperimentCategory) -> [AnyExperiment] {
        all.filter { $0.category == category }
    }

    public static func experiment(id: String) -> AnyExperiment? {
        all.first { $0.id == id }
    }
}
