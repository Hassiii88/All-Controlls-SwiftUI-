import SwiftUI

struct EditStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @State var student: Student
    var onSave: (Student) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Student")) {
                    TextField("Name", text: $student.name)
                    TextField("Monthly Fee", value: $student.monthlyFee, format: .number)
                        .keyboardType(.decimalPad)
                    Toggle("Active", isOn: $student.isActive)
                }
            }
            .navigationTitle("Edit Student")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(student)
                        dismiss()
                    }
                }
            }
        }
    }
}
