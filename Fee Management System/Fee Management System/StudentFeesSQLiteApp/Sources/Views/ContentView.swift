import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showAdd = false
    @State private var editStudent: Student? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                MonthPickerView(year: $vm.year, month: $vm.month)
                    .padding(.horizontal)
                
                HStack {
                    Text("Revenue: ")
                    Spacer()
                    Text(vm.revenue, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                List {
                    ForEach(vm.students) { item in
                        StudentRow(item: item,
                                   onTogglePaid: { paid in
                            let amount = paid ? item.student.monthlyFee : 0
                            vm.setPaid(studentId: item.student.id, paid: paid, amount: amount)
                        }, onAmountChange: { newAmount in
                            vm.setPaid(studentId: item.student.id, paid: true, amount: newAmount)
                        }, onEdit: {
                            editStudent = item.student
                        })
                    }
                    .onDelete { idx in
                        for i in idx {
                            let id = vm.students[i].student.id
                            vm.removeStudent(id: id)
                        }
                    }
                }
            }
            .navigationTitle("Student Fees")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddStudentView { name, fee in
                    vm.addStudent(name: name, fee: fee)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $editStudent) { st in
                EditStudentView(student: st) { updated in
                    vm.updateStudent(updated)
                }
            }
        }
    }
}

struct StudentRow: View {
    let item: StudentPayment
    var onTogglePaid: (Bool) -> Void
    var onAmountChange: (Double) -> Void
    var onEdit: () -> Void
    
    @State private var localPaid: Bool
    @State private var localAmount: String
    
    init(item: StudentPayment,
         onTogglePaid: @escaping (Bool) -> Void,
         onAmountChange: @escaping (Double) -> Void,
         onEdit: @escaping () -> Void) {
        self.item = item
        self.onTogglePaid = onTogglePaid
        self.onAmountChange = onAmountChange
        self.onEdit = onEdit
        _localPaid = State(initialValue: item.isPaid)
        _localAmount = State(initialValue: String(format: "%.0f", item.amountPaid > 0 ? item.amountPaid : item.student.monthlyFee))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.student.name)
                        .font(.headline)
                    Text("Fee: \(item.student.monthlyFee, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                Toggle("Paid", isOn: Binding(get: { localPaid }, set: { v in
                    localPaid = v
                    onTogglePaid(v)
                }))
                .toggleStyle(.checkbox)
                
                TextField("Amount", text: Binding(get: { localAmount }, set: { v in
                    localAmount = v
                }))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .disabled(!localPaid)
                Button("Update") {
                    if let amt = Double(localAmount) {
                        onAmountChange(amt)
                    }
                }
                .disabled(!localPaid)
            }
        }
        .padding(.vertical, 6)
    }
}
