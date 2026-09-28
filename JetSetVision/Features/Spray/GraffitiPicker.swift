import SwiftUI

/// Horizontal strip for choosing which graffiti design to spray next.
struct GraffitiPicker: View {
    @ObservedObject var controller: GraffitiPlacementController

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GraffitiAsset.library) { asset in
                    Button {
                        controller.selectedAsset = asset
                    } label: {
                        Image(asset.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .padding(6)
                            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(controller.selectedAsset.id == asset.id ? Color.white : .clear, lineWidth: 3)
                            )
                    }
                    .accessibilityLabel(asset.name)
                    .accessibilityAddTraits(controller.selectedAsset.id == asset.id ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
