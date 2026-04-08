// "import Foundation" importe les outils de base de Swift (dates, texte, nombres, etc.)
import Foundation

// Représente un produit stocké dans la base de données.
struct Product: Codable, Sendable {
    var id: Int64?  // Identifiant unique du produit (nil avant insertion en base de données)
    var title: String  // Nom du produit, ex : "Boîte de vis M6"
    var description: String  // Description libre, ex : "Lot de 100 vis inox"
    var quantity: Int  // Quantité actuellement en stock
    var threshold: Int  // Seuil de réapprovisionnement : alerte quand le stock passe en dessous
    var warehouseId: Int64  // ID de l'entrepôt dans lequel ce produit est stocké (clé étrangère)
}
