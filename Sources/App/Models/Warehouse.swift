// "import Foundation" importe les outils de base de Swift (dates, texte, nombres, etc.)
import Foundation

// Un "struct" est un type de donnée qui regroupe plusieurs propriétés liées.
// "Codable" permet de convertir ce struct en JSON et inversement (utile pour les API).
// "Sendable" indique que ce type est sûr à utiliser dans plusieurs tâches en même temps.

// Représente un entrepôt stocké dans la base de données.
struct Warehouse: Codable, Sendable {
    var id: Int64?  // Identifiant unique de l'entrepôt (nil avant insertion en base de données)
    var name: String  // Nom de l'entrepôt, ex : "Entrepôt Paris Nord"
    var description: String  // Description libre, ex : "Dédié aux produits réfrigérés"
    var usedStorage: Int  // Quantité d'espace de stockage actuellement occupé
    var totalStorage: Int  // Capacité maximale de stockage de l'entrepôt
}
