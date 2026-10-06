import SwiftUI

/// Minimal app-wide settings — currently just "Clear All Placements," but
/// deliberately its own screen (not bolted onto `GraffitiLibraryView`,
/// which manages the asset *library*, not AR scene state) so future
/// settings have a natural home.
struct SettingsView: View {
    let placementController: GraffitiPlacementController
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false
    @State private var didClear = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("CLEAR ALL PLACEMENTS", systemImage: "trash")
                    }
                } footer: {
                    Text("Removes every piece of graffiti you've placed, in this session and any saved from before. This can't be undone.")
                }

                if didClear {
                    Section {
                        SuccessBanner(message: "CLEARED")
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.black.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                }
            }
            .alert("CLEAR ALL PLACEMENTS?", isPresented: $showClearConfirmation) {
                Button("CANCEL", role: .cancel) {}
                Button("CLEAR", role: .destructive) {
                    placementController.clearAllPlacements()
                    WorldMapStore.clear()
                    withAnimation { didClear = true }
                }
            } message: {
                Text("This removes every placed graffiti piece and can't be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }
}
