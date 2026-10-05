import Foundation
import Combine

final class AppViewModel: ObservableObject {
    @Published var year: Int
    @Published var month: Int
    @Published var students: [StudentPayment] = []
    @Published var revenue: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let cal = Calendar.current
        let now = Date()
        self.year = cal.component(.year, from: now)
        self.month = cal.component(.month, from: now)
        
        // When month/year changes, reload
        $year.combineLatest($month).sink { [weak self] _, _ in
            self?.reload()
        }.store(in: &cancellables)
    }
    
    func setup() {
        Database.shared.open()
        reload()
    }
    
    func reload() {
        students = Database.shared.fetchStudentPayments(year: year, month: month)
        revenue = Database.shared.monthRevenue(year: year, month: month)
    }
    
    func addStudent(name: String, fee: Double) {
        Database.shared.addStudent(name: name, monthlyFee: fee)
        reload()
    }
    
    func removeStudent(id: Int64) {
        Database.shared.removeStudent(id: id)
        reload()
    }
    
    func updateStudent(_ s: Student) {
        Database.shared.updateStudent(id: s.id, name: s.name, monthlyFee: s.monthlyFee, isActive: s.isActive)
        reload()
    }
    
    func setPaid(studentId: Int64, paid: Bool, amount: Double?) {
        Database.shared.setPaid(studentId: studentId, year: year, month: month, paid: paid, amountPaid: amount)
        reload()
    }
}
