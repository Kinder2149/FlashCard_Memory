# Graph Report - V:\DEV\PROJETS\applications_mobile\FlashCard_Memory  (2026-09-07)

## Corpus Check
- 61 files · ~83,089 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 318 nodes · 340 edges · 32 communities detected
- Extraction: 99% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_dartconvert datacards_store.dart|dart:convert data/cards_store.dart]]
- [[_COMMUNITY_build SizedBox|build SizedBox]]
- [[_COMMUNITY_main Flashcard|main Flashcard]]
- [[_COMMUNITY_csv_parser.dart cell|csv_parser.dart cell]]
- [[_COMMUNITY_import_screen.dart build|import_screen.dart build]]
- [[_COMMUNITY_Écran session|Écran session]]
- [[_COMMUNITY_Sheet Rationale|Sheet Rationale]]
- [[_COMMUNITY_game_screen.dart build|game_screen.dart build]]
- [[_COMMUNITY_help_screen.dart import_screen.dart|help_screen.dart import_screen.dart]]
- [[_COMMUNITY_dartasync qcm_game_screen.dart|dart:async qcm_game_screen.dart]]
- [[_COMMUNITY_stats_screen.dart build|stats_screen.dart build]]
- [[_COMMUNITY_vocabulary_screen.dart build|vocabulary_screen.dart build]]
- [[_COMMUNITY_help_screen.dart build|help_screen.dart build]]
- [[_COMMUNITY_models.dart DirectionStat|models.dart DirectionStat]]
- [[_COMMUNITY_qcm_builder.dart build|qcm_builder.dart build]]
- [[_COMMUNITY_csv_source.dart darttyped_data|csv_source.dart dart:typed_data]]
- [[_COMMUNITY_csv_source.dart buildDataUrl|csv_source.dart buildDataUrl]]
- [[_COMMUNITY_GeneratedPluginRegistrant.java GeneratedPluginRegistrant|GeneratedPluginRegistrant.java GeneratedPluginRegistrant]]
- [[_COMMUNITY_MainActivity.kt MainActivity|MainActivity.kt MainActivity]]
- [[_COMMUNITY_hors-ligne Stockage|hors-ligne Stockage]]
- [[_COMMUNITY_Rationale éviter|Rationale éviter]]
- [[_COMMUNITY_build.gradle.kts|build.gradle.kts]]
- [[_COMMUNITY_settings.gradle.kts|settings.gradle.kts]]
- [[_COMMUNITY_build.gradle.kts|build.gradle.kts]]
- [[_COMMUNITY_Vision Flashcard|Vision Flashcard]]
- [[_COMMUNITY_modèle Téléchargement|modèle Téléchargement]]
- [[_COMMUNITY_Génération flashcards|Génération flashcards]]
- [[_COMMUNITY_Page d'aide|Page d'aide]]
- [[_COMMUNITY_Exclusions multi-langues,|Exclusions multi-langues,]]
- [[_COMMUNITY_Architecture couches|Architecture couches]]
- [[_COMMUNITY_Maximum fichiers|Maximum fichiers]]
- [[_COMMUNITY_Zéro structure|Zéro structure]]

## God Nodes (most connected - your core abstractions)
1. `../models.dart` - 18 edges
2. `package:flutter/material.dart` - 10 edges
3. `package:provider/provider.dart` - 9 edges
4. `../app_state.dart` - 9 edges
5. `6 écrans : Accueil, Import, Paramétrage de partie, Jeu, Récap de session, Consultation des statistiques` - 7 edges
6. `dart:math` - 6 edges
7. `Audit de reprise du 2026-08-06` - 6 edges
8. `package:shared_preferences/shared_preferences.dart` - 5 edges
9. `package:flutter_test/flutter_test.dart` - 5 edges
10. `Import via lien Google Sheet partagé (Lecteur), adresse construite par l'app` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Total : 16 modules, sous la limite de 20` --conceptually_related_to--> `Écart constaté : 24 fichiers .dart vs 16 modules annoncés`  [AMBIGUOUS]
  SPEC_FONCTIONNELLE.md → PROJET_CONTEXTE.md
- `Partage du Sheet : « Tous les utilisateurs disposant du lien », rôle Lecteur` --references--> `Import via lien Google Sheet partagé (Lecteur), adresse construite par l'app`  [EXTRACTED]
  TEMPLATE_GOOGLE_SHEET.md → PROJET_CONTEXTE.md
- `Total : 16 modules, sous la limite de 20` --conceptually_related_to--> `Maximum 20 modules`  [EXTRACTED]
  SPEC_FONCTIONNELLE.md → PROJET_CONTEXTE.md
- `README.md — boilerplate par défaut flutter create` --conceptually_related_to--> `README.md resté le boilerplate flutter create`  [INFERRED]
  README.md → PROJET_CONTEXTE.md
- `Partage du Sheet : « Tous les utilisateurs disposant du lien », rôle Lecteur` --conceptually_related_to--> `Google Sheet = source de vérité, lecture seule côté app`  [EXTRACTED]
  TEMPLATE_GOOGLE_SHEET.md → PROJET_CONTEXTE.md

## Communities

### Community 0 - "dart:convert data/cards_store.dart"
Cohesion: 0.07
Nodes (27): dart:convert, data/cards_store.dart, data/csv_parser.dart, ../data/csv_source.dart, data/link_store.dart, data/local_file_source.dart, data/stats_store.dart, _applyRows (+19 more)

### Community 1 - "build SizedBox"
Cohesion: 0.07
Nodes (27): ../app_state.dart, game_screen.dart, build, FlashcardApp, MaterialApp, build, Divider, Expanded (+19 more)

### Community 2 - "main Flashcard"
Cohesion: 0.08
Nodes (22): dart:io, dart:math, SessionBuilder, package:flashcard_memory/data/csv_parser.dart, package:flashcard_memory/data/csv_source.dart, package:flashcard_memory/data/local_file_source.dart, package:flashcard_memory/logic/qcm_builder.dart, package:flashcard_memory/logic/session_builder.dart (+14 more)

### Community 3 - "csv_parser.dart cell"
Cohesion: 0.09
Nodes (18): cell, CsvParser, answer, answerCurrent, close, GameSession, prompt, SessionCard (+10 more)

### Community 4 - "import_screen.dart build"
Cohesion: 0.09
Nodes (22): build, Card, Column, dispose, Divider, _ErrorBox, Icon, _idList (+14 more)

### Community 5 - "Écran session"
Cohesion: 0.09
Nodes (23): Aucun dépôt git initialisé malgré projet mature (clé signature Android, assets Play Store), Audit de reprise du 2026-08-06, Backlog de reprise : git, écart fichiers, README, CHANGELOG, graphify-out, statut publication, Écart constaté : 24 fichiers .dart vs 16 modules annoncés, Affichage de l'état de la mémoire (cartes intégrées vs entrées Sheet), Jeu : choix thème/sens, saisie + auto-évaluation, score de session, Maximum 20 modules, Pas de CHANGELOG.md (+15 more)

### Community 6 - "Sheet Rationale"
Cohesion: 0.11
Nodes (20): Les deux modes d'import partagent validation, synchronisation et rapport identiques, Le fichier local n'est pas mémorisé, réimport après chaque modification, Google Sheet = source de vérité, lecture seule côté app, Identité d'une carte = ID figé (code onglet + numéro, ex. EN-42), Import fichier Excel (.xlsx) local de l'appareil, Import via lien Google Sheet partagé (Lecteur), adresse construite par l'app, Lien CSV mémorisé après premier import, Rationale : permet de corriger une faute de frappe sans perdre les statistiques (+12 more)

### Community 7 - "game_screen.dart build"
Cohesion: 0.11
Nodes (18): build, Container, didUpdateWidget, dispose, _face, _FlipCard, _FlipCardState, GameScreen (+10 more)

### Community 8 - "help_screen.dart import_screen.dart"
Cohesion: 0.11
Nodes (17): help_screen.dart, import_screen.dart, build, Card, _comparisonLine, HomeScreen, _HomeScreenState, initState (+9 more)

### Community 9 - "dart:async qcm_game_screen.dart"
Cohesion: 0.11
Nodes (17): dart:async, build, Container, dispose, _goRecap, _OptionButton, _optionsFor, OutlinedButton (+9 more)

### Community 10 - "stats_screen.dart build"
Cohesion: 0.15
Nodes (12): build, _CardRow, Column, Container, Divider, ExpansionTile, _modeBlock, Padding (+4 more)

### Community 11 - "vocabulary_screen.dart build"
Cohesion: 0.17
Nodes (11): build, Column, Divider, Icon, Padding, _PairRow, Scaffold, SizedBox (+3 more)

### Community 12 - "help_screen.dart build"
Cohesion: 0.18
Nodes (10): build, Card, Center, HelpScreen, _HiddenEggTrigger, Scaffold, _Section, _showEgg (+2 more)

### Community 13 - "models.dart DirectionStat"
Cohesion: 0.25
Nodes (7): DirectionStat, Flashcard, fromCode, ImportReport, RawRow, register, sameContentAs

### Community 14 - "qcm_builder.dart build"
Cohesion: 0.25
Nodes (7): build, _distance, distinctTargetCount, isAvailable, QcmBuilder, QcmOptions, _target

### Community 15 - "csv_source.dart dart:typed_data"
Cohesion: 0.29
Nodes (6): csv_source.dart, dart:typed_data, cell, CsvSourceException, LocalFileSource, package:excel/excel.dart

### Community 16 - "csv_source.dart buildDataUrl"
Cohesion: 0.33
Nodes (5): buildDataUrl, CsvSource, CsvSourceException, toString, package:http/http.dart

### Community 17 - "GeneratedPluginRegistrant.java GeneratedPluginRegistrant"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 18 - "MainActivity.kt MainActivity"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 19 - "hors-ligne Stockage"
Cohesion: 1.0
Nodes (2): Jeu hors-ligne, Stockage local persistant (cartes + statistiques) requis pour jeu hors-ligne

### Community 20 - "Rationale éviter"
Cohesion: 1.0
Nodes (2): Rationale : éviter les variantes orthographiques qui créeraient des thèmes séparés, Colonne Thème : liste déroulante via validation de données

### Community 21 - "build.gradle.kts"
Cohesion: 1.0
Nodes (0): 

### Community 22 - "settings.gradle.kts"
Cohesion: 1.0
Nodes (0): 

### Community 23 - "build.gradle.kts"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Vision Flashcard"
Cohesion: 1.0
Nodes (1): Vision Flashcard : jeu mobile de révision de vocabulaire via Google Sheet

### Community 25 - "modèle Téléchargement"
Cohesion: 1.0
Nodes (1): Téléchargement du modèle de Sheet (lien copie) et modèle Excel embarqué

### Community 26 - "Génération flashcards"
Cohesion: 1.0
Nodes (1): Génération des flashcards avec catégories (thèmes)

### Community 27 - "Page d'aide"
Cohesion: 1.0
Nodes (1): Page d'aide « Comment ça marche ? » (U7) avec easter egg

### Community 28 - "Exclusions multi-langues,"
Cohesion: 1.0
Nodes (1): Exclusions V1 : multi-langues, Apps Script, choix format session, répétition espacée, taux pondéré

### Community 29 - "Architecture couches"
Cohesion: 1.0
Nodes (1): Architecture 3 couches : UI / Logique / Données

### Community 30 - "Maximum fichiers"
Cohesion: 1.0
Nodes (1): Maximum 5 fichiers de documentation

### Community 31 - "Zéro structure"
Cohesion: 1.0
Nodes (1): Zéro structure créée pour le futur

## Ambiguous Edges - Review These
- `Écart constaté : 24 fichiers .dart vs 16 modules annoncés` → `Total : 16 modules, sous la limite de 20`  [AMBIGUOUS]
  SPEC_FONCTIONNELLE.md · relation: conceptually_related_to

## Knowledge Gaps
- **245 isolated node(s):** `MainActivity`, `AppState`, `load`, `CsvSourceException`, `_applyRows` (+240 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `MainActivity.kt MainActivity`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `hors-ligne Stockage`** (2 nodes): `Jeu hors-ligne`, `Stockage local persistant (cartes + statistiques) requis pour jeu hors-ligne`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Rationale éviter`** (2 nodes): `Rationale : éviter les variantes orthographiques qui créeraient des thèmes séparés`, `Colonne Thème : liste déroulante via validation de données`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `build.gradle.kts`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `settings.gradle.kts`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `build.gradle.kts`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Vision Flashcard`** (1 nodes): `Vision Flashcard : jeu mobile de révision de vocabulaire via Google Sheet`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `modèle Téléchargement`** (1 nodes): `Téléchargement du modèle de Sheet (lien copie) et modèle Excel embarqué`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Génération flashcards`** (1 nodes): `Génération des flashcards avec catégories (thèmes)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Page d'aide`** (1 nodes): `Page d'aide « Comment ça marche ? » (U7) avec easter egg`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Exclusions multi-langues,`** (1 nodes): `Exclusions V1 : multi-langues, Apps Script, choix format session, répétition espacée, taux pondéré`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Architecture couches`** (1 nodes): `Architecture 3 couches : UI / Logique / Données`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Maximum fichiers`** (1 nodes): `Maximum 5 fichiers de documentation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Zéro structure`** (1 nodes): `Zéro structure créée pour le futur`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Écart constaté : 24 fichiers .dart vs 16 modules annoncés` and `Total : 16 modules, sous la limite de 20`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `../models.dart` connect `csv_parser.dart cell` to `dart:convert data/cards_store.dart`, `build SizedBox`, `main Flashcard`, `import_screen.dart build`, `game_screen.dart build`, `dart:async qcm_game_screen.dart`, `stats_screen.dart build`, `vocabulary_screen.dart build`, `qcm_builder.dart build`, `csv_source.dart dart:typed_data`?**
  _High betweenness centrality (0.291) - this node is a cross-community bridge._
- **Why does `dart:math` connect `main Flashcard` to `dart:convert data/cards_store.dart`, `qcm_builder.dart build`, `game_screen.dart build`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `help_screen.dart build` to `build SizedBox`, `import_screen.dart build`, `game_screen.dart build`, `help_screen.dart import_screen.dart`, `dart:async qcm_game_screen.dart`, `stats_screen.dart build`, `vocabulary_screen.dart build`?**
  _High betweenness centrality (0.109) - this node is a cross-community bridge._
- **What connects `MainActivity`, `AppState`, `load` to the rest of the system?**
  _245 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `dart:convert data/cards_store.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `build SizedBox` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._