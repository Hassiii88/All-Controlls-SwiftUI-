import SwiftUI

struct AddStudentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var fee: String = ""
    
    var onSave: (String, Double) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Student")) {
                    TextField("Name", text: $name)
                    TextField("Monthly Fee", text: $fee)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Student")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let f = Double(fee), !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(name, f)
                        dismiss()
                    }
                    .disabled(Double(fee) == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
