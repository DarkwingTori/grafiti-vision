import Foundation

/// Shared application state. Grows as later phases add AR/Vision/gallery features.
final class AppState: ObservableObject {
    enum Mode: Equatable {
        case spray
        case vision
    }

    @Published var mode: Mode = .spray
}
