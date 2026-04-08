import Foundation
import Hummingbird
// "@preconcurrency" supprime certains avertissements liés à la concurrence pour ce module
@preconcurrency import SQLite

// =========================================
// Démarrage de la base de données
// =========================================

// Ouvre (ou crée) le fichier .sqlite3 et prépare les tables.
// "try" indique que cette opération peut échouer ; si c'est le cas, l'application s'arrête.
let db = try Database.setup()

// =========================================
// Configuration du routeur HTTP (Hummingbird)
// =========================================

// "Router()" crée le routeur qui associe des URL à des fonctions Swift.
let router = Router()

// Enregistre les routes liées aux entrepôts (voir Routes/WarehouseRoutes.swift)
registerWarehouseRoutes(on: router, db: db)

// Enregistre les routes liées aux produits (voir Routes/ProductRoutes.swift)
registerProductRoutes(on: router, db: db)

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
