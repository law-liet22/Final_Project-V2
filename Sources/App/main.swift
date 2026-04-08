import Foundation
import Hummingbird
@preconcurrency import SQLite

// Setup SQLite Database
let db = try Database.setup()

// Setup Web Server (Hummingbird)
let router = Router()

// Root Page
router.get("/") { _, _ -> HTML in
    let allTasks = try Database.fetchAllTasks(db: db)
    return Views.renderIndex(items: allTasks)
}

// API: Add Task (form submits application/x-www-form-urlencoded, not JSON)
router.post("/add") { request, _ -> Response in
    let buffer = try await request.body.collect(upTo: 1024 * 16)
    let bodyString = String(buffer: buffer)
    var components = URLComponents()
    components.percentEncodedQuery = bodyString
    let title = components.queryItems?.first(where: { $0.name == "title" })?.value ?? ""
    guard !title.isEmpty else {
        return Response(status: .badRequest)
    }
    try Database.addTask(db: db, title: title)
    return Response(status: .seeOther, headers: [.location: "/"])
}

// API: Toggle Task
router.post("/toggle/:id") { _, context -> Response in
    guard let idStr = context.parameters.get("id"), let targetId = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    try Database.toggleTask(db: db, id: targetId)
    return Response(status: .seeOther, headers: [.location: "/"])
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print("🚀 Server started at http://localhost:8080")
try await app.runService()