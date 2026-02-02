# Documentation - Système de Groupe avec WebSocket

## Vue d'ensemble

Le système de groupe permet à plusieurs joueurs de se rassembler dans une partie multijoueur en temps réel. La communication entre les clients et le serveur se fait via :
- **API REST** : Pour créer/rejoindre/quitter une partie et configurer les paramètres
- **WebSocket (SignalR)** : Pour les notifications en temps réel et les interactions durant le jeu

---

## Configuration de base

### URL de l'API
- Base URL : `https://votre-domaine.com/api/v1`
- WebSocket Hub : `https://votre-domaine.com/group`

### Authentification
Toutes les requêtes nécessitent un token JWT dans le header :
```
Authorization: Bearer <votre-token-jwt>
```

---

## Routes API REST

### 1. Créer une partie de groupe

**Endpoint** : `POST /v1/group/create`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Corps de la requête** : Aucun

**Réponse** (200 OK) :
```json
{
  "id": "guid",
  "code": "ABC123",
  "nbQuestions": 10,
  "inProgress": false,
  "scoreEachRound": false,
  "idPartyType": 2,
  "idUserHost": 123,
  "active": true,
  "finish": false,
  "dt": "2026-02-02T10:00:00Z",
  "partyUsers": [],
  "partyTheme": [
    {
      "idTheme": 1,
      "theme": {
        "id": 1,
        "label": "Histoire"
      }
    }
  ],
  "partyDifficulty": [
    {
      "idDifficulty": 1,
      "difficulty": {
        "id": 1,
        "label": "Facile"
      }
    }
  ],
  "percent": 0,
  "score": 0,
  "time": 0
}
```

**Codes d'erreur** :
- `401 Unauthorized` : Token manquant ou invalide
- `500 Internal Server Error` : Erreur serveur

---

### 2. Rejoindre une partie de groupe

**Endpoint** : `POST /v1/group/join`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Corps de la requête** :
```json
{
  "code": "ABC123"
}
```

**Réponse** (200 OK) :
Même structure que la réponse de création, mais avec les joueurs déjà présents dans `partyUsers`.

**Codes d'erreur** :
- `401 Unauthorized` : Token manquant ou invalide
- `404 Not Found` : Code de partie invalide
- `500 Internal Server Error` : Erreur serveur

---

### 3. Quitter une partie de groupe

**Endpoint** : `POST /v1/group/leave`

**Headers** :
```
Authorization: Bearer <token>
```

**Corps de la requête** : Aucun

**Réponse** (200 OK) : Aucun contenu

**Codes d'erreur** :
- `401 Unauthorized` : Token manquant ou invalide
- `500 Internal Server Error` : Erreur serveur

---

### 4. Modifier les paramètres de la partie

**Endpoint** : `POST /v1/group/settings`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Corps de la requête** :
```json
{
  "themes": [1, 2, 3],
  "difficulties": [1, 2],
  "nbQuestions": 10,
  "scoreEachRound": true
}
```

**Paramètres** :
- `themes` : Tableau d'IDs de thèmes (obligatoire, non vide)
- `difficulties` : Tableau d'IDs de difficultés (obligatoire, non vide)
- `nbQuestions` : Nombre de questions (5, 10, 15 ou 20)
- `scoreEachRound` : Si `true`, les scores sont envoyés après chaque question

**Réponse** (200 OK) : Aucun contenu

**Codes d'erreur** :
- `400 Bad Request` : Paramètres invalides
- `401 Unauthorized` : Token manquant ou invalide
- `500 Internal Server Error` : Erreur serveur

---

## WebSocket (SignalR)

### Connexion au Hub

**URL** : `/group`

**Exemple de connexion (JavaScript)** :
```javascript
const connection = new signalR.HubConnectionBuilder()
    .withUrl("https://votre-domaine.com/group", {
        accessTokenFactory: () => "votre-token-jwt"
    })
    .withAutomaticReconnect()
    .build();

await connection.start();
```

---

## Méthodes invocables par le client (Client → Serveur)

### 1. Démarrer la partie

**Nom de la méthode** : `StartGroupParty`

**Paramètres** : Aucun

**Exemple** :
```javascript
await connection.invoke("StartGroupParty");
```

**Description** : Le joueur hôte appelle cette méthode pour démarrer la partie. Tous les joueurs recevront ensuite les événements de jeu.

---

### 2. Envoyer une réponse

**Nom de la méthode** : `SendAnswer`

**Paramètres** :
- `answerId` (number) : L'ID de la réponse sélectionnée

**Exemple** :
```javascript
await connection.invoke("SendAnswer", 42);
```

**Description** : Le joueur envoie sa réponse à la question en cours.

---

## Événements reçus par le client (Serveur → Client)

### 1. OnPlayerJoined

**Nom de l'événement** : `OnPlayerJoined`

**Données reçues** :
```json
{
  "id": 123,
  "nickName": "JoueurTest",
  "email": "joueur@exemple.com",
  "avatar": "https://...",
  "isAdmin": false,
  "isNew": false
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnPlayerJoined", (user) => {
    console.log(`${user.nickName} a rejoint la partie`);
    // Mettre à jour la liste des joueurs dans l'interface
});
```

**Description** : Notifie tous les joueurs qu'un nouveau joueur a rejoint la partie.

---

### 2. OnPlayerLeft

**Nom de l'événement** : `OnPlayerLeft`

**Données reçues** :
```json
{
  "id": 123,
  "nickName": "JoueurTest",
  "email": "joueur@exemple.com",
  "avatar": "https://...",
  "isAdmin": false,
  "isNew": false
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnPlayerLeft", (user) => {
    console.log(`${user.nickName} a quitté la partie`);
    // Retirer le joueur de la liste dans l'interface
});
```

**Description** : Notifie tous les joueurs qu'un joueur a quitté la partie.

---

### 3. OnPartyDeleted

**Nom de l'événement** : `OnPartyDeleted`

**Données reçues** :
```json
{
  "id": 123,
  "nickName": "Hôte",
  "email": "hote@exemple.com",
  "avatar": "https://...",
  "isAdmin": false,
  "isNew": false
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnPartyDeleted", (user) => {
    console.log(`La partie a été supprimée par ${user.nickName}`);
    // Rediriger vers l'écran d'accueil
});
```

**Description** : Notifie tous les joueurs que la partie a été supprimée (généralement par l'hôte).

---

### 4. OnPartyUpdated

**Nom de l'événement** : `OnPartyUpdated`

**Données reçues** :
```json
{
  "id": "guid",
  "code": "ABC123",
  "nbQuestions": 15,
  "inProgress": false,
  "scoreEachRound": true,
  "idPartyType": 2,
  "idUserHost": 123,
  "active": true,
  "finish": false,
  "partyUsers": [...],
  "partyTheme": [...],
  "partyDifficulty": [...],
  "percent": 0,
  "score": 0,
  "time": 0
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnPartyUpdated", (party) => {
    console.log("Paramètres de la partie mis à jour");
    // Mettre à jour l'affichage des paramètres
});
```

**Description** : Notifie tous les joueurs que les paramètres de la partie ont été modifiés.

---

### 5. OnPartyStarted

**Nom de l'événement** : `OnPartyStarted`

**Données reçues** :
```json
{
  "id": "guid",
  "code": "ABC123",
  "nbQuestions": 10,
  "inProgress": true,
  "scoreEachRound": false,
  "idPartyType": 2,
  "idUserHost": 123,
  "active": true,
  "finish": false,
  "partyUsers": [...],
  "partyTheme": [...],
  "partyDifficulty": [...],
  "percent": 0,
  "score": 0,
  "time": 0
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnPartyStarted", (party) => {
    console.log("La partie commence !");
    // Passer à l'écran de jeu
});
```

**Description** : Notifie tous les joueurs que la partie a démarré.

---

### 6. OnCountdown

**Nom de l'événement** : `OnCountdown`

**Données reçues** : Un nombre (secondes restantes)

**Exemple d'écoute** :
```javascript
connection.on("OnCountdown", (seconds) => {
    console.log(`Compte à rebours: ${seconds}`);
    // Afficher le compte à rebours avant la question
});
```

**Description** : Compte à rebours avant l'affichage d'une question (généralement 3, 2, 1...).

---

### 7. OnQuestionSend

**Nom de l'événement** : `OnQuestionSend`

**Données reçues** :
```json
{
  "question": {
    "id": 42,
    "label": "Quelle est la capitale de la France ?",
    "idDifficulty": 1,
    "difficulty": {
      "id": 1,
      "label": "Facile"
    },
    "answer": [
      {
        "id": 1,
        "idQuestion": 42,
        "value": "Paris",
        "valid": null
      },
      {
        "id": 2,
        "idQuestion": 42,
        "value": "Londres",
        "valid": null
      },
      {
        "id": 3,
        "idQuestion": 42,
        "value": "Berlin",
        "valid": null
      },
      {
        "id": 4,
        "idQuestion": 42,
        "value": "Madrid",
        "valid": null
      }
    ]
  },
  "currentIndex": 1,
  "score": 100
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnQuestionSend", (groupQuestion) => {
    console.log(`Question ${groupQuestion.currentIndex}: ${groupQuestion.question.label}`);
    // Afficher la question et les réponses
    // Note: valid est null car la bonne réponse n'est pas encore révélée
});
```

**Description** : Envoie une nouvelle question à un joueur. Le champ `valid` des réponses est `null` pour ne pas révéler la bonne réponse.

---

### 8. OnQuestionAnswerSend

**Nom de l'événement** : `OnQuestionAnswerSend`

**Données reçues** :
```json
{
  "question": {
    "id": 42,
    "label": "Quelle est la capitale de la France ?",
    "idDifficulty": 1,
    "difficulty": {
      "id": 1,
      "label": "Facile"
    },
    "answer": [
      {
        "id": 1,
        "idQuestion": 42,
        "value": "Paris",
        "valid": true
      },
      {
        "id": 2,
        "idQuestion": 42,
        "value": "Londres",
        "valid": false
      },
      {
        "id": 3,
        "idQuestion": 42,
        "value": "Berlin",
        "valid": false
      },
      {
        "id": 4,
        "idQuestion": 42,
        "value": "Madrid",
        "valid": false
      }
    ]
  },
  "currentIndex": 1,
  "score": 100
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnQuestionAnswerSend", (groupQuestion) => {
    console.log("Réponse correcte révélée");
    // Afficher la bonne réponse (valid: true)
    // Afficher le score potentiel
});
```

**Description** : Envoie la question avec les bonnes réponses révélées (champ `valid` renseigné).

---

### 9. OnUserAnswer

**Nom de l'événement** : `OnUserAnswer`

**Données reçues** :
```json
{
  "id": 123,
  "nickName": "JoueurTest",
  "email": "joueur@exemple.com",
  "avatar": "https://...",
  "isAdmin": false,
  "isNew": false
}
```

**Exemple d'écoute** :
```javascript
connection.on("OnUserAnswer", (user) => {
    console.log(`${user.nickName} a répondu`);
    // Afficher une indication que ce joueur a répondu
});
```

**Description** : Notifie tous les autres joueurs qu'un joueur a envoyé sa réponse.

---

### 10. OnScoreUpdate

**Nom de l'événement** : `OnScoreUpdate`

**Données reçues** :
```json
[
  {
    "score": 500,
    "user": {
      "id": 123,
      "nickName": "Joueur1",
      "email": "joueur1@exemple.com",
      "avatar": "https://...",
      "isAdmin": false,
      "isNew": false
    }
  },
  {
    "score": 350,
    "user": {
      "id": 456,
      "nickName": "Joueur2",
      "email": "joueur2@exemple.com",
      "avatar": "https://...",
      "isAdmin": false,
      "isNew": false
    }
  }
]
```

**Exemple d'écoute** :
```javascript
connection.on("OnScoreUpdate", (userScores) => {
    console.log("Mise à jour des scores");
    userScores.forEach(us => {
        console.log(`${us.user.nickName}: ${us.score} points`);
    });
    // Afficher le classement
});
```

**Description** : Envoie les scores de tous les joueurs. Envoyé après chaque question si `scoreEachRound` est `true`.

---

### 11. OnPartyFinished

**Nom de l'événement** : `OnPartyFinished`

**Données reçues** :
```json
[
  {
    "score": 1500,
    "user": {
      "id": 123,
      "nickName": "Joueur1",
      "email": "joueur1@exemple.com",
      "avatar": "https://...",
      "isAdmin": false,
      "isNew": false
    }
  },
  {
    "score": 1200,
    "user": {
      "id": 456,
      "nickName": "Joueur2",
      "email": "joueur2@exemple.com",
      "avatar": "https://...",
      "isAdmin": false,
      "isNew": false
    }
  }
]
```

**Exemple d'écoute** :
```javascript
connection.on("OnPartyFinished", (userScores) => {
    console.log("Partie terminée !");
    // Afficher l'écran de fin avec le classement final
});
```

**Description** : Notifie tous les joueurs que la partie est terminée et envoie le classement final.

---

### 12. OnError

**Nom de l'événement** : `OnError`

**Données reçues** : Une chaîne de caractères (message d'erreur)

**Exemple d'écoute** :
```javascript
connection.on("OnError", (errorMessage) => {
    console.error("Erreur:", errorMessage);
    // Afficher un message d'erreur à l'utilisateur
});
```

**Description** : Notifie le client d'une erreur survenue lors de l'exécution d'une action.

---

## Flux de jeu typique

### 1. Création et configuration de la partie

```
1. L'hôte appelle POST /v1/group/create
2. L'hôte reçoit le code de la partie (ex: "ABC123")
3. L'hôte se connecte au WebSocket /group
4. L'hôte partage le code avec les autres joueurs
5. Les autres joueurs appellent POST /v1/group/join avec le code
6. Tous les joueurs connectés reçoivent OnPlayerJoined pour chaque nouveau joueur
7. L'hôte peut modifier les paramètres avec POST /v1/group/settings
8. Tous les joueurs reçoivent OnPartyUpdated
```

### 2. Démarrage de la partie

```
1. L'hôte appelle connection.invoke("StartGroupParty")
2. Tous les joueurs reçoivent OnPartyStarted
3. Tous les joueurs reçoivent OnCountdown (3, 2, 1...)
4. Chaque joueur reçoit OnQuestionSend avec la première question
```

### 3. Réponse à une question

```
1. Le joueur sélectionne une réponse
2. Le joueur appelle connection.invoke("SendAnswer", answerId)
3. Les autres joueurs reçoivent OnUserAnswer
4. Après le délai de réponse, tous les joueurs reçoivent OnQuestionAnswerSend (avec valid renseigné)
5. Si scoreEachRound est true, tous les joueurs reçoivent OnScoreUpdate
6. Le processus recommence avec OnCountdown pour la question suivante
```

### 4. Fin de la partie

```
1. Après la dernière question, tous les joueurs reçoivent OnPartyFinished
2. L'écran de résultats affiche le classement final
```

---

## Exemple d'implémentation complète (JavaScript)

```javascript
// Configuration de la connexion
const API_BASE_URL = "https://votre-domaine.com/api/v1";
const HUB_URL = "https://votre-domaine.com/group";
let jwtToken = ""; // À récupérer après authentification

// Connexion au hub
const connection = new signalR.HubConnectionBuilder()
    .withUrl(HUB_URL, {
        accessTokenFactory: () => jwtToken
    })
    .withAutomaticReconnect()
    .build();

// Enregistrement des événements
connection.on("OnPlayerJoined", (user) => {
    console.log(`${user.nickName} a rejoint`);
    addPlayerToUI(user);
});

connection.on("OnPlayerLeft", (user) => {
    console.log(`${user.nickName} est parti`);
    removePlayerFromUI(user);
});

connection.on("OnPartyUpdated", (party) => {
    updatePartySettingsUI(party);
});

connection.on("OnPartyStarted", (party) => {
    showGameScreen();
});

connection.on("OnCountdown", (seconds) => {
    showCountdown(seconds);
});

connection.on("OnQuestionSend", (groupQuestion) => {
    displayQuestion(groupQuestion);
});

connection.on("OnQuestionAnswerSend", (groupQuestion) => {
    revealCorrectAnswer(groupQuestion);
});

connection.on("OnUserAnswer", (user) => {
    showUserAnswered(user);
});

connection.on("OnScoreUpdate", (userScores) => {
    updateScoreboard(userScores);
});

connection.on("OnPartyFinished", (userScores) => {
    showFinalResults(userScores);
});

connection.on("OnError", (errorMessage) => {
    alert("Erreur: " + errorMessage);
});

// Démarrer la connexion
await connection.start();
console.log("Connecté au hub");

// Créer une partie
async function createParty() {
    const response = await fetch(`${API_BASE_URL}/group/create`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${jwtToken}`,
            "Content-Type": "application/json"
        }
    });
    
    const party = await response.json();
    console.log(`Partie créée avec le code: ${party.code}`);
    return party;
}

// Rejoindre une partie
async function joinParty(code) {
    const response = await fetch(`${API_BASE_URL}/group/join`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${jwtToken}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ code: code })
    });
    
    const party = await response.json();
    return party;
}

// Modifier les paramètres
async function updateSettings(themes, difficulties, nbQuestions, scoreEachRound) {
    await fetch(`${API_BASE_URL}/group/settings`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${jwtToken}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            themes: themes,
            difficulties: difficulties,
            nbQuestions: nbQuestions,
            scoreEachRound: scoreEachRound
        })
    });
}

// Démarrer la partie
async function startParty() {
    await connection.invoke("StartGroupParty");
}

// Envoyer une réponse
async function sendAnswer(answerId) {
    await connection.invoke("SendAnswer", answerId);
}

// Quitter la partie
async function leaveParty() {
    await fetch(`${API_BASE_URL}/group/leave`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${jwtToken}`
        }
    });
    
    await connection.stop();
}
```

---

## Objets de données principaux

### User
```typescript
interface User {
    id: number;
    nickName: string;
    email: string;
    avatar: string;
    isAdmin: boolean;
    isNew: boolean;
}
```

### GroupParty
```typescript
interface GroupParty {
    id: string;  // GUID
    code: string;
    nbQuestions: number;
    inProgress: boolean;
    scoreEachRound: boolean;
    idPartyType: number;
    idUserHost: number;
    active: boolean;
    finish: boolean;
    dt: string;  // ISO 8601 date
    partyUsers: PartyUser[];
    partyTheme: PartyTheme[];
    partyDifficulty: PartyDifficulty[];
    percent: number;
    score: number;
    time: number;
}
```

### GroupQuestion
```typescript
interface GroupQuestion {
    question: Question;
    currentIndex: number;  // Index de la question (commence à 1)
    score: number;  // Score potentiel pour cette question
}
```

### Question
```typescript
interface Question {
    id: number;
    label: string;
    idDifficulty: number;
    difficulty: Difficulty;
    answer: Answer[];
}
```

### Answer
```typescript
interface Answer {
    id: number;
    idQuestion: number;
    value: string;
    valid: boolean | null;  // null si non révélé, true/false si révélé
}
```

### UserScore
```typescript
interface UserScore {
    score: number;
    user: User;
}
```

---

## Notes importantes

1. **Authentification** : Tous les appels API et la connexion WebSocket nécessitent un token JWT valide.

2. **Auto-reconnexion** : Utilisez `.withAutomaticReconnect()` pour gérer automatiquement les déconnexions.

3. **Gestion des erreurs** : Toujours écouter l'événement `OnError` pour gérer les erreurs serveur.

4. **Ordre des événements** : Les événements sont envoyés dans un ordre précis pendant le jeu. Respectez cet ordre dans votre implémentation.

5. **Valid=null** : Dans `OnQuestionSend`, le champ `valid` des réponses est `null`. Il est renseigné uniquement dans `OnQuestionAnswerSend`.

6. **ScoreEachRound** : Si `false`, les scores ne sont envoyés qu'à la fin de la partie via `OnPartyFinished`. Si `true`, ils sont envoyés après chaque question via `OnScoreUpdate`.

7. **Hôte de la partie** : Seul l'hôte (idUserHost) peut démarrer la partie et modifier les paramètres.

8. **Code de partie** : Le code est généré automatiquement à la création et permet aux autres joueurs de rejoindre.

---

## Résumé pour l'IA générative

Pour implémenter un client de jeu de groupe :

1. **Authentifiez** l'utilisateur et récupérez un token JWT
2. **Créez ou rejoignez** une partie via les endpoints REST
3. **Connectez-vous** au WebSocket SignalR à `/group` avec le token
4. **Enregistrez tous les événements** listés ci-dessus
5. **Affichez l'interface** en fonction des événements reçus
6. **Invoquez** `StartGroupParty` (hôte uniquement) pour démarrer
7. **Invoquez** `SendAnswer` pour répondre aux questions
8. **Gérez** la déconnexion et les erreurs proprement

Bonne chance avec votre implémentation ! 🎮
