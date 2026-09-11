# Flashcard — Contexte projet

## Vision
Jeu mobile de flashcards pour réviser du vocabulaire. L'utilisateur saisit ses mots et traductions dans un Google Sheet qu'il remplit au quotidien ; l'application lit ce Sheet et génère une flashcard par correspondance. L'utilisateur joue ensuite des sessions de révision et suit son taux de réussite par carte.

## Principe de fonctionnement
- Le Google Sheet est la source de vérité des correspondances. L'utilisateur le remplit.
- L'application lit le Sheet, elle n'écrit jamais dedans. Elle garde les cartes et les statistiques en local.
- À chaque mise à jour, l'application se cale sur l'état exact du Sheet.

## Statut

**V1 publiée sur le Play Store (2026-09).** Retours utilisateurs post-publication réceptionnés le 2026-09-10 → ouverture de la **V2** (voir section dédiée ci-dessous). La V1 reste la référence pour tout ce qui n'est pas explicitement changé en V2.

## Périmètre V1 (figé, historique)

Inclus :
- Un seul onglet de langues : Français / Anglais.
- Import des données depuis un lien Google Sheet partagé « disposant du lien /
  Lecteur » (lien mémorisé ; l'app construit seule l'adresse de données —
  évolution 2026-07-28 remplaçant l'ancienne publication CSV manuelle).
- Import des données depuis un fichier Excel (.xlsx) local de l'appareil (ajout
  2026-07-28, décision Kinder — voir « Décisions structurantes figées »).
- Téléchargement du modèle de Sheet via un lien « faire une copie », et
  téléchargement du modèle Excel embarqué dans l'app.
- Génération des flashcards, avec catégories (thèmes).
- Affichage de l'état de la mémoire (cartes intégrées vs entrées du Sheet).
- Jeu : choix du thème et du sens, saisie + auto-évaluation, score de session.
- Statistiques : taux de réussite par carte et par sens (cumulatif), écran de consultation.
- Jeu hors-ligne.
- Page d'aide « Comment ça marche ? » (U7, ajout 2026-07-28) accessible depuis
  l'accueil, avec un easter egg discret en pied de page.

Exclus de la V1 (certains levés en V2, voir plus bas) :
- ~~Plusieurs paires de langues / plusieurs onglets.~~ → **levé, en cours en V2 (chantier B)**.
- Script Google Apps Script (point d'accès unique à tous les onglets, écriture dans le Sheet, automatisation de la publication CSV). Toujours exclu.
- Choix du format de session (tout / thème entier / paquet de taille fixe). Toujours exclu.
- Répétition espacée (priorisation des cartes les moins réussies). Toujours exclu.
- Taux de réussite pondéré sur les dernières tentatives. Toujours exclu.

## Périmètre V2 (en cours, 2026-09-10)

Déclenché par des retours utilisateurs post-publication. Plan détaillé (missions, tests manuels) tenu en session Claude Code, pas dupliqué ici — ce fichier trace les décisions structurantes actées.

4 chantiers, séquencés A → B → D → C :
- **A. Base de données mère dans l'app** — inverse la source de vérité (voir « Décisions structurantes » ci-dessous, rupture avec la V1).
- **B. Multi-langues** — paires de langues source/cible dynamiques, dépend de A.
- **C. Identité visuelle & organisation en blocs** — indépendant, appliqué en dernier sur tous les écrans (y compris ceux créés en A/B).
- **D. Écran d'accueil pédagogique au premier lancement** — indépendant, rapide.

Ajustement post-retour (2026-09-11) : l'écran unique « Gestion des données » (chantier A1) et l'écran « Vocabulaire » (V1) ont été retirés — retour utilisateur : le premier manquait d'orientation (formulaires empilés au lieu d'un choix clair), le second faisait doublon avec « Mes cartes » (A2). Nouvelle structure d'Accueil : tuiles d'action (Jouer, Mes cartes — fusionne CRUD + consultation groupée par thème —, Statistiques, Paramètres). Paramètres = 3 blocs (Importations, Langue, Réinitialiser) ; Importations est un écran de choix explicite (3 méthodes en cartes) qui n'affiche le formulaire qu'une fois la méthode choisie.

Décisions actées (chantier B) :
- **B1** : la langue mère est un **réglage unique de l'app** (pas un champ par carte — on suppose un seul apprenant, donc une seule langue mère), réglable dans « Gestion des données ». Le modèle Excel gagne une colonne **E « Langue »** = code ISO de la langue étrangère de la ligne (ex. `EN`, `ES`, `DE`) ; vide = `EN` par défaut, pour rester compatible avec les fichiers V1 sans cette colonne. Une **paire** = (langue mère globale, valeur de la colonne Langue). L'app trie automatiquement les cartes par paire (`AppState.availablePairs`) et le paramétrage de partie propose de choisir parmi les paires disponibles avant le thème et le sens.

Décisions actées (chantier A) :
- **A2** : une carte créée dans l'app reçoit un ID dans l'espace réservé `APP-n` (auto-incrément), distinct de l'espace des ID importés (`EN-42`…) — aucune collision possible avec un futur import.
- **A4** : une carte dont l'ID commence par `APP-` n'est **jamais** supprimée par une synchronisation/import, même absente du fichier — un fichier importé ne connaît par construction jamais ces ID, donc les supprimer effacerait systématiquement tout ajout manuel. Les cartes venant d'un import précédent gardent le comportement V1 inchangé (le fichier réimporté fait foi sur son propre espace d'ID, suppression comprise). Pas de vrai « conflit de contenu » possible entre app et fichier tant qu'aucun fichier ne peut porter un ID `APP-` : le cas n'a donc pas eu besoin d'arbitrage plus poussé.

## Décisions structurantes figées
- Identité d'une carte = un ID figé, pré-rempli dans le template, composé d'un code d'onglet + un numéro (ex. `EN-42`). Permet de corriger une faute de frappe sans perdre les statistiques.
- Le Sheet est en lecture seule côté application.
- L'état « intégré / pas intégré » vit dans l'application, pas dans le Sheet.
- Le lien CSV est mémorisé après le premier import ; ensuite, « mettre à jour » ré-utilise le lien mémorisé.
- **Ajout du 2026-07-28 (décision Kinder)** : un second mode d'import est
  autorisé — un fichier Excel (.xlsx) local, choisi sur l'appareil. Objectif :
  distribuer un APK de test sans que le testeur ait à publier un Google Sheet.
  Les deux modes (lien CSV et fichier local) partagent exactement la même
  validation, la même synchronisation et le même rapport. Le modèle Excel est
  embarqué dans l'app et téléchargeable. Le fichier local n'est pas mémorisé :
  après chaque modification, le testeur le réimporte.
- **V2 (2026-09-10, décision Kinder) — inversion de la source de vérité** : à
  partir du chantier A, l'application devient la base mère (CRUD possible
  directement dans l'app), et le Sheet/Excel devient un canal d'import/export
  parmi d'autres — remplace la règle V1 « le Sheet est en lecture seule côté
  application ». Détail des règles de fusion/conflit : point ouvert A4
  ci-dessus, à trancher avant codage de A4.

## Contraintes de conception
- Architecture 3 couches uniquement : UI / Logique / Données.
- Maximum 20 modules (la V1 en compte 16, voir la spec fonctionnelle).
- Maximum 5 fichiers de documentation.
- Zéro structure créée « pour le futur » : rien dans le code ni dans le template pour les évolutions ci-dessus tant qu'elles ne sont pas lancées.
- Stack : selon `STACK_STANDARD`. Contrainte technique dérivée : un stockage local persistant (cartes + statistiques) est nécessaire pour le jeu hors-ligne.

## Audit de reprise (2026-08-06)
**Constat :**
- `lib/` compte **24 fichiers .dart** (data: 6, logic: 6, ui: 9, + app_state/models/main), contre les **16 modules annoncés** dans ce fichier — écart à vérifier (le décompte a-t-il changé de définition, ou le document est-il resté figé depuis U7 le 28/07 ?). Reste sous le plafond de 20 *modules* si "module" ≠ "fichier", à clarifier.
- **Aucun dépôt git initialisé** (`git status` → "not a git repository") alors que le projet est mature : clé de signature Android présente (`flashcard-upload.jks`), assets Play Store prêts (`store/feature-graphic.png`, `store/play-store-icon.png`, `store/privacy`). Absence de contrôle de version = risque réel de perte de travail avant publication.
- `README.md` est resté le boilerplate par défaut de `flutter create` (aucune information sur le projet réel).
- Pas de `CHANGELOG.md`.
- Pas de `graphify-out/`.

**Backlog (reprise) :**
1. Initialiser un dépôt git avant toute nouvelle session de code — projet proche de la publication Play Store, aucun filet actuel.
2. Vérifier l'écart 16 vs 24 fichiers `.dart` avec la `SPEC_FONCTIONNELLE.md` — mettre à jour l'un des deux documents pour qu'ils concordent.
3. Réécrire `README.md` avec une vraie description du projet (actuellement le README généré par défaut).
4. Créer `CHANGELOG.md` — absent malgré plusieurs décisions structurantes déjà actées (import Excel local, page d'aide U7…).
5. Initialiser `graphify-out/` avant la prochaine mission de fond — 24 fichiers Dart, cohésion inter-couches (UI/Logique/Données) pas vérifiée outillée.
6. Clarifier le statut de mise en ligne réelle : `flashcard-upload.jks` + assets Play Store présents suggèrent une publication proche ou déjà tentée — non documenté dans "Statut" (absent de ce fichier, qui n'a pas de section IDENTITÉ/Statut au format standard).
