# Résumé fonctionnel d’EduGest

## Objet de l’application

EduGest est une application de gestion d’établissement scolaire. Le dépôt contient :

- un client Flutter, utilisable sur Android, iOS, Web, Windows, macOS et Linux ;
- une API REST Spring Boot ;
- une base de données MySQL/MariaDB (port du backend : `8003`).

L’application centralise les données administratives, pédagogiques, disciplinaires et financières d’une école.

## Accès, comptes et interface

- Affiche une page de bienvenue puis une page de connexion.
- Permet la connexion avec e-mail, mot de passe et rôle sélectionné.
- Permet l’inscription initiale d’un compte Fondateur (nom, téléphone, e-mail et mot de passe).
- Permet de créer des comptes du personnel : Proviseur, Censeur, Surveillant général, Secrétaire, Comptable et Enseignant.
- Liste les comptes du personnel et permet leur suppression depuis la gestion du staff.
- Affiche le profil connecté : identité, e-mail et rôle.
- Permet à l’utilisateur de changer son mot de passe après vérification de l’ancien.
- Fournit une navigation latérale responsive : panneau fixe sur grand écran et menu tiroir sur mobile.
- Affiche le nom de l’établissement, l’année scolaire active et l’état d’attente d’une nouvelle année dans le menu.
- Propose l’interface en français et en anglais ; le sélecteur de langue est présent dans les paramètres.
- Permet une déconnexion côté interface (retour à l’écran de connexion).

## Rôles pris en compte

Les rôles de données sont : Proviseur, Censeur, Secrétaire, Comptable, Enseignant, Fondateur, Surveillant, Surveillant général, Parent et Élève.

Le menu Flutter adapte les rubriques affichées principalement pour Proviseur, Fondateur, Censeur, Secrétaire, Comptable, Enseignant et Surveillant général :

- **Enseignant** : emploi du temps, appel, liste des élèves, saisie de notes, cahier de texte et consultation de ses publications.
- **Censeur / Surveillant général** : suivi des absences, discipline, consultation des cahiers de texte, élèves, enseignants, classes, matières et bulletins.
- **Secrétaire** : élèves, enseignants, événements, classes, matières, bulletins et paramètres.
- **Comptable** : paiements, dépenses, bulletins, emploi du temps, élèves et paramètres.
- **Proviseur / Fondateur** : tableaux de bord, gestion du personnel, élèves, enseignants, finance, années scolaires, paramètres, bulletins et autres rubriques de pilotage selon le tableau de bord utilisé.

> Les restrictions sont actuellement essentiellement appliquées dans le menu Flutter. L’API Spring autorise toutes les routes `/api/**` sans authentification ni contrôle de rôle ; ces rôles ne constituent donc pas encore une sécurité serveur.

## Tableaux de bord et pilotage

- Charge des indicateurs réels depuis l’API : nombre d’élèves, nombre de membres du staff et montants financiers encaissés.
- Affiche un tableau de bord adapté au rôle (administratif, stratégique, discipline, comptabilité, enseignant, etc.).
- Affiche, pour le tableau de bord Proviseur, l’effectif, une valeur de réussite affichée, les recettes et des activités récentes.
- Donne accès aux pages métier depuis le menu et à la page de profil depuis l’en-tête.
- Affiche une bannière lorsque l’établissement est en attente de l’ouverture d’une nouvelle année.

## Gestion de l’établissement et des années scolaires

- Consulte et modifie les informations de l’établissement : nom, adresse, téléphone, e-mail, année scolaire et dates associées.
- Charge ces informations dans un notifier partagé afin de les répercuter dans l’interface.
- Ouvre une nouvelle année académique avec libellé, date de début et date prévisionnelle d’archivage.
- Clôture l’année active et demande confirmation avant l’archivage.
- Conserve les récapitulatifs des années clôturées : période, établissement, recettes, dépenses, solde, effectifs, enseignants, leçons, examens, absences et sanctions.
- Recherche les récapitulatifs d’années par année ou établissement.
- Affiche le détail complet d’un bilan annuel.
- Génère, télécharge ou imprime un rapport PDF de bilan annuel.

## Élèves, enseignants, classes, matières et parents

### Élèves

- Liste les élèves avec recherche textuelle et filtre par classe.
- Crée et modifie une fiche élève : identité, classe, date de naissance, tuteur, coordonnées du tuteur et photo URL.
- Permet la suppression d’un élève avec confirmation dans l’interface.
- Actualise les listes depuis le serveur.

### Enseignants

- Liste les enseignants.
- Ajoute, modifie et supprime un enseignant.
- Gère nom, prénom, spécialité, e-mail, téléphone et mot de passe lors du recrutement.
- Recherche les enseignants via l’API.

### Classes et matières

- Crée et liste les classes avec niveau, capacité, description et enseignant référent.
- Supprime une classe.
- Crée, modifie, liste et supprime les matières.
- Associe un coefficient à chaque matière.

### Parents

- Le backend expose la consultation et la création de fiches parents : identité, téléphone, e-mail, adresse et élèves rattachés.
- Cette gestion des parents n’a pas d’écran Flutter dédié dans l’état actuel du projet.

## Emploi du temps et présence

- Consulte l’emploi du temps par jour, classe ou enseignant.
- Charge les enseignants, classes et matières pour faciliter la création d’un créneau.
- Crée un créneau avec jour, matière, classe, enseignant, heure de début et heure de fin.
- Supprime un créneau depuis l’emploi du temps.
- Filtre l’affichage de l’emploi du temps selon le rôle connecté.
- Détermine le cours en cours d’un enseignant à partir du jour et de l’heure courants.
- Propose une page d’appel : récupère le cours courant et les élèves de la classe, permet de marquer chaque élève présent/absent, de tout marquer présent, puis enregistre les absences.

## Pédagogie : cahier de texte, notes, examens et bulletins

### Cahier de texte

- Permet à l’enseignant de publier une leçon avec classe, matière, titre et contenu détaillé.
- Affiche l’historique de ses publications et permet de reprendre une leçon pour la modifier.
- Permet à l’administration de consulter les cahiers de texte publiés et de les filtrer par classe.

### Notes et examens

- Permet de créer/saisir une évaluation avec classe, matière, intitulé, date et coefficient.
- Charge les élèves de la classe puis permet de saisir leur note et une observation.
- Envoie les notes au backend sous forme de bordereau d’examen.
- Affiche l’historique des examens/soumissions.
- Permet d’ouvrir un bordereau reçu et de consulter les notes élève par élève.
- Exporte un bordereau de notes en PDF ou au format Excel (`.xlsx`) avec élève, note, coefficient et note finale pondérée.

### Bulletins scolaires

- Sélectionne une classe et une période (trimestre).
- Recherche un élève dans la classe.
- Agrège les évaluations et notes disponibles pour calculer la moyenne pondérée de chaque élève.
- Calcule les statistiques de classe : moyenne générale, minimum, maximum et rang.
- Affiche une appréciation selon la note.
- Intègre le total d’absences de l’élève dans le bulletin.
- Génère un aperçu détaillé : coordonnées de l’établissement, identité de l’élève, tuteur, notes par matière, coefficients, points, appréciations, moyenne, rang et absences.
- Télécharge ou imprime le bulletin en PDF.

## Vie scolaire, événements et discipline

- Crée, modifie, liste et supprime des événements (titre, catégorie, date et heure).
- Classe les événements par catégories telles que conseil, examen, réunion et cérémonie.
- Offre une vue de réception/consultation des événements pour l’administration.
- Liste les absences, avec filtre par classe.
- Signale une absence avec élève, classe, période, motif et statut justifiée/non justifiée.
- Enregistre les absences produites par l’appel.
- Liste les sanctions disciplinaires.
- Crée, modifie et supprime une sanction avec élève, type, motif et date.

## Finances

- Affiche une vue financière globale : total encaissé, total des dépenses et solde net.
- Actualise les indicateurs financiers depuis l’API.
- Enregistre un paiement d’élève : élève, montant, date, description et personne ayant enregistré l’opération.
- Liste les paiements et produit au choix un ticket thermique de 80 mm ou un reçu PDF standard au format A5.
- Enregistre une dépense : libellé, catégorie, montant, date, description et personne ayant saisi l’opération.
- Liste les dépenses et permet leur suppression.
- Expose les statistiques financières au tableau de bord et aux bilans annuels.

## Notifications

- Le backend expose les notifications non lues et le marquage d’une notification comme lue.
- L’icône de notifications est visible dans le tableau de bord Flutter, mais elle n’ouvre pas encore de liste ou de traitement dans l’interface.

## API et persistance

- L’API REST couvre les utilisateurs, élèves, enseignants, classes, parents, matières, emploi du temps, leçons, examens, notes, événements, paiements, dépenses, absences, sanctions, établissement, années académiques et notifications.
- Les données sont persistées via JPA/Hibernate dans MySQL/MariaDB ; Hibernate met à jour le schéma automatiquement.
- Le client Flutter appelle par défaut `http://localhost:8003` (ou `10.0.2.2:8003` pour l’émulateur Android si le paramètre est basculé).
- Les erreurs réseau, délais d’attente et erreurs métier de l’API sont remontés dans l’interface.

## Éléments présents mais à finaliser ou à sécuriser

- Le jeton de connexion est prévu dans le modèle de réponse, mais n’est pas utilisé pour authentifier les appels API.
- Les routes de l’API sont publiques et le CORS accepte toutes les origines : à sécuriser avant toute mise en production.
- Le bouton de notification ne réalise actuellement aucune action dans Flutter.
- Les préférences locales de notifications/langue sont affichées, mais seules les données de l’établissement sont effectivement sauvegardées par l’écran des paramètres.
- La sélection d’une photo d’élève n’est pas reliée à un stockage de fichier : la fiche utilise une URL de photo.
- La page dédiée aux parents et un véritable espace Parent/Élève ne sont pas implémentés côté Flutter malgré l’existence des rôles et de l’API parents.
- Certains tableaux de bord utilisent des valeurs d’exemple (notamment le taux de réussite et les activités récentes).
- Le routage Proviseur/Fondateur ouvre un tableau de bord qui instancie actuellement un profil de Proviseur de démonstration ; l’identité réellement connectée n’y est donc pas entièrement propagée.
