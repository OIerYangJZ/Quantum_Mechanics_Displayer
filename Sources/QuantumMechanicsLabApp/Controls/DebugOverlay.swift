import QuantumMechanicsLabCore
import SwiftUI

struct DebugOverlay: View {
    var snapshot: SimulationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .foregroundStyle(.cyan)
                Text("HUD / SYSTEM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)
                    .tracking(1.5)
            }
            .padding(.bottom, 2)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("NORM")
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.diagnostics.norm, format: .number.precision(.fractionLength(6)))")
                        .foregroundStyle(.white)
                }
                GridRow {
                    Text("STEPS")
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.diagnostics.stepCount)")
                        .foregroundStyle(.white)
                }
                if let energy = snapshot.diagnostics.energy {
                    GridRow {
                        Text("ENERGY")
                            .foregroundStyle(.secondary)
                        Text("\(energy, format: .number.precision(.fractionLength(6)))")
                            .foregroundStyle(.white)
                    }
                }
                if let energyDrift = snapshot.diagnostics.energyDrift {
                    GridRow {
                        Text("dE")
                            .foregroundStyle(.secondary)
                        Text("\(energyDrift, format: .number.precision(.fractionLength(6)))")
                            .foregroundStyle(.white)
                    }
                }
            }
            .font(.caption2.monospaced())

            if let warning = snapshot.diagnostics.warning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(LocalizedStringKey(warning.rawValue))
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange)
                .clipShape(Capsule())
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [.cyan.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
