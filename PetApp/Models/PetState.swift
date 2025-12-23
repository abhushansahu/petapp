import Foundation

enum PetState: String, CaseIterable {
    case idle
    case walking
    case running
    case eating
    case playing
    case dragging
    case dropped
    case dancing
    case watching
    case sitting
    case sleeping
    
    var displayName: String {
        return rawValue.capitalized
    }
}
