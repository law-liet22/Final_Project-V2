// "import Hummingbird" importe le framework web pour accéder aux types Request, Response, etc.
import Hummingbird

// =========================================
// Type HTML : permet à Hummingbird de retourner du HTML en réponse HTTP
// =========================================

// "ResponseGenerator" est un protocole de Hummingbird.
// En le respectant, on peut retourner un objet HTML directement depuis une route.
struct HTML: ResponseGenerator {
    let content: String  // Le contenu HTML de la page

    // Cette fonction est appelée par Hummingbird pour construire la réponse HTTP.
    // "request" représente la requête reçue ; "context" contient le contexte de la requête.
    func response(from request: Request, context: some RequestContext) throws -> Response {
        return Response(
            status: .ok,  // Code HTTP 200 OK
            headers: [.contentType: "text/html; charset=utf-8"],  // Indique au navigateur le type de contenu
            body: .init(byteBuffer: .init(string: content))  // Corps de la réponse = le HTML
        )
    }
}
