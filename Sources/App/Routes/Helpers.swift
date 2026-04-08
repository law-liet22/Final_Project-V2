// "import Foundation" importe les outils de base de Swift, notamment URLComponents
import Foundation
// "import Hummingbird" importe le framework web pour accéder au type Request
import Hummingbird

// =========================================
// Utilitaire : lecture du corps d'un formulaire HTML
// =========================================

// Les formulaires HTML envoient les données au format "clé=valeur&clé=valeur..." (URL-encodé).
// Cette fonction lit le corps de la requête et retourne un dictionnaire [nom -> valeur].
// "async" signifie que la fonction peut être suspendue en attendant des données réseau.
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
