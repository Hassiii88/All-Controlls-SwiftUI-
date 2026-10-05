import Foundation

struct Student: Identifiable, Hashable {
    let id: Int64
    var name: String
    var monthlyFee: Double
    var isActive: Bool
}
