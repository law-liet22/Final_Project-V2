// "import Hummingbird" importe le framework web (Router, Request, Response, etc.)
import Hummingbird
// "@preconcurrency" supprime certains avertissements liés à la concurrence pour ce module
@preconcurrency import SQLite

// Enregistre sur le routeur toutes les routes liées aux produits.
// "router" : le routeur Hummingbird principal, sur lequel les routes sont attachées.
// "db"     : la connexion SQLite partagée, passée en paramètre pour éviter les variables globales.
func registerProductRoutes(on router: Router<BasicRequestContext>, db: Connection) {

    // Affiche le formulaire pour ajouter un produit dans un entrepôt donné.
    // ":id" dans l'URL représente l'ID de l'entrepôt (ex : /warehouses/3/products/add)
    router.get("/warehouses/:id/products/add") { _, context -> HTML in
        guard let idStr = context.parameters.get("id"), let wid = Int64(idStr) else {
            return HTML(content: "<p>Entrepôt introuvable.</p>")
        }
        return Views.renderAddProductForm(warehouseId: wid)  // Génère le formulaire HTML vide
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
            db: db, title: title, description: description, quantity: quantity,
            threshold: threshold, warehouseId: wid)

        // Redirige vers la page de l'entrepôt après création
        return Response(status: .seeOther, headers: [.location: "/warehouses/\(wid)"])
    }

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
        return Response(
            status: .seeOther, headers: [.location: "/warehouses/\(existing.warehouseId)"])
    }

    // Supprime un produit par son ID.
    router.post("/products/:id/delete") { _, context -> Response in
        guard let idStr = context.parameters.get("id"), let pid = Int64(idStr) else {
            return Response(status: .badRequest)
        }
        // Récupère le produit pour connaître son entrepôt (pour la redirection après suppression)
        let product = try Database.fetchProduct(db: db, id: pid)
        let wid = product?.warehouseId ?? 0

        try Database.deleteProduct(db: db, id: pid)  // Supprime le produit en base

        // Redirige vers la page de l'entrepôt après suppression
        return Response(status: .seeOther, headers: [.location: "/warehouses/\(wid)"])
    }
}
