import SQLite
import Foundation

// Connection uses an internal serial queue, so it is safe to mark Sendable.
extension Connection: @unchecked @retroactive Sendable {}

struct Database {
    // Definitions for the Table
    static let tasks = Table("tasks")
    static let id = Expression<Int64>("id")
    static let title = Expression<String>("title")
    static let isCompleted = Expression<Bool>("is_completed")

    static func setup() throws -> Connection {
        let db = try Connection("db.sqlite3")
        try db.run(tasks.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(title)
            t.column(isCompleted, defaultValue: false)
        })
        return db
    }

    static func fetchAllTasks(db: Connection) throws -> [TaskItem] {
        return try db.prepare(tasks).map { row in
            TaskItem(id: row[id], title: row[title], isCompleted: row[isCompleted])
        }
    }

    static func addTask(db: Connection, title text: String) throws {
        try db.run(tasks.insert(title <- text))
    }
    
    static func toggleTask(db: Connection, id targetId: Int64) throws {
        let task = tasks.filter(id == targetId)
        // Find current state to flip it
        if let current = try db.pluck(task) {
            try db.run(task.update(isCompleted <- !current[isCompleted]))
        }
    }
}