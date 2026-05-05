import QuantumMechanicsLabCore
import SwiftUI

struct WavefunctionCanvas1D: View {
    @Environment(AppModel.self) private var appModel
    var snapshot: SimulationSnapshot

    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                drawBackground(in: context, size: size)
                drawPotential(in: context, size: size)
                drawDensity(in: context, size: size)
                drawPhaseTrace(in: context, size: size)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            if snapshot.experimentID == "custom-potential" {
                                appModel.prepareForPotentialStroke()
                            }
                        }

                        let size = proxy.size
                        guard size.width > 0, size.height > 0 else { return }
                        let hPos = value.location.x / size.width
                        let vPos = value.location.y / size.height

                        if snapshot.experimentID == "custom-potential" {
                            appModel.paintCustomPotential(horizontalPosition: hPos, verticalPosition: vPos)
                        } else {
                            if !appModel.isPlaying {
                                appModel.moveWavepacket(horizontalPosition: hPos, verticalPosition: vPos)
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        // Treat a short drag without much movement as a tap if playing
                        let size = proxy.size
                        guard size.width > 0, size.height > 0 else { return }
                        let distance = hypot(value.translation.width, value.translation.height)
                        if appModel.isPlaying && distance < 10 {
                            let hPos = value.location.x / size.width
                            let vPos = value.location.y / size.height
                            appModel.collapseWavefunction(horizontalPosition: hPos, verticalPosition: vPos)
                        }
                    }
            )
        }
        .accessibilityLabel("One dimensional wavefunction viewport")
    }

    private func drawBackground(in context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.04),
                    Color(red: 0.04, green: 0.07, blue: 0.08),
                    Color(red: 0.02, green: 0.025, blue: 0.035)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )

        let midY = size.height * 0.58
        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: midY))
        axis.addLine(to: CGPoint(x: size.width, y: midY))
        context.stroke(axis, with: .color(.white.opacity(0.16)), lineWidth: 1)

        for fraction in stride(from: 0.1, through: 0.9, by: 0.1) {
            let x = size.width * fraction
            var line = Path()
            line.move(to: CGPoint(x: x, y: 0))
            line.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(line, with: .color(.white.opacity(0.035)), lineWidth: 1)
        }
    }

    private func drawDensity(in context: GraphicsContext, size: CGSize) {
        guard case let .oneD(grid) = snapshot.grid else {
            return
        }

        let density = snapshot.psi.probabilityDensity()
        guard density.count == grid.pointCount, let maxDensity = density.max(), maxDensity > 0 else {
            return
        }

        var path = Path()
        var fillPath = Path()
        let baseline = size.height * 0.58

        fillPath.move(to: CGPoint(x: 0, y: baseline))
        for index in density.indices {
            let x = CGFloat(index) / CGFloat(max(density.count - 1, 1)) * size.width
            let y = baseline - CGFloat(density[index] / maxDensity) * size.height * 0.46
            if index == density.startIndex {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            fillPath.addLine(to: CGPoint(x: x, y: y))
        }
        fillPath.addLine(to: CGPoint(x: size.width, y: baseline))
        fillPath.closeSubpath()

        context.fill(fillPath, with: .color(.cyan.opacity(0.18)))
        context.stroke(path, with: .color(.cyan.opacity(0.88)), lineWidth: 2.4)
    }

    private func drawPotential(in context: GraphicsContext, size: CGSize) {
        guard let potential = snapshot.potential, potential.values.count > 1 else {
            return
        }

        let minValue = potential.values.min() ?? 0
        let maxValue = potential.values.max() ?? 1
        let scale = max(maxValue - minValue, .ulpOfOne)

        var path = Path()
        var fillPath = Path()
        fillPath.move(to: CGPoint(x: 0, y: size.height))
        for index in potential.values.indices {
            let x = CGFloat(index) / CGFloat(max(potential.values.count - 1, 1)) * size.width
            let normalized = (potential.values[index] - minValue) / scale
            let y = size.height - CGFloat(normalized) * size.height * 0.34 - size.height * 0.08
            if index == potential.values.startIndex {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            fillPath.addLine(to: CGPoint(x: x, y: y))
        }
        fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
        fillPath.closeSubpath()

        context.fill(fillPath, with: .color(.orange.opacity(0.10)))
        context.stroke(path, with: .color(.orange.opacity(0.82)), lineWidth: 1.8)
    }

    private func drawPhaseTrace(in context: GraphicsContext, size: CGSize) {
        guard case let .oneD(grid) = snapshot.grid else {
            return
        }

        let density = snapshot.psi.probabilityDensity()
        guard density.count == grid.pointCount, let maxDensity = density.max(), maxDensity > 0 else {
            return
        }

        let centerY = size.height * 0.78
        let amplitude = size.height * 0.11
        let step = max(1, density.count / 420)
        var previousPoint: CGPoint?
        var previousPhase = 0.0

        for index in stride(from: 0, to: density.count, by: step) {
            let sample = snapshot.psi[index]
            let normalizedDensity = min(density[index] / maxDensity, 1)
            let phase = atan2(sample.imaginary, sample.real)
            let x = CGFloat(index) / CGFloat(max(density.count - 1, 1)) * size.width
            let y = centerY - CGFloat(sample.real) * CGFloat(sqrt(normalizedDensity)) * amplitude
            let point = CGPoint(x: x, y: y)

            if let previousPoint {
                var segment = Path()
                segment.move(to: previousPoint)
                segment.addLine(to: point)
                let baseColor = PhaseColorMap.color(for: previousPhase, density: 0.95)
                context.stroke(segment, with: .color(baseColor.opacity(0.3)), lineWidth: 4)
                context.stroke(segment, with: .color(baseColor.opacity(0.86)), lineWidth: 1.5)
            }

            previousPoint = point
            previousPhase = phase
        }
    }

    private func customPotentialDragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard snapshot.experimentID == "custom-potential",
                      size.width > 0,
                      size.height > 0
                else {
                    return
                }

                appModel.paintCustomPotential(
                    horizontalPosition: value.location.x / size.width,
                    verticalPosition: value.location.y / size.height
                )
            }
    }
}
