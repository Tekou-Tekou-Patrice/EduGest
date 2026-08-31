<!--
Sync Impact Report
- Version change: (unratified template) → 1.0.0
- Modified principles:
  - [PRINCIPLE_1_NAME] → I. Qualité complète (NON-NÉGOCIABLE)
  - [PRINCIPLE_2_NAME] → II. Pratiques conventionnelles
  - [PRINCIPLE_3_NAME] → III. Fichiers sensibles protégés (NON-NÉGOCIABLE)
  - [PRINCIPLE_4_NAME] → IV. Domaine scolaire et contrôle d'accès par rôle
  - [PRINCIPLE_5_NAME] → V. Contrat Flutter ↔ Spring Boot
- Added sections:
  - Contraintes de pile et d'intégrité
  - Flux de travail et portes qualité
  - Governance (procédure d'amendement, versioning, revue de conformité)
- Removed sections: none (template placeholders replaced)
- Follow-up TODOs: none
-->

# EduGest Constitution

## Core Principles

### I. Qualité complète (NON-NÉGOCIABLE)

Chaque changement MUST livrer un travail fini, cohérent et utilisable. Une
fonctionnalité n'est pas « faite » tant que le parcours utilisateur réel n'est
pas complet : saisie, validation, persistance, affichage, erreurs, et états
vides. Les raccourcis, stubs, TODO laissés dans un chemin de production, et
les implémentations à moitié câblées sont interdits.

- MUST implémenter de bout en bout (UI Flutter + API Spring + modèle de données)
  quand le besoin traverse les deux couches.
- MUST préserver le comportement existant hors du périmètre demandé.
- MUST corriger une régression introduite avant de déclarer la tâche terminée.
- SHOULD rester simple : une solution claire et standard bat une architecture
  originale.

**Rationale :** EduGest gère scolarité, notes, finances et discipline. Un
travail incomplet ou fragile met en cause des données d'établissement.

### II. Pratiques conventionnelles

Le projet MUST suivre les usages normaux de Flutter et de Spring Boot déjà
présents dans le dépôt. N'invente pas de framework interne, de couche
d'abstraction supplémentaire, ni de pattern exotique quand le code existant
montre déjà comment faire.

- Flutter MUST rester organisé en `lib/pages`, `lib/models`, `lib/service`,
  `lib/components`, `lib/localization`.
- Spring Boot MUST rester organisé en Controller → Service → Repository,
  avec DTO pour l'API et Entity pour la persistance.
- MUST réutiliser les composants, services et conventions de nommage déjà
  en place plutôt que d'en créer de parallèles.
- MUST garder le français comme langue de l'interface et des messages
  métier visibles.
- SHOULD ajouter une dépendance seulement si le besoin n'est pas déjà
  couvert par `pubspec.yaml` ou `pom.xml`.

**Rationale :** Un projet « normal » se lit, se corrige et se reprend sans
apprendre un style unique à un contributeur.

### III. Fichiers sensibles protégés (NON-NÉGOCIABLE)

Les fichiers de build, de plateforme et d'outillage généré sont hors
périmètre par défaut. Un agent ou un contributeur MUST NOT les modifier,
les régénérer, ni les « nettoyer » sauf demande explicite et écrite du
mainteneur du dépôt.

Fichiers et chemins interdits sans demande explicite :

- Tout `build.gradle`, `build.gradle.kts`, `settings.gradle`,
  `settings.gradle.kts`, `gradle.properties`
- `android/gradle/wrapper/**`, `android/local.properties`, `android/gradlew*`
- `ios/**/*.pbxproj`, `ios/**/*.xcconfig` générés, `GeneratedPluginRegistrant.*`
- `macos/**`, `linux/**`, `windows/**` fichiers CMake, runner natif et
  registrants générés
- Répertoires `build/`, `android/build/`, `lib/Edu/target/`, caches Gradle
- Wrappers Maven (`mvnw`, `mvnw.cmd`) et fichiers `.iml`

Si un besoin semble exiger l'un de ces fichiers, MUST s'arrêter et demander
confirmation. Ne pas « corriger » un Gradle, un CMake ou un pbxproj pour
faire passer une feature applicative.

**Rationale :** Ces fichiers cassent le build Android/iOS/desktop plus
vite qu'ils ne le réparent. La demande d'origine l'interdit nommément.

### IV. Domaine scolaire et contrôle d'accès par rôle

EduGest est un système d'établissement. Chaque écran, endpoint et action
MUST respecter le rôle de l'utilisateur connecté. Les rôles canoniques
backend sont : Fondateur, Proviseur, Censeur, Secrétaire, Comptable,
Enseignant, Surveillant Général. Les rôles Flutter `parent` et `eleve`,
s'ils existent, MUST rester alignés avec le backend avant d'être exposés.

- MUST filtrer navigation, actions et données selon le rôle.
- MUST NOT divulguer notes, paiements, sanctions ou dossiers d'élèves à
  un rôle qui n'y a pas droit.
- MUST traiter les données élèves, parents et finances comme sensibles :
  pas de logs de secrets, mots de passe ou jetons.
- SHOULD conserver les libellés de rôles français déjà utilisés dans l'API
  (`Fondateur`, `Proviseur`, `Surveillant Général`, …).

**Rationale :** Le métier est l'école, pas un CRUD générique. Le rôle est
une règle produit, pas un simple label d'affichage.

### V. Contrat Flutter ↔ Spring Boot

Le client Flutter et l'API Spring Boot MUST rester un seul produit. Un
changement de champ, de route ou de rôle côté serveur MUST être reflété
dans les modèles et services Flutter (`lib/models`, `lib/service`), et
inversement.

- MUST garder les DTO Java et les modèles Dart cohérents (noms, types,
  nullabilité, enums de rôle).
- MUST passer par `lib/service/api_service.dart` (ou un service existant
  du même dossier) pour les appels réseau ; pas d'appels HTTP dispersés
  dans les pages.
- MUST NOT dupliquer le backend hors de `lib/Edu` (pas de second arbre
  Spring parallèle).
- SHOULD couvrir les contrats API critiques (auth, rôles, listes métier)
  par des tests d'intégration déjà amorcés côté Java.

**Rationale :** Un écran qui compile mais parle un JSON différent de
l'API est une régression métier, pas un détail de wiring.

## Contraintes de pile et d'intégrité

Stack de référence (ne pas remplacer sans amendement) :

- Client : Flutter (Dart 3), Material 3, `flutter_localizations`
- État / navigation déjà présents : Riverpod, go_router — les utiliser
  s'ils sont déjà câblés sur le flux touché ; ne pas forcer une migration
  globale hors demande
- Réseau / stockage : Dio, Flutter Secure Storage, sqflite
- Backend : Spring Boot dans `lib/Edu` (Controllers, Services,
  Repositories, Entities, DTOs)
- Qualité statique : `flutter_lints` via `analysis_options.yaml`

Intégrité du dépôt :

- MUST limiter les diffs au besoin demandé. Pas de reformatage de masse,
  pas de fichiers générés commités, pas de `pubspec.yaml` / `pom.xml`
  modifié sans raison fonctionnelle.
- MUST NOT exécuter `flutter create`, `gradle wrapper`, ni régénérer les
  dossiers `android/`, `ios/`, `windows/`, `linux/`, `macos/`.
- Secrets, mots de passe et clés MUST NOT entrer dans le dépôt ni dans
  les logs. Les credentials vivent dans la config locale non versionnée.
- Les assets de build (`build/`, `target/`, `.gradle`) ne sont pas du
  code source : ne pas les éditer.

## Flux de travail et portes qualité

Avant d'implémenter une fonctionnalité nouvelle : spécifier (`/speckit-specify`),
planifier (`/speckit-plan`), découper (`/speckit-tasks`), puis implémenter
(`/speckit-implement`). Un correctif local, borné, peut s'exécuter sans ce
cycle s'il ne change pas le contrat produit.

Portes avant de déclarer un travail terminé :

1. Le code compile sur la couche touchée (`dart analyze` / tests Java
   concernés).
2. Le parcours utilisateur du changement a été exercé (écran, rôle,
   erreur, vide) — pas seulement lu.
3. Aucun fichier de la liste protégée n'apparaît dans le diff.
4. Client et API restent alignés si le contrat a bougé.
5. Les lints nouveaux du fichier touché sont traités ; on n'étend pas
   le silence de linter pour masquer un problème.

Revue : tout changement MUST pouvoir être relu contre cette constitution.
Un écart (fichier protégé, rôle ignoré, feature incomplète) bloque la
livraison jusqu'à correction ou amendement documenté.

## Governance

Cette constitution prime sur les habitudes locales, les suggestions
d'outils et les préférences d'un contributeur. En cas de conflit entre
une pratique ad hoc et un principe ci-dessus, le principe l'emporte.

Amendements :

- MUST être écrits dans ce fichier, avec version, date et rationale.
- MUST suivre le versionnage sémantique :
  - MAJOR : suppression ou redéfinition incompatible d'un principe
  - MINOR : nouveau principe ou section, ou guidance matériellement
    élargie
  - PATCH : clarification, typo, précision sans changer le sens
- Un amendement qui relâche la protection des fichiers Gradle/CMake/Xcode
  MUST être explicite et justifié ; le silence ne vaut pas autorisation.
- `RATIFICATION_DATE` ne change pas. `LAST_AMENDED_DATE` est la date du
  dernier amendement réel.

Conformité :

- Les commandes Spec Kit (`specify`, `plan`, `tasks`, `implement`,
  `analyze`, `checklist`) MUST lire cette constitution et s'y conformer.
- Une revue de constitution SHOULD précéder une release ou un chantier
  qui touche l'auth, les rôles ou la pile de build.
- Les exceptions temporaires MUST être notées (quoi, pourquoi, jusqu'à
  quand) ; une exception sans date de fin est refusée.

**Version**: 1.0.0 | **Ratified**: 2026-08-21 | **Last Amended**: 2026-08-21
