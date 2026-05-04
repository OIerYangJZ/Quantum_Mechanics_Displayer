import SwiftUI

struct TimelineControls: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                appModel.togglePlayback()
            } label: {
                Label(appModel.isPlaying ? "Pause" : "Play", systemImage: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(appModel.isPlaying ? .orange : .cyan)
            .clipShape(Capsule())

            Button {
                appModel.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .padding(10)
            .background(.white.opacity(0.1))
            .clipShape(Circle())

            Divider()
                .frame(height: 24)

            HStack(spacing: 8) {
                Image(systemName: "hare.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Slider(value: Bindable(appModel).playbackSpeed, in: 0.25...4) {
                    Text("Speed")
                }
                .frame(maxWidth: 160)
                .tint(.cyan)
            }

            Divider()
                .frame(height: 24)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundStyle(.cyan)
                Text(appModel.snapshot.time, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .fontWeight(.medium)
                    .frame(minWidth: 50, alignment: .leading)
            }
        }
    }
}
