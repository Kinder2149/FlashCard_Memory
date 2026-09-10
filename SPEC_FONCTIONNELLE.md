# Flashcard — Spécification fonctionnelle V1

## Écrans

1. Accueil
2. Import
3. Paramétrage de partie
4. Jeu
5. Récap de session
6. Consultation des statistiques

### 1. Accueil
Affiche l'état de la mémoire : nombre de cartes en mémoire vs nombre d'entrées valides dans le Sheet (ex. « 47 en mémoire / 52 dans le Sheet — 5 à intégrer »).

Actions :
- Jouer — disponible seulement s'il y a au moins une carte en mémoire → Paramétrage de partie.
- Importer / mettre à jour → Import.
- Consulter les statistiques → Consultation.

### 2. Import
Deux entrées :
- Télécharger le modèle : ouvre un lien « faire une copie » du Sheet modèle. L'utilisateur obtient sa propre copie à remplir.
- Coller le lien : l'utilisateur colle le lien de publication CSV de son Sheet. Au premier import, le lien est mémorisé ; ensuite, un bouton « mettre à jour » ré-utilise le lien mémorisé sans le recoller.

Au déclenchement :
- L'application télécharge le CSV, le compare à la mémoire et applique la synchronisation (voir plus bas).
- Elle affiche un rapport d'import : nombre de cartes ajoutées, mises à jour, supprimées ; liste des ID des lignes incomplètes ignorées ; liste des ID des doublons détectés.
- Validation → retour à l'Accueil.

### 3. Paramétrage de partie
Deux réglages :
- Thème : un thème précis, ou « tout ».
- Sens : Français → Anglais, ou Anglais → Français.

Lancer → Jeu.

### 4. Jeu
- Les cartes du périmètre choisi sont présentées une par une, en ordre aléatoire, chacune une seule fois.
- Chaque carte affiche le mot dans la langue source, selon le sens choisi.
- Un champ de saisie permet à l'utilisateur d'écrire sa réponse. Ce champ est une aide à l'écriture : il n'est jamais comparé automatiquement.
- L'utilisateur valide → la réponse attendue s'affiche → un pop-up « je savais / je savais pas » → carte suivante.
- La réponse (« je savais » / « je savais pas ») met immédiatement à jour la statistique de la carte pour ce sens.
- L'utilisateur peut clôturer la session à tout moment. Les cartes non jouées ne sont pas comptées.
- Quand toutes les cartes du périmètre sont passées, la session se termine → Récap.

### 5. Récap de session
Affiche le score : bonnes réponses / cartes réellement jouées. Liste des cartes jouées avec leur résultat.

### 6. Consultation des statistiques
Liste, par thème, chaque carte avec ses deux taux de réussite : Français → Anglais et Anglais → Français.

## Synchronisation (Sheet → mémoire)

À chaque import / mise à jour, l'application prend l'état exact du Sheet et applique, ID par ID :

| Situation | Action |
|-----------|--------|
| ID rempli, absent de la mémoire | Carte intégrée |
| ID des deux côtés, contenu identique | Inchangé |
| ID des deux côtés, contenu différent | Texte mis à jour, statistiques conservées (correction) |
| ID en mémoire, absent du Sheet | Carte supprimée, statistiques supprimées |
| ID présent, correspondance incomplète | Non intégré, ID signalé dans le rapport |

Règles de validation :
- Ligne incomplète = ID rempli mais mot Français ou mot Anglais manquant. Un thème vide ne rend pas la ligne incomplète.
- Doublon = même correspondance (même mot Français + même mot Anglais) sous deux ID différents. Signalé, non bloquant : les deux cartes restent.

## Statistiques
- Chaque carte porte deux taux distincts : un pour Français → Anglais, un pour Anglais → Français.
- Taux cumulatif = nombre de « je savais » / nombre de tentatives, pour ce sens, depuis toujours.
- Score de session = bonnes réponses / cartes réellement jouées dans la session.

## Cartographie des modules — 3 couches, 16 modules

Couche Données
- D1. Récupération du CSV depuis le lien mémorisé.
- D2. Parsing du CSV en lignes structurées (ID, mot FR, mot EN, thème).
- D3. Stockage local des cartes.
- D4. Stockage local des statistiques (par carte, par sens).
- D5. Stockage du lien CSV.

Couche Logique
- L1. Moteur de synchronisation (diff Sheet ↔ mémoire).
- L2. Validation des lignes (complète / incomplète, détection des doublons).
- L3. Constitution de session (filtre thème + sens, ordre aléatoire).
- L4. Déroulé de session (carte courante, validation, auto-évaluation, clôture).
- L5. Calcul des statistiques (taux cumulatif, score de session).

Couche UI
- U1. Accueil.
- U2. Import.
- U3. Paramétrage de partie.
- U4. Jeu.
- U5. Récap de session.
- U6. Consultation des statistiques.

Total : 16 modules, sous la limite de 20.
