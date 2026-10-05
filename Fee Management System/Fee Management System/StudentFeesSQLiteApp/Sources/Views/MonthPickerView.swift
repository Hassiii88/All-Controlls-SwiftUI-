import SwiftUI

struct MonthPickerView: View {
    @Binding var year: Int
    @Binding var month: Int
    
    private let years: [Int] = {
        let y = Calendar.current.component(.year, from: Date())
        return Array((y-5)...(y+5))
    }()
    private let months = Array(1...12)
    
    var body: some View {
        HStack {
            Picker("Year", selection: $year) {
                ForEach(years, id: \.\self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .pickerStyle(.menu)
            Picker("Month", selection: $month) {
                ForEach(months, id: \.\self) { m in
                    Text(DateFormatter().monthSymbols[m-1]).tag(m)
                }
            }
            .pickerStyle(.menu)
            Spacer()
        }
    }
}
