import QuantumMechanicsLabCore
import SwiftUI

struct PotentialCanvas1D: View {
    var potential: PotentialBuffer

    var body: some View {
        Canvas { context, size in
            guard potential.values.count > 1 else {
                return
            }

            let minValue = potential.values.min() ?? 0
            let maxValue = potential.values.max() ?? 1
            let scale = max(maxValue - minValue, .ulpOfOne)
            var path = Path()

            for index in potential.values.indices {
                let x = CGFloat(index) / CGFloat(max(potential.values.count - 1, 1)) * size.width
                let y = size.height - CGFloat((potential.values[index] - minValue) / scale) * size.height
                if index == potential.values.startIndex {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(.orange.opacity(0.3)), lineWidth: 6)
            context.stroke(path, with: .color(.orange), lineWidth: 2)
        }
    }
}
