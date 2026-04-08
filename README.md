# Préambule -- WareStock

Créée à partir d'un template d'un environnement iOS donné par M. O'SHEI durant le cours de développement mobile au semestre 2 de la L3 ISEI à l'Université Paris 8, cette application est un projet de développement d'une app. web en Swift, utilisant GitHub Codespaces pour le développement, sans nécessiter Xcode ou macOS.

Le projet est une application de **gestion de stocks** basique, permettant aux utilisateurs de gérer des entrepôts et les produits qui y sont stockés. L'application utilise SQLite pour la persistance des données et Hummingbird pour le serveur web.

---

## 1. Compiler et exécuter

Dans le terminal de votre Codespace :

```bash
./build.sh
```

Ce résout les dépendances et compile le projet. Lorsque c'est terminé, démarrez le serveur :

```bash
./run.sh
```

Codespaces détectera que le port **8080** est maintenant utilisé et affichera une fenêtre contextuelle — cliquez sur **"Open in Browser"** (ou trouvez-le sous l'onglet **Ports**). Vous devriez voir l'application WareStock en cours d'exécution.

> Pour arrêter le serveur, appuyez sur `Ctrl + C` dans le terminal.

---

## 2. Structure du projet

```
Sources/App/
  main.swift                    # Point d'entrée — démarre la base de données et le serveur
  Models/
    Warehouse.swift             # Struct Warehouse (id, name, description, usedStorage, totalStorage)
    Product.swift               # Struct Product (id, title, description, quantity, threshold, warehouseId)
  Database/
    Database.swift              # Configuration SQLite, création des tables, toutes les fonctions CRUD
  Views/
    Views.swift                 # Génération des pages HTML (renderIndex, renderWarehouseDetail, etc.)
    HTML.swift                  # Struct HTML conforme à ResponseGenerator (Hummingbird)
  Routes/
    Helpers.swift               # Fonction utilitaire parseFormBody (décodage des formulaires HTML)
    WarehouseRoutes.swift       # Toutes les routes HTTP liées aux entrepôts
    ProductRoutes.swift         # Toutes les routes HTTP liées aux produits
Package.swift                   # Définition du package Swift — dépendances et cibles de compilation
build.sh                        # Script d'aide : résoudre les dépendances et compiler
run.sh                          # Script d'aide : démarrer le serveur
```

---

## 3. Comment ça fonctionne ?

```
Navigateur  →  Requête HTTP
                  ↓
         main.swift  (enregistre les routes via registerWarehouseRoutes / registerProductRoutes)
                  ↓
         Routes/*.swift  (la route correspondante traite la requête)
                  ↓
         Database/Database.swift  (SQLite.swift lit ou écrit dans db.sqlite3)
                  ↓
         Views/Views.swift  (construit une chaîne HTML à partir des données)
                  ↓
         Réponse HTTP  →  Le navigateur affiche la page
```

| Couche | Fichier(s) | Technologie |
|---|---|---|
| Serveur web & routing | `main.swift`, `Routes/*.swift` | [Hummingbird 2](https://github.com/hummingbird-project/hummingbird) |
| Modèles de données | `Models/Warehouse.swift`, `Models/Product.swift` | Swift `struct` |
| Base de données | `Database/Database.swift` | [SQLite.swift](https://github.com/stephencelis/SQLite.swift) |
| Interface / HTML | `Views/Views.swift`, `Views/HTML.swift` | [Pico CSS](https://picocss.com) |

---

## 4. Référence des routes HTTP

### Entrepôts — `Routes/WarehouseRoutes.swift`

| Méthode | URL | Quand elle est appelée | Ce qu'elle fait |
|---|---|---|---|
| `GET` | `/` | Chargement de la page d'accueil | Lit tous les entrepôts en base et affiche la liste avec leur barre de remplissage |
| `GET` | `/warehouses/add` | Clic sur "+ Ajouter" | Affiche le formulaire vide de création d'entrepôt |
| `POST` | `/warehouses/add` | Soumission du formulaire de création | Valide les champs, insère l'entrepôt en base, redirige vers `/` |
| `GET` | `/warehouses/:id` | Clic sur "Voir les produits" | Affiche la page de détail de l'entrepôt avec la liste de ses produits |
| `GET` | `/warehouses/:id/edit` | Clic sur "Modifier" (entrepôt) | Affiche le formulaire pré-rempli avec les données actuelles de l'entrepôt |
| `POST` | `/warehouses/:id/edit` | Soumission du formulaire de modification | Valide les champs, met à jour l'entrepôt en base, redirige vers `/warehouses/:id` |
| `POST` | `/warehouses/:id/delete` | Clic sur "Supprimer" (entrepôt) | Supprime l'entrepôt et **tous ses produits** (règle CASCADE SQLite), redirige vers `/` |

### Produits — `Routes/ProductRoutes.swift`

| Méthode | URL | Quand elle est appelée | Ce qu'elle fait |
|---|---|---|---|
| `GET` | `/warehouses/:id/products/add` | Clic sur "+ Ajouter un produit" | Affiche le formulaire vide de création de produit rattaché à l'entrepôt `:id` |
| `POST` | `/warehouses/:id/products/add` | Soumission du formulaire de création | Valide les champs et la capacité disponible, insère le produit, redirige vers `/warehouses/:id` |
| `GET` | `/products/:id/edit` | Clic sur "Modifier" (produit) | Affiche le formulaire pré-rempli avec les données actuelles du produit |
| `POST` | `/products/:id/edit` | Soumission du formulaire de modification | Valide les champs et la capacité disponible, met à jour le produit, redirige vers `/warehouses/:warehouseId` |
| `POST` | `/products/:id/delete` | Clic sur "Supprimer" (produit) | Supprime le produit, recalcule le `usedStorage` de l'entrepôt, redirige vers `/warehouses/:warehouseId` |

### Règles de validation

- **Entrepôt** : le nom ne peut pas être vide et la capacité totale doit être supérieure à 0.
- **Produit (ajout)** : le titre ne peut pas être vide et `quantity` ne peut pas dépasser `totalStorage - usedStorage` de l'entrepôt.
- **Produit (modification)** : même règle, mais la quantité actuelle du produit est d'abord restituée avant de calculer l'espace disponible (`totalStorage - usedStorage + quantitéActuelle`).

---

## 5. Concepts Swift clés dans ce projet

| Concept | Où le voir |
|---|---|
| `struct` | `Models/`, `Database/Database.swift`, `Views/HTML.swift` |
| `async/await` | `main.swift` — `app.runService()`, handlers de routes |
| Closures | `Routes/*.swift` — blocs `{ request, context in ... }` |
| Conformité à un protocole | `Views/HTML.swift` — `HTML: ResponseGenerator` |
| `throws` / `try` | `Database/Database.swift` — tous les appels base de données |
| Extensions | `Database/Database.swift` — `Connection: @unchecked Sendable` |
| Clé étrangère SQL + CASCADE | `Database/Database.swift` — `setup()` |

---

## 6. Dépannage

**Le port 8080 est déjà utilisé**
```bash
lsof -i :8080
kill <PID>
```
Puis redémarrez avec `./run.sh`.

**Erreurs de compilation au premier lancement**
```bash
swift package resolve
./build.sh
```

**Les modifications ne s'affichent pas dans le navigateur**
Le serveur doit être redémarré après chaque recompilation. Appuyez sur `Ctrl + C`, puis relancez `./build.sh` et `./run.sh`.