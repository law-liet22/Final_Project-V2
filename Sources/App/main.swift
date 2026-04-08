import Foundation
import Hummingbird
// \"@preconcurrency\" supprime certains avertissements liés à la concurrence pour ce module
@preconcurrency import SQLite

// =========================================
// Démarrage de la base de données
// =========================================

// Ouvre (ou crée) le fichier .sqlite3 et prépare les tables.
// \"try\" indique que cette opération peut échouer ; si c'est le cas, l'application s'arrête.
let db = try Database.setup()

// =========================================
// Utilitaire : lecture du corps d'un formulaire HTML
// =========================================

// Les formulaires HTML envoient les données au format "clé=valeur&clé=valeur..." (URL-encodé).
// Cette fonction lit le corps de la requête et retourne un dictionnaire [nom -> valeur].
// \"async\" signifie que la fonction peut être suspendue en attendant des données réseau.
func parseFormBody(_ request: Request) async throws -> [String: String] {
    // Lit jusqu'à 16 Ko de données depuis le corps de la requête
    let buffer = try await request.body.collect(upTo: 1024 * 16)
    // Convertit le buffer binaire en texte (chaîne de caractères)
    let bodyString = String(buffer: buffer)
    // Utilise URLComponents pour décoder les paires clé=valeur encodées en URL.
    // Dans le format application/x-www-form-urlencoded, les espaces sont envoyés comme "+".
    // URLComponents ne les convertit pas automatiquement, donc on remplace d'abord "+" par "%20",
    // qui est la notation percent-encodée standard pour un espace.
    var components = URLComponents()
    components.percentEncodedQuery = bodyString.replacingOccurrences(of: "+", with: "%20")
    // Transforme la liste de QueryItem en dictionnaire [String: String]
    // "?? [:]" retourne un dictionnaire vide si queryItems est nil
    return Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            // "compactMap" ignore les entrées sans valeur
            guard let value = item.value else { return nil }
            return (item.name, value)
        }
    )
}

// =========================================
// Configuration du routeur HTTP (Hummingbird)
// =========================================

// "Router()" crée le routeur qui associe des URL à des fonctions Swift.
// Chaque appel ".get" ou ".post" définit une route (URL + méthode HTTP).
let router = Router()

// =========================================
// Route : Page d'accueil (GET /)
// =========================================

// Quand le navigateur demande "/", affiche la liste de tous les entrepôts.
// "_, _" signifie qu'on n'utilise ni la requête ni le contexte dans cette route.
router.get("/") { _, _ -> HTML in
    let allWarehouses = try Database.fetchAllWarehouses(db: db)  // Lit tous les entrepôts
    return Views.renderIndex(warehouses: allWarehouses)  // Génère la page HTML
}

// =========================================
// Routes : Entrepôts (Warehouses)
// =========================================

// Affiche le formulaire pour créer un nouvel entrepôt.
router.get("/warehouses/add") { _, _ -> HTML in
    return Views.renderAddWarehouseForm()  // Génère le formulaire HTML vide
}

// Traite la soumission du formulaire de création d'entrepôt.
router.post("/warehouses/add") { request, _ -> Response in
    // Lit et décode les données envoyées par le formulaire
    let form = try await parseFormBody(request)

    // Récupère chaque champ du formulaire ; "" si le champ est absent
    let name = form["name"] ?? ""
    let description = form["description"] ?? ""
    // "Int(...) ?? 0" convertit le texte en entier, ou 0 si la conversion échoue
    let totalStorage = Int(form["totalStorage"] ?? "0") ?? 0

    // Validation basique : le nom ne doit pas être vide et la capacité > 0
    guard !name.isEmpty, totalStorage > 0 else {
        return Response(status: .badRequest)  // Code HTTP 400 : requête invalide
    }

    // Insère le nouvel entrepôt dans la base de données
    try Database.addWarehouse(
        db: db, name: name, description: description, totalStorage: totalStorage)

    // Redirige vers la page d'accueil après création (HTTP 303 See Other)
    return Response(status: .seeOther, headers: [.location: "/"])
}

// Affiche la page de détail d'un entrepôt avec ses produits.
// ":id" est un paramètre dynamique dans l'URL (ex : /warehouses/3 → id = "3")
router.get("/warehouses/:id") { _, context -> HTML in
    // Récupère le paramètre "id" depuis l'URL et le convertit en Int64
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        // Si l'ID est invalide, retourne une page d'erreur simple
        return HTML(content: "<p>Entrepôt introuvable.</p>")
    }
    // Cherche l'entrepôt en base
    guard let warehouse = try Database.fetchWarehouse(db: db, id: wid) else {
        return HTML(content: "<p>Entrepôt introuvable.</p>")
    }
    // Récupère tous les produits de cet entrepôt
    let warehouseProducts = try Database.fetchProducts(db: db, forWarehouseId: wid)
    // Génère la page de détail
    return Views.renderWarehouseDetail(warehouse: warehouse, products: warehouseProducts)
}

// Supprime un entrepôt (et tous ses produits grâce à CASCADE).
router.post("/warehouses/:id/delete") { _, context -> Response in
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    try Database.deleteWarehouse(db: db, id: wid)  // Supprime l'entrepôt en base
    return Response(status: .seeOther, headers: [.location: "/"])  // Retour à l'accueil
}

// =========================================
// Routes : Produits (Products)
// =========================================

// Affiche le formulaire pour ajouter un produit dans un entrepôt donné.
router.get("/warehouses/:id/products/add") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        return HTML(content: "<p>Entrepôt introuvable.</p>")
    }
    return Views.renderAddProductForm(warehouseId: wid)  // Génère le formulaire HTML
}

// Traite la soumission du formulaire de création de produit.
router.post("/warehouses/:id/products/add") { request, context -> Response in
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    let form = try await parseFormBody(request)

    let title = form["title"] ?? ""
    let description = form["description"] ?? ""
    let quantity = Int(form["quantity"] ?? "0") ?? 0
    let threshold = Int(form["threshold"] ?? "0") ?? 0

    // Validation : le titre ne doit pas être vide
    guard !title.isEmpty else {
        return Response(status: .badRequest)
    }

    // Insère le nouveau produit en base
    try Database.addProduct(
        db: db, title: title, description: description, quantity: quantity, threshold: threshold,
        warehouseId: wid)

    // Redirige vers la page de l'entrepôt après création
    return Response(status: .seeOther, headers: [.location: "/warehouses/\(wid)"])
}

// =========================================
// Routes : Modification d'un entrepôt
// =========================================

// Affiche le formulaire pré-rempli pour modifier un entrepôt existant.
router.get("/warehouses/:id/edit") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        return HTML(content: "<p>Entrepôt introuvable.</p>")
    }
    // Cherche l'entrepôt en base pour pré-remplir le formulaire
    guard let warehouse = try Database.fetchWarehouse(db: db, id: wid) else {
        return HTML(content: "<p>Entrepôt introuvable.</p>")
    }
    return Views.renderEditWarehouseForm(warehouse: warehouse)  // Génère le formulaire pré-rempli
}

// Traite la soumission du formulaire de modification d'entrepôt.
router.post("/warehouses/:id/edit") { request, context -> Response in
    guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    let form = try await parseFormBody(request)

    let name = form["name"] ?? ""
    let description = form["description"] ?? ""
    let totalStorage = Int(form["totalStorage"] ?? "0") ?? 0

    // Validation : nom non vide et capacité supérieure à 0
    guard !name.isEmpty, totalStorage > 0 else {
        return Response(status: .badRequest)
    }

    // Met à jour l'entrepôt en base de données
    try Database.updateWarehouse(
        db: db, id: wid, name: name, description: description, totalStorage: totalStorage)

    // Redirige vers la page de détail de l'entrepôt après modification
    return Response(status: .seeOther, headers: [.location: "/warehouses/\(wid)"])
}

// =========================================
// Routes : Modification d'un produit
// =========================================

// Affiche le formulaire pré-rempli pour modifier un produit existant.
router.get("/products/:id/edit") { _, context -> HTML in
    guard let idStr = context.parameters.get("id"), let pid = Int64(idStr) else {
        return HTML(content: "<p>Produit introuvable.</p>")
    }
    // Cherche le produit en base pour pré-remplir le formulaire
    guard let product = try Database.fetchProduct(db: db, id: pid) else {
        return HTML(content: "<p>Produit introuvable.</p>")
    }
    return Views.renderEditProductForm(product: product)  // Génère le formulaire pré-rempli
}

// Traite la soumission du formulaire de modification de produit.
router.post("/products/:id/edit") { request, context -> Response in
    guard let idStr = context.parameters.get("id"), let pid = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    let form = try await parseFormBody(request)

    let title = form["title"] ?? ""
    let description = form["description"] ?? ""
    let quantity = Int(form["quantity"] ?? "0") ?? 0
    let threshold = Int(form["threshold"] ?? "0") ?? 0

    // Validation : le titre ne doit pas être vide
    guard !title.isEmpty else {
        return Response(status: .badRequest)
    }

    // Récupère le warehouseId actuel pour conserver le rattachement à l'entrepôt
    guard let existing = try Database.fetchProduct(db: db, id: pid) else {
        return Response(status: .notFound)
    }

    // Met à jour le produit en base de données (en conservant son entrepôt)
    try Database.updateProduct(
        db: db, id: pid, title: title, description: description, quantity: quantity,
        threshold: threshold, warehouseId: existing.warehouseId)

    // Redirige vers la page de l'entrepôt après modification
    return Response(status: .seeOther, headers: [.location: "/warehouses/\(existing.warehouseId)"])
}

// Supprime un produit par son ID.
router.post("/products/:id/delete") { request, context -> Response in
    guard let idStr = context.parameters.get("id"), let pid = Int64(idStr) else {
        return Response(status: .badRequest)
    }
    // Récupère le produit pour connaître son entrepôt (pour la redirection)
    let product = try Database.fetchProduct(db: db, id: pid)
    let wid = product?.warehouseId ?? 0

    try Database.deleteProduct(db: db, id: pid)  // Supprime le produit en base

    // Redirige vers la page de l'entrepôt après suppression
    return Response(status: .seeOther, headers: [.location: "/warehouses/\(wid)"])
}

// =========================================
// Démarrage du serveur web
// =========================================

// "Application" crée le serveur Hummingbird avec le routeur et la configuration réseau.
let app = Application(
    router: router,
    // Écoute sur toutes les interfaces réseau ("0.0.0.0") sur le port 8080
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

print("🚀 Serveur démarré sur http://localhost:8080")

// Démarre le serveur et attend indéfiniment les requêtes entrantes.
// "try await" indique que c'est une opération asynchrone qui peut échouer.
try await app.runService()
