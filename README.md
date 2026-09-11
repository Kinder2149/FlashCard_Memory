# Flashcard Memory

Application mobile (Android, Flutter) de révision de vocabulaire par flashcards.
Publiée sur le Play Store. En développement V2 (multi-langues, base de
données mère dans l'app, gestion manuelle des cartes).

## Documentation du projet

- [`PROJET_CONTEXTE.md`](PROJET_CONTEXTE.md) — vision, périmètre, décisions
  structurantes figées (V1 et V2).
- [`SPEC_FONCTIONNELLE.md`](SPEC_FONCTIONNELLE.md) — spécification
  fonctionnelle détaillée de la V1 (écrans, synchronisation, statistiques).
- [`TEMPLATE_GOOGLE_SHEET.md`](TEMPLATE_GOOGLE_SHEET.md) — structure du
  modèle Excel / Google Sheet attendu par l'app.

## Développement

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Stack : Flutter + Dart, état via Provider, stockage local via
`shared_preferences`. Cible Android uniquement.
