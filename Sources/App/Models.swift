import Foundation

struct TaskItem: Codable, Sendable {
    let id: Int64?
    var title: String
    var isCompleted: Bool
}