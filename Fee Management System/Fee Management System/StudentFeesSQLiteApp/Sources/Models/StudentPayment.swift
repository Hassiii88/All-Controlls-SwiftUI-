import Foundation

struct StudentPayment: Identifiable, Hashable {
    var id: Int64 { student.id }
    let student: Student
    var isPaid: Bool
    var amountPaid: Double
}
