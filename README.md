# Swift App Template

A starter template for iOS development students to build and run a Swift-backed web app — entirely in **GitHub Codespaces**, no Xcode or macOS required.

The included demo is a simple **Task List** app: a web server written in Swift that persists data with SQLite and renders an interactive UI in the browser.

---

## 1. Using This Template

1. Click the **"Use this template"** button at the top of this repository.
2. Give your new repository a name and click **"Create repository"**.

> Do **not** clone this repo directly — always start from your own copy created via the template.

---

## 2. Opening in GitHub Codespaces

1. In **your new repository**, click the green **"Code"** button.
2. Select the **"Codespaces"** tab and click **"Create codespace on main"**.
3. Wait for the container to build — this pulls the Swift 6.2 Docker image and runs `swift package resolve` automatically. This takes a few minutes the first time.

Once the container is ready, VS Code opens in the browser with Swift fully configured.

---

## 3. Build & Run

Open the integrated terminal and run:

```bash
./build.sh
```

This resolves dependencies and compiles the project. When it finishes, start the server:

```bash
./run.sh
```

Codespaces will detect that port **8080** is now in use and show a pop-up — click **"Open in Browser"** (or find it under the **Ports** tab). You should see the Task List app running live.

> To stop the server press `Ctrl + C` in the terminal.

---

## 4. Project Structure

```
.devcontainer/
  devcontainer.json     # Codespaces container config (Swift 6.2, VS Code extensions, port forwarding)
Sources/App/
  main.swift            # Entry point — server setup and HTTP route definitions
  Models.swift          # Data model: the TaskItem struct
  Database.swift        # SQLite setup and all database queries
  Views.swift           # HTML page rendering (returns pages to the browser)
Package.swift           # Swift package definition — dependencies and build targets
build.sh                # Helper script: resolve + compile
run.sh                  # Helper script: start the server
```

---

## 5. How It Works

```
Browser  →  HTTP Request
             ↓
         main.swift  (Hummingbird router matches the route)
             ↓
         Database.swift  (SQLite.swift reads/writes db.sqlite3)
             ↓
         Views.swift  (builds an HTML string from the data)
             ↓
         HTTP Response  →  Browser renders the page
```

| Layer | File | Technology |
|---|---|---|
| Web server & routing | `main.swift` | [Hummingbird 2](https://github.com/hummingbird-project/hummingbird) |
| Data model | `Models.swift` | Swift `struct` |
| Database | `Database.swift` | [SQLite.swift](https://github.com/stephencelis/SQLite.swift) |
| UI / HTML | `Views.swift` | [Pico CSS](https://picocss.com) |

---

## 6. Your Assignment

Your job is to extend this template into your own app. Here are the four files you will work in and what to change:

### `Models.swift` — Define your data
Replace or extend `TaskItem` with a struct that represents the data your app works with.
```swift
struct TaskItem: Codable, Sendable {
    let id: Int64?
    var title: String
    var isCompleted: Bool
    // Add your own fields here, e.g.:
    // var dueDate: String
    // var priority: Int
}
```

### `Database.swift` — Read and write data
Update the SQLite table columns to match your model, and add functions for any new queries your app needs (e.g. filtering, deleting, updating fields).

### `Views.swift` — Change the UI
Modify `renderIndex(items:)` to display your data the way you want. You can add new `render...()` functions for additional pages.

### `main.swift` — Add routes
Register new routes to handle new pages or actions. Follow the existing pattern:
```swift
router.get("/my-page") { _, _ -> HTML in
    // fetch data, return a View
}

router.post("/my-action") { request, context -> Response in
    // handle form submission
}
```

---

## 7. Key Swift Concepts in This Project

| Concept | Where to see it |
|---|---|
| `struct` | `Models.swift`, `Database.swift`, `Views.swift` |
| `async/await` | `main.swift` — `app.runService()`, request handlers |
| Closures | `main.swift` — route handler blocks `{ request, context in ... }` |
| Protocol conformance | `Views.swift` — `HTML: ResponseGenerator` |
| `throws` / `try` | `Database.swift` — all database calls |
| Extensions | `Database.swift` — `Connection: @unchecked Sendable` |

---

## 8. Troubleshooting

**Port 8080 is already in use**
Another process is using the port. In the terminal run:
```bash
lsof -i :8080
kill <PID>
```
Then start the server again with `./run.sh`.

**`error: 'App' product not found` or build errors on first open**
The package dependencies may not have resolved yet. Run:
```bash
swift package resolve
./build.sh
```

**Codespace is slow to start**
The first build after creating a Codespace downloads the Swift Docker image (~1 GB). Subsequent starts are much faster because the image is cached.

**Changes not showing in the browser**
The server must be restarted to pick up code changes. Press `Ctrl + C`, run `./build.sh`, then `./run.sh` again.
