// "import Foundation" importe les outils de base de Swift
import Foundation
// "import Hummingbird" importe le framework web pour pouvoir retourner des réponses HTTP
import Hummingbird

// "struct Views" regroupe toutes les fonctions qui génèrent des pages HTML.
// Chaque fonction retourne un objet HTML (défini dans HTML.swift).
struct Views {

    // =========================================
    // Page d'accueil : liste de tous les entrepôts
    // =========================================

    // Génère la page principale affichant la liste de tous les entrepôts.
    // "warehouses" est le tableau d'entrepôts à afficher.
    static func renderIndex(warehouses: [Warehouse]) -> HTML {

        // Pour chaque entrepôt, on génère un bloc HTML (article).
        // ".map { ... }" transforme chaque entrepôt en une chaîne de texte HTML.
        // ".joined()" colle tous ces blocs HTML en un seul texte.
        let rows = warehouses.map { wh in
            // On calcule un pourcentage d'utilisation pour la barre de progression
            // Swift utilise la valeur 0 si le stockage total vaut 0 (évite la division par zéro)
            let usedPct =
                wh.totalStorage > 0
                ? Int((Double(wh.usedStorage) / Double(wh.totalStorage)) * 100)
                : 0
            // On clamp le pourcentage entre 0 et 100 pour ne jamais dépasser les bornes
            // "min(100, max(0, ...))" garantit que la valeur reste dans l'intervalle [0, 100]
            let clampedPct = min(100, max(0, usedPct))
            // Retourne le bloc HTML pour cet entrepôt
            return """
                <article>
                    <header>
                        <strong><a href="/warehouses/\(wh.id ?? 0)">\(wh.name)</a></strong>
                    </header>
                    <p>\(wh.description)</p>
                    <p>Stockage : \(wh.usedStorage) / \(wh.totalStorage) unités (\(clampedPct)%)</p>
                    <div style="background:#e5e7eb; border-radius:6px; height:12px; overflow:hidden;">
                        <div style="
                            width:\(clampedPct)%;
                            height:100%;
                            background: linear-gradient(to right, #3b82f6, #a855f7, #ef4444);
                            background-size: \(clampedPct > 0 ? Int(10000 / clampedPct) : 100)% 100%;
                            border-radius:6px;
                            transition: width 0.4s ease;
                        "></div>
                    </div>
                    <footer style="display:flex; gap:8px; margin-top:0.75rem;">
                        <a href="/warehouses/\(wh.id ?? 0)" role="button" class="outline">Voir les produits</a>
                        <a href="/warehouses/\(wh.id ?? 0)/edit" role="button" class="outline secondary">Modifier</a>
                        <form action="/warehouses/\(wh.id ?? 0)/delete" method="post" style="margin:0;">
                            <button type="submit" class="outline contrast">Supprimer</button>
                        </form>
                    </footer>
                </article>
                """
        }.joined()

        // Retourne la page HTML complète avec la liste des entrepôts
        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 800px;">
                    <header>
                        <h1>Gestion de Stock</h1>
                        <p>Application de gestion des entrepôts et des produits. Projet final de fin de semestre à l'université Paris 8.</p>
                    </header>
                    <main>
                        <section>
                            <h2>Entrepôts <a href="/warehouses/add" role="button" style="float:right; font-size:0.9rem;">+ Ajouter</a></h2>
                            \(warehouses.isEmpty ? "<p>Aucun entrepôt pour l'instant. Commencez par en ajouter un !</p>" : rows)
                        </section>
                    </main>
                </body>
                </html>
                """)
    }

    // =========================================
    // Page de détail d'un entrepôt (avec ses produits)
    // =========================================

    // Génère la page de détail d'un entrepôt, avec la liste de ses produits.
    // "warehouse" est l'entrepôt à afficher ; "products" est la liste de ses produits.
    static func renderWarehouseDetail(warehouse: Warehouse, products: [Product]) -> HTML {

        // Pour chaque produit, on génère un bloc HTML.
        let rows = products.map { p in
            // Si la quantité est sous le seuil, on affiche une alerte en rouge
            let alert =
                p.quantity < p.threshold
                ? "<span style=\"color:red;\"> ⚠️ Stock bas !</span>"
                : ""
            return """
                <article>
                    <header>
                        <strong>\(p.title)</strong>\(alert)
                    </header>
                    <p>\(p.description)</p>
                    <p>Quantité : <strong>\(p.quantity)</strong> | Seuil : \(p.threshold)</p>
                    <footer style="display:flex; gap:8px;">
                        <a href="/products/\(p.id ?? 0)/edit" role="button" class="outline secondary">Modifier</a>
                        <form action="/products/\(p.id ?? 0)/delete" method="post" style="margin:0;">
                            <button type="submit" class="outline contrast">Supprimer</button>
                        </form>
                    </footer>
                </article>
                """
        }.joined()

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>\(warehouse.name) – WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 800px;">
                    <header>
                        <a href="/">← Retour aux entrepôts</a>
                        <h1>\(warehouse.name)</h1>
                        <p>\(warehouse.description)</p>
                        <p>Stockage : \(warehouse.usedStorage) / \(warehouse.totalStorage) unités</p>
                    </header>
                    <main>
                        <section>
                            <h2>Produits <a href="/warehouses/\(warehouse.id ?? 0)/products/add" role="button" style="float:right; font-size:0.9rem;">+ Ajouter un produit</a></h2>
                            \(products.isEmpty ? "<p>Aucun produit dans cet entrepôt.</p>" : rows)
                        </section>
                    </main>
                </body>
                </html>
                """)
    }

    // =========================================
    // Formulaire d'ajout d'un entrepôt
    // =========================================

    // Génère le formulaire HTML pour créer un nouvel entrepôt.
    // "error" est un message d'erreur optionnel à afficher (nil = pas d'erreur).
    static func renderAddWarehouseForm(error: String? = nil) -> HTML {
        // Si une erreur est présente, on génère un paragraphe rouge, sinon une chaîne vide
        let errorHtml = error.map { "<p style=\"color:red;\">\($0)</p>" } ?? ""

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Ajouter un entrepôt – WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 600px;">
                    <header>
                        <a href="/">← Retour</a>
                        <h1>Ajouter un entrepôt</h1>
                    </header>
                    <main>
                        \(errorHtml)
                        <form action="/warehouses/add" method="post">
                            <label>Nom
                                <input type="text" name="name" placeholder="Entrepôt Paris Nord" required>
                            </label>
                            <label>Description
                                <textarea name="description" placeholder="Description de l'entrepôt..."></textarea>
                            </label>
                            <label>Capacité totale (unités)
                                <input type="number" name="totalStorage" min="1" required>
                            </label>
                            <button type="submit">Créer l'entrepôt</button>
                        </form>
                    </main>
                </body>
                </html>
                """)
    }

    // =========================================
    // Formulaire de modification d'un entrepôt
    // =========================================

    // Génère le formulaire HTML pré-rempli pour modifier un entrepôt existant.
    // "warehouse" est l'entrepôt dont on veut modifier les informations.
    // "error" est un message d'erreur optionnel à afficher (nil = pas d'erreur).
    static func renderEditWarehouseForm(warehouse: Warehouse, error: String? = nil) -> HTML {
        let errorHtml = error.map { "<p style=\"color:red;\">\($0)</p>" } ?? ""
        // "wid" est l'ID de l'entrepôt, utilisé dans l'URL du formulaire
        let wid = warehouse.id ?? 0

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Modifier \(warehouse.name) – WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 600px;">
                    <header>
                        <a href="/">← Retour aux entrepôts</a>
                        <h1>Modifier l'entrepôt</h1>
                    </header>
                    <main>
                        \(errorHtml)
                        <form action="/warehouses/\(wid)/edit" method="post">
                            <label>Nom
                                <input type="text" name="name" value="\(warehouse.name)" required>
                            </label>
                            <label>Description
                                <textarea name="description">\(warehouse.description)</textarea>
                            </label>
                            <label>Capacité totale (unités)
                                <input type="number" name="totalStorage" value="\(warehouse.totalStorage)" min="1" required>
                            </label>
                            <button type="submit">Enregistrer les modifications</button>
                        </form>
                    </main>
                </body>
                </html>
                """)
    }

    // =========================================
    // Formulaire d'ajout d'un produit dans un entrepôt
    // =========================================

    // Génère le formulaire HTML pour ajouter un produit dans un entrepôt spécifique.
    // "warehouseId" est l'ID de l'entrepôt auquel le produit sera rattaché.
    // "error" est un message d'erreur optionnel (nil = pas d'erreur).
    static func renderAddProductForm(warehouseId: Int64, error: String? = nil) -> HTML {
        let errorHtml = error.map { "<p style=\"color:red;\">\($0)</p>" } ?? ""

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Ajouter un produit – WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 600px;">
                    <header>
                        <a href="/warehouses/\(warehouseId)">← Retour à l'entrepôt</a>
                        <h1>Ajouter un produit</h1>
                    </header>
                    <main>
                        \(errorHtml)
                        <form action="/warehouses/\(warehouseId)/products/add" method="post">
                            <label>Nom du produit
                                <input type="text" name="title" placeholder="Boîte de vis M6" required>
                            </label>
                            <label>Description
                                <textarea name="description" placeholder="Description du produit..."></textarea>
                            </label>
                            <label>Quantité en stock
                                <input type="number" name="quantity" value="0" min="0" required>
                            </label>
                            <label>Seuil de réapprovisionnement
                                <input type="number" name="threshold" value="0" min="0" required>
                            </label>
                            <button type="submit">Ajouter le produit</button>
                        </form>
                    </main>
                </body>
                </html>
                """)
    }

    // =========================================
    // Formulaire de modification d'un produit
    // =========================================

    // Génère le formulaire HTML pré-rempli pour modifier un produit existant.
    // "product" est le produit dont on veut modifier les informations.
    // "error" est un message d'erreur optionnel (nil = pas d'erreur).
    static func renderEditProductForm(product: Product, error: String? = nil) -> HTML {
        let errorHtml = error.map { "<p style=\"color:red;\">\($0)</p>" } ?? ""
        // "pid" est l'ID du produit, utilisé dans l'URL du formulaire
        let pid = product.id ?? 0

        return HTML(
            content: """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
                    <title>Modifier \(product.title) – WareStock</title>
                </head>
                <body class="container" style="padding-top: 2rem; max-width: 600px;">
                    <header>
                        <a href="/warehouses/\(product.warehouseId)">← Retour à l'entrepôt</a>
                        <h1>Modifier le produit</h1>
                    </header>
                    <main>
                        \(errorHtml)
                        <form action="/products/\(pid)/edit" method="post">
                            <label>Nom du produit
                                <input type="text" name="title" value="\(product.title)" required>
                            </label>
                            <label>Description
                                <textarea name="description">\(product.description)</textarea>
                            </label>
                            <label>Quantité en stock
                                <input type="number" name="quantity" value="\(product.quantity)" min="0" required>
                            </label>
                            <label>Seuil de réapprovisionnement
                                <input type="number" name="threshold" value="\(product.threshold)" min="0" required>
                            </label>
                            <button type="submit">Enregistrer les modifications</button>
                        </form>
                    </main>
                </body>
                </html>
                """)
    }
}
