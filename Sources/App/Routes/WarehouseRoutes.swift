// "import Hummingbird" importe le framework web (Router, Request, Response, etc.)
import Hummingbird
// "@preconcurrency" supprime certains avertissements liés à la concurrence pour ce module
@preconcurrency import SQLite

// Enregistre sur le routeur toutes les routes liées aux entrepôts.
// "router" : le routeur Hummingbird principal, sur lequel les routes sont attachées.
// "db"     : la connexion SQLite partagée, passée en paramètre pour éviter les variables globales.
func registerWarehouseRoutes(on router: Router<BasicRequestContext>, db: Connection) {

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
            return HTML(content: "<p>Entrepôt introuvable.</p>")  // Si l'ID est invalide
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
}
