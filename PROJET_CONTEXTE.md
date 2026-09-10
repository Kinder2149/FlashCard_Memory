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

Points ouverts à trancher avant codage (ne pas supposer) :
- A2 : règle de génération d'ID pour une carte créée directement dans l'app (le principe V1 « ID pré-rempli dans le template » ne couvre pas ce cas).
- A4 : résolution de conflit quand une carte est modifiée dans l'app ET dans un fichier importé (V1 n'avait pas cette notion, le Sheet écrasait toujours).
- B1 : format de la colonne « langue » dans le modèle Excel et définition exacte d'une « paire ».

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
