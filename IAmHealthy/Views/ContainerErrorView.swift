import SwiftUI

/// Shown when the SwiftData ModelContainer fails to open. Replaces the
/// previous fatalError so users see actionable guidance instead of an
/// instant crash, and so the underlying error is preserved on screen and
/// in the unified log for diagnosis.
struct ContainerErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("We couldn't open your data")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("I Am Healthy! ran into a problem reading its local store. This is usually fixed by trying again. If it keeps happening, deleting and reinstalling the app will reset it (your Apple Health entries are not affected).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            ScrollView {
                Text(detailText)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(maxHeight: 160)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button("Try again", action: retry)
                    .buttonStyle(.borderedProminent)
                Button("Copy details") { UIPasteboard.general.string = detailText }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var detailText: String {
        let nsError = error as NSError
        return """
        Domain: \(nsError.domain)
        Code: \(nsError.code)
        \(nsError.localizedDescription)

        \(error)
        """
    }
}
