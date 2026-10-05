import Foundation
import SQLite3

final class Database {
    static let shared = Database()
    private var db: OpaquePointer?
    
    private init() { }
    
    func open() {
        if db != nil { return }
        do {
            let fm = FileManager.default
            let docURL = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = docURL.appendingPathComponent("student_fees.sqlite")
            if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
                print("Failed to open DB")
            } else {
                createTables()
            }
        } catch {
            print("DB path error: \(error)")
        }
    }
    
    private func createTables() {
        let createStudents = """
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            monthly_fee REAL NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
        );
        """
        let createPayments = """
        CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            is_paid INTEGER NOT NULL DEFAULT 0,
            amount_paid REAL NOT NULL DEFAULT 0,
            paid_at TEXT,
            UNIQUE(student_id, year, month),
            FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE
        );
        """
        _ = exec(sql: createStudents)
        _ = exec(sql: createPayments)
        // Enable foreign keys
        _ = exec(sql: "PRAGMA foreign_keys = ON;")
    }
    
    private func exec(sql: String) -> Bool {
        var errmsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errmsg) != SQLITE_OK {
            if let e = errmsg { print("SQL error:", String(cString: e)) }
            return false
        }
        return true
    }
    
    // MARK: - Students
    func addStudent(name: String, monthlyFee: Double) {
        let sql = "INSERT INTO students(name, monthly_fee, is_active) VALUES(?,?,1)"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 2, monthlyFee)
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error inserting student")
            }
        }
        sqlite3_finalize(stmt)
    }
    
    func removeStudent(id: Int64) {
        let sql = "DELETE FROM students WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error deleting student")
            }
        }
        sqlite3_finalize(stmt)
        // Payments will be deleted due to ON DELETE CASCADE (if pragma active).
    }
    
    func updateStudent(id: Int64, name: String, monthlyFee: Double, isActive: Bool) {
        let sql = "UPDATE students SET name = ?, monthly_fee = ?, is_active = ? WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 2, monthlyFee)
            sqlite3_bind_int(stmt, 3, isActive ? 1 : 0)
            sqlite3_bind_int64(stmt, 4, id)
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error updating student")
            }
        }
        sqlite3_finalize(stmt)
    }
    
    func fetchStudents() -> [Student] {
        var result: [Student] = []
        let sql = "SELECT id, name, monthly_fee, is_active FROM students ORDER BY name COLLATE NOCASE"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int64(stmt, 0)
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let fee = sqlite3_column_double(stmt, 2)
                let active = sqlite3_column_int(stmt, 3) == 1
                result.append(Student(id: id, name: name, monthlyFee: fee, isActive: active))
            }
        }
        sqlite3_finalize(stmt)
        return result
    }
    
    // MARK: - Payments
    func fetchStudentPayments(year: Int, month: Int) -> [StudentPayment] {
        // Left join students with payments for given (year, month)
        let sql = """
        SELECT s.id, s.name, s.monthly_fee, s.is_active,
               IFNULL(p.is_paid, 0), IFNULL(p.amount_paid, 0)
        FROM students s
        LEFT JOIN payments p
          ON p.student_id = s.id AND p.year = ? AND p.month = ?
        WHERE s.is_active = 1
        ORDER BY s.name COLLATE NOCASE;
        """
        var stmt: OpaquePointer?
        var list: [StudentPayment] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(year))
            sqlite3_bind_int(stmt, 2, Int32(month))
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int64(stmt, 0)
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let fee = sqlite3_column_double(stmt, 2)
                let active = sqlite3_column_int(stmt, 3) == 1
                let isPaid = sqlite3_column_int(stmt, 4) == 1
                let amountPaid = sqlite3_column_double(stmt, 5)
                let student = Student(id: id, name: name, monthlyFee: fee, isActive: active)
                list.append(StudentPayment(student: student, isPaid: isPaid, amountPaid: amountPaid))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    func setPaid(studentId: Int64, year: Int, month: Int, paid: Bool, amountPaid: Double?) {
        // Upsert pattern
        let selectSQL = "SELECT id FROM payments WHERE student_id=? AND year=? AND month=?"
        var stmt: OpaquePointer?
        var paymentId: Int64 = 0
        
        if sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, studentId)
            sqlite3_bind_int(stmt, 2, Int32(year))
            sqlite3_bind_int(stmt, 3, Int32(month))
            if sqlite3_step(stmt) == SQLITE_ROW {
                paymentId = sqlite3_column_int64(stmt, 0)
            }
        }
        sqlite3_finalize(stmt)
        
        if paymentId == 0 {
            // Insert
            let sql = "INSERT INTO payments(student_id, year, month, is_paid, amount_paid, paid_at) VALUES(?,?,?,?,?,?)"
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int64(stmt, 1, studentId)
                sqlite3_bind_int(stmt, 2, Int32(year))
                sqlite3_bind_int(stmt, 3, Int32(month))
                sqlite3_bind_int(stmt, 4, paid ? 1 : 0)
                sqlite3_bind_double(stmt, 5, paid ? (amountPaid ?? 0) : 0)
                let iso = paid ? ISO8601DateFormatter().string(from: Date()) : nil
                if let iso = iso {
                    sqlite3_bind_text(stmt, 6, (iso as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 6)
                }
                if sqlite3_step(stmt) != SQLITE_DONE {
                    print("Error inserting payment")
                }
            }
            sqlite3_finalize(stmt)
        } else {
            // Update
            let sql = "UPDATE payments SET is_paid=?, amount_paid=?, paid_at=? WHERE id=?"
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, paid ? 1 : 0)
                sqlite3_bind_double(stmt, 2, paid ? (amountPaid ?? 0) : 0)
                let iso = paid ? ISO8601DateFormatter().string(from: Date()) : nil
                if let iso = iso {
                    sqlite3_bind_text(stmt, 3, (iso as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 3)
                }
                sqlite3_bind_int64(stmt, 4, paymentId)
                if sqlite3_step(stmt) != SQLITE_DONE {
                    print("Error updating payment")
                }
            }
            sqlite3_finalize(stmt)
        }
    }
    
    func monthRevenue(year: Int, month: Int) -> Double {
        let sql = "SELECT IFNULL(SUM(amount_paid),0) FROM payments WHERE year=? AND month=? AND is_paid=1"
        var stmt: OpaquePointer?
        var total: Double = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(year))
            sqlite3_bind_int(stmt, 2, Int32(month))
            if sqlite3_step(stmt) == SQLITE_ROW {
                total = sqlite3_column_double(stmt, 0)
            }
        }
        sqlite3_finalize(stmt)
        return total
    }
}
