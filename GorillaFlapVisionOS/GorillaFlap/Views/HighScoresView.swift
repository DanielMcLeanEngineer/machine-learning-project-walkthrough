import SwiftUI

/// Compact local top-5 table for the menu.
struct HighScoresView: View {
    @ObservedObject var store = HighScores.shared

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Local Top 5", systemImage: "chart.bar.fill")
                .font(.headline)

            if store.entries.isEmpty {
                Text("No runs yet — swing to set the first score.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                    HStack {
                        Text("\(index + 1).")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(index == 0 ? .yellow : .secondary)
                            .frame(width: 24, alignment: .leading)
                        Text("\(entry.score)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                        Spacer()
                        Text(Self.dateFormatter.localizedString(for: entry.date, relativeTo: Date()))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
