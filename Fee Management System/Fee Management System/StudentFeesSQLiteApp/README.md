# StudentFeesSQLiteApp

A simple SwiftUI iOS app that uses **SQLite (SQLite3 C API, no external packages)** to manage academy students' monthly fees **locally**.

## Features
- Add / remove students
- Set each student's monthly fee
- Pick a **year & month**
- Mark fee **Paid / Unpaid** for the selected month (checkbox)
- Auto-sets `amount_paid` to the student's fee when you mark as Paid (you can override)
- Shows **total revenue** for the selected month
- All data stored **locally** in `Documents/student_fees.sqlite`

## How to Run (Xcode 15/16, iOS 16+)
1. Open Xcode → **File > New > Project…** → iOS **App** → Name it `StudentFeesSQLiteApp` → Interface: **SwiftUI**, Language: **Swift**.
2. In the new project, **delete** the default `ContentView.swift` and `StudentFeesSQLiteAppApp.swift` files (or keep and replace).
3. Drag the `Sources` folder from this repo into Xcode (check “Copy items if needed”).
4. Go to the target’s **Build Settings** → **Other Linker Flags** and add `-lsqlite3` (usually not required, but safe).
5. Build & Run on Simulator or a device.

> No external libraries required. iOS ships with SQLite3.

## Folder Structure
```
Sources/
  App.swift
  Models/
    Student.swift
    StudentPayment.swift
  Data/
    Database.swift
  ViewModels/
    AppViewModel.swift
  Views/
    ContentView.swift
    AddStudentView.swift
    EditStudentView.swift
    MonthPickerView.swift
```

## Notes
- Removing a student also deletes their payment records.
- Payments are per (year, month). Toggling Paid inserts/updates a payment row.
- `amount_paid` defaults to the student's fee when marking as Paid; you can edit it inline.

---

© 2025-09-06
