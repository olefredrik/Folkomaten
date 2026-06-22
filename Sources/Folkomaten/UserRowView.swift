import SwiftUI
import FolkomatenKit

/// Én rad i listen: favoritt-stjerne, navn, fødselsnummer, fødselsdato og kopier-knapp.
/// Klikk hvor som helst på raden kopierer fødselsnummeret.
struct UserRowView: View {
    @EnvironmentObject private var store: TestUserStore
    let user: TestUser
    let isCopied: Bool
    let copy: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.toggleFavorite(user)
            } label: {
                Image(systemName: store.isFavorite(user) ? "star.fill" : "star")
                    .foregroundStyle(store.isFavorite(user) ? Color.yellow : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(store.isFavorite(user) ? "Fjern favoritt" : "Legg til favoritt")

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .fontWeight(.semibold)
                HStack(spacing: 6) {
                    Text(user.fnr)
                        .font(.system(.callout, design: .monospaced))
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(user.birthDateFormatted)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(action: copy) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundStyle(isCopied ? Color.green : Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Kopier fødselsnummer")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(hovering ? Color.primary.opacity(0.06) : Color.clear)
        .onHover { hovering = $0 }
        .onTapGesture(perform: copy)
    }
}
