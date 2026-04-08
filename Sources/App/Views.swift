import Hummingbird
import Foundation

struct Views {
    static func renderIndex(items: [TaskItem]) -> HTML {
        let rows = items.map { item in
            """
            <article style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                <span style="text-decoration: \(item.isCompleted ? "line-through" : "none")">
                    \(item.isCompleted ? "✅" : "⭕️") \(item.title)
                </span>
                <form action="/toggle/\(item.id ?? 0)" method="post" style="margin: 0;">
                    <button type="submit" class="outline secondary" style="padding: 4px 8px; font-size: 0.8rem;">
                        \(item.isCompleted ? "Undo" : "Complete")
                    </button>
                </form>
            </article>
            """
        }.joined()

        return HTML(content: """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
            <title>Swift Task App</title>
        </head>
        <body class="container" style="padding-top: 2rem; max-width: 600px;">
            <header>
                <h1>Swift Task List</h1>
                <p>A lightweight TO-DO List app built with Swift, Hummingbird, and SQLite.</p>
            </header>
            
            <main>
                <form action="/add" method="post" style="display: flex; gap: 10px;">
                    <input type="text" name="title" placeholder="New task..." required style="flex-grow: 1;">
                    <button type="submit">Add</button>
                </form>
                
                <section>
                    \(items.isEmpty ? "<p>No tasks yet! Add one above.</p>" : rows)
                </section>
            </main>
        </body>
        </html>
        """)
    }
}

// Allows Hummingbird to return HTML strings
struct HTML: ResponseGenerator {
    let content: String
    func response(from request: Request, context: some RequestContext) throws -> Response {
        return Response(
            status: .ok,
            headers: [.contentType: "text/html"],
            body: .init(byteBuffer: .init(string: content))
        )
    }
}