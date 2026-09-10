# Flashcard — Template Google Sheet

## Structure de l'onglet
Un seul onglet. Il est nommé par un **code fixe**, pas un nom décoratif : ce code sert à composer les ID, donc le renommer désynchroniserait toutes les cartes.
- Nom d'onglet : `EN` (nom hérité de la V1, conservé même si la colonne Langue permet maintenant d'y mettre d'autres langues — voir plus bas).

Colonnes, dans cet ordre, avec en-têtes figés :

| Colonne | En-tête | Contenu | Rempli par |
|---------|---------|---------|------------|
| A | `ID` | Identifiant figé, format `EN-1`, `EN-2`, … Pré-rempli. À ne jamais modifier ni réordonner. | Modèle |
| B | `Français` | Le mot ou l'expression dans votre langue (langue mère, réglable dans l'app). | Utilisateur |
| C | `Anglais` | La traduction en langue étrangère. | Utilisateur |
| D | `Thème` | Catégorie de la carte. Optionnel. Choisi dans une liste déroulante. | Utilisateur |
| E | `Langue` | **V2** — Code de la langue étrangère de cette ligne (ex. `EN`, `ES`, `DE`). Optionnel : laissé vide, l'app suppose l'anglais (compatibilité avec les fichiers V1). Permet de mélanger plusieurs langues dans le même fichier : l'app trie automatiquement par paire. | Utilisateur |

## Identifiants
- La colonne A est pré-remplie avec un bloc d'ID : `EN-1` à `EN-500`.
- L'utilisateur remplit les colonnes B, C, D en face des ID, dans l'ordre.
- Pour aller au-delà de 500 : recopier le motif de la colonne A vers le bas (`EN-501`, `EN-502`, …).
- Ne jamais réutiliser un ID pour un mot différent : les statistiques de l'ancien mot resteraient collées au nouveau.

## Thèmes (liste déroulante)
- La colonne D utilise une validation de données (Données → Validation des données) qui pointe vers une liste de thèmes.
- Objectif : éviter les variantes (« Animaux » / « animaux » / « Aniamux ») qui créeraient des thèmes séparés dans le jeu.
- Pour ajouter un thème : l'ajouter d'abord à la liste de référence, il devient alors sélectionnable.

## Partager le Sheet pour l'application (à faire une fois)

L'application fabrique elle-même l'adresse de données à partir du lien : il n'y a plus rien à « publier ». Il suffit de rendre le Sheet **lisible par lien**.

1. Ouvrir le Sheet → bouton **Partager**.
2. Sous « Accès général », choisir **« Tous les utilisateurs disposant du lien »**, rôle **Lecteur**.
3. **Copier le lien** (celui du bouton Partager, ou l'adresse de la barre du navigateur).
4. Coller ce lien dans l'écran d'import de l'application.

Rappels :
- Le partage est à régler **une seule fois**. Ensuite l'application relit le contenu à jour à chaque « mettre à jour ».
- Le Sheet doit rester en « disposant du lien / Lecteur ». S'il redevient privé, l'application affiche un message et ne peut plus le lire.
- L'application ne modifie jamais le Sheet. Toute correction se fait dans le Sheet, côté utilisateur.
- Alternative sans partage : remplir le **modèle Excel** et l'importer en local depuis l'appareil.
