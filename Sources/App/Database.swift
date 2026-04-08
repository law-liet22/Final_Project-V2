// \"import Foundation\" importe les outils de base de Swift
import Foundation
// \"import SQLite\" importe la bibliothèque SQLite.swift pour travailler avec la base de données
import SQLite

// SQLite.swift utilise une file d'attente interne, donc on peut l'utiliser en concurrence sans risque.
// \"@unchecked Sendable\" indique qu'on prend nous-mêmes la responsabilité de cette garantie.
// \"@retroactive\" permet d'étendre un type extérieur (Connection) avec un protocole (Sendable).
extension Connection: @unchecked @retroactive Sendable {}

// \"struct Database\" regroupe toutes les définitions de tables et les fonctions d'accès aux données.
struct Database {

    // =========================================
    // Définition de la table "warehouses" (entrepôts)
    // =========================================

    // \"Table(\"warehouses\")\" représente la table SQL nommée "warehouses"
    static let warehouses = Table("warehouses")

    // \"Expression<T>\" décrit une colonne de la table ; T est le type Swift de la donnée.
    static let warehouseId = Expression<Int64>("id")  // Colonne "id" : entier 64 bits
    static let warehouseName = Expression<String>("name")  // Colonne "name" : texte
    static let warehouseDesc = Expression<String>("description")  // Colonne "description" : texte
    static let warehouseUsed = Expression<Int>("used_storage")  // Stockage actuellement utilisé
    static let warehouseTotal = Expression<Int>("total_storage")  // Capacité totale de l'entrepôt

    // =========================================
    // Définition de la table "products" (produits)
    // =========================================

    static let products = Table("products")

    static let productId = Expression<Int64>("id")  // Colonne "id" : entier 64 bits
    static let productTitle = Expression<String>("title")  // Colonne "title" : texte
    static let productDesc = Expression<String>("description")  // Colonne "description" : texte
    static let productQuantity = Expression<Int>("quantity")  // Quantité en stock
    static let productThreshold = Expression<Int>("threshold")  // Seuil de réapprovisionnement
    static let productWarehouseId = Expression<Int64>("warehouse_id")  // Référence vers l'entrepôt (clé étrangère)

    // =========================================
    // Initialisation de la base de données
    // =========================================

    // Cette fonction est appelée au démarrage de l'application.
    // Elle ouvre (ou crée) le fichier .sqlite3 et crée les tables si elles n'existent pas encore.
    // \"throws\" signifie qu'elle peut lancer une erreur (ex : problème d'écriture sur le disque).
    static func setup() throws -> Connection {
        // Ouvre ou crée le fichier "db.sqlite3" dans le répertoire courant
        let db = try Connection("db.sqlite3")

        // Active les contraintes de clé étrangère dans SQLite.
        // Par défaut, SQLite ne les vérifie pas — cette ligne corrige ce comportement.
        try db.execute("PRAGMA foreign_keys = ON;")

        // Crée la table "warehouses" uniquement si elle n'existe pas encore ("ifNotExists: true").
        // La closure "{ t in ... }" définit les colonnes de la table.
        try db.run(
            warehouses.create(ifNotExists: true) { t in
                t.column(warehouseId, primaryKey: .autoincrement)  // Clé primaire auto-incrémentée : 1, 2, 3...
                t.column(warehouseName)  // Colonne obligatoire (pas de valeur par défaut)
                t.column(warehouseDesc)  // Colonne obligatoire
                t.column(warehouseUsed, defaultValue: 0)  // Stockage utilisé : 0 par défaut à la création
                t.column(warehouseTotal)  // Capacité totale : obligatoire
            })

        // Crée la table "products" uniquement si elle n'existe pas encore.
        try db.run(
            products.create(ifNotExists: true) { t in
                t.column(productId, primaryKey: .autoincrement)  // Clé primaire auto-incrémentée
                t.column(productTitle)  // Titre obligatoire
                t.column(productDesc)  // Description obligatoire
                t.column(productQuantity, defaultValue: 0)  // Quantité : 0 par défaut
                t.column(productThreshold, defaultValue: 0)  // Seuil : 0 par défaut
                t.column(productWarehouseId)  // ID de l'entrepôt : obligatoire
                // Clé étrangère : "warehouse_id" doit exister dans la colonne "id" de "warehouses".
                // "delete: .cascade" signifie que si l'entrepôt est supprimé, ses produits le sont aussi.
                t.foreignKey(
                    productWarehouseId, references: warehouses, warehouseId, delete: .cascade)
            })

        // Retourne la connexion active, prête à être utilisée dans le reste de l'application
        return db
    }

    // =========================================
    // CRUD des entrepôts
    // CRUD = Create (créer), Read (lire), Update (modifier), Delete (supprimer)
    // =========================================

    // Retourne la liste de tous les entrepôts présents dans la base de données.
    // \"throws\" signifie que la fonction peut échouer (connexion perdue, etc.).
    static func fetchAllWarehouses(db: Connection) throws -> [Warehouse] {
        // "db.prepare(warehouses)" prépare un SELECT * FROM warehouses
        // ".map { row in ... }" transforme chaque ligne SQL en objet Swift Warehouse
        return try db.prepare(warehouses).map { row in
            Warehouse(
                id: row[warehouseId],  // Lit la valeur de la colonne "id"
                name: row[warehouseName],  // Lit "name"
                description: row[warehouseDesc],  // Lit "description"
                usedStorage: row[warehouseUsed],  // Lit "used_storage"
                totalStorage: row[warehouseTotal]  // Lit "total_storage"
            )
        }
    }

    // Retourne un seul entrepôt identifié par son ID, ou nil s'il n'existe pas.
    static func fetchWarehouse(db: Connection, id targetId: Int64) throws -> Warehouse? {
        // ".filter(...)" ajoute une condition WHERE id = targetId à la requête
        let query = warehouses.filter(warehouseId == targetId)
        // "db.pluck" retourne la première ligne, ou nil si aucune ligne ne correspond
        return try db.pluck(query).map { row in
            Warehouse(
                id: row[warehouseId],
                name: row[warehouseName],
                description: row[warehouseDesc],
                usedStorage: row[warehouseUsed],
                totalStorage: row[warehouseTotal]
            )
        }
    }

    // Insère un nouvel entrepôt dans la base de données.
    static func addWarehouse(db: Connection, name: String, description: String, totalStorage: Int)
        throws
    {
        // "warehouses.insert(...)" génère un INSERT SQL.
        // L'opérateur "<-" assigne une valeur à une colonne (syntaxe propre à SQLite.swift).
        try db.run(
            warehouses.insert(
                warehouseName <- name,
                warehouseDesc <- description,
                warehouseUsed <- 0,  // Un nouvel entrepôt commence toujours avec 0 utilisé
                warehouseTotal <- totalStorage
            ))
    }

    // Met à jour les informations d'un entrepôt existant, identifié par son ID.
    static func updateWarehouse(
        db: Connection, id targetId: Int64, name: String, description: String, totalStorage: Int
    ) throws {
        // Sélectionne uniquement la ligne dont l'ID vaut targetId
        let target = warehouses.filter(warehouseId == targetId)
        // ".update(...)" génère un UPDATE SQL pour les colonnes spécifiées
        try db.run(
            target.update(
                warehouseName <- name,
                warehouseDesc <- description,
                warehouseTotal <- totalStorage
            ))
    }

    // Supprime un entrepôt par son ID.
    // Grâce à la règle CASCADE, tous les produits de cet entrepôt seront aussi supprimés.
    static func deleteWarehouse(db: Connection, id targetId: Int64) throws {
        let target = warehouses.filter(warehouseId == targetId)  // Sélectionne la ligne ciblée
        try db.run(target.delete())  // Exécute le DELETE SQL
    }

    // =========================================
    // CRUD des produits
    // =========================================

    // Retourne la liste de tous les produits présents dans la base de données.
    static func fetchAllProducts(db: Connection) throws -> [Product] {
        return try db.prepare(products).map { row in
            Product(
                id: row[productId],
                title: row[productTitle],
                description: row[productDesc],
                quantity: row[productQuantity],
                threshold: row[productThreshold],
                warehouseId: row[productWarehouseId]
            )
        }
    }

    // Retourne tous les produits appartenant à un entrepôt donné (filtré par warehouseId).
    static func fetchProducts(db: Connection, forWarehouseId wid: Int64) throws -> [Product] {
        // Filtre les produits dont la colonne "warehouse_id" correspond à "wid"
        let query = products.filter(productWarehouseId == wid)
        return try db.prepare(query).map { row in
            Product(
                id: row[productId],
                title: row[productTitle],
                description: row[productDesc],
                quantity: row[productQuantity],
                threshold: row[productThreshold],
                warehouseId: row[productWarehouseId]
            )
        }
    }

    // Retourne un seul produit identifié par son ID, ou nil s'il n'existe pas.
    static func fetchProduct(db: Connection, id targetId: Int64) throws -> Product? {
        let query = products.filter(productId == targetId)
        return try db.pluck(query).map { row in
            Product(
                id: row[productId],
                title: row[productTitle],
                description: row[productDesc],
                quantity: row[productQuantity],
                threshold: row[productThreshold],
                warehouseId: row[productWarehouseId]
            )
        }
    }

    // Insère un nouveau produit dans la base de données.
    static func addProduct(
        db: Connection, title: String, description: String, quantity: Int, threshold: Int,
        warehouseId wid: Int64
    ) throws {
        try db.run(
            products.insert(
                productTitle <- title,
                productDesc <- description,
                productQuantity <- quantity,
                productThreshold <- threshold,
                productWarehouseId <- wid  // Lie ce produit à un entrepôt existant
            ))
    }

    // Met à jour un produit existant, identifié par son ID.
    static func updateProduct(
        db: Connection, id targetId: Int64, title: String, description: String, quantity: Int,
        threshold: Int, warehouseId wid: Int64
    ) throws {
        let target = products.filter(productId == targetId)  // Sélectionne le produit ciblé
        try db.run(
            target.update(
                productTitle <- title,
                productDesc <- description,
                productQuantity <- quantity,
                productThreshold <- threshold,
                productWarehouseId <- wid
            ))
    }

    // Supprime un produit par son ID.
    static func deleteProduct(db: Connection, id targetId: Int64) throws {
        let target = products.filter(productId == targetId)  // Sélectionne le produit ciblé
        try db.run(target.delete())  // Exécute le DELETE SQL
    }
}
