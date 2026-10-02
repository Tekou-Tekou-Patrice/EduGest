import 'package:flutter/material.dart';
import 'package:edugest/components/app_colors.dart';

class HelpManualPage extends StatefulWidget {
  const HelpManualPage({super.key});

  @override
  State<HelpManualPage> createState() => _HelpManualPageState();
}

class _HelpManualPageState extends State<HelpManualPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const Map<String, List<({String title, List<String> steps})>>
  _manuals = {
    'fr': [
      (
        title: '1. Comprendre EduGest et préparer son accès',
        steps: [
          'EduGest regroupe les opérations de l’établissement : administration, pédagogie, vie scolaire, finances et communication.',
          'Connectez-vous avec le courriel ou le numéro de téléphone enregistré et le mot de passe. Après la connexion, choisissez l’établissement voulu. Si le compte appartient à plusieurs établissements, le rôle et les données changent avec l’établissement sélectionné.',
          'Actualisez la liste des établissements si elle est vide. Pour un établissement auquel vous n’avez pas encore accès, demandez un code de jonction à la direction ou utilisez « Rejoindre ou créer un établissement ».',
          'Les menus dépendent du rôle et du niveau de l’établissement. L’absence d’un menu n’autorise pas à contourner les permissions : demandez au fondateur de vérifier l’adhésion et le rôle.',
          'Sur téléphone, touchez ☰ pour ouvrir la barre latérale. Sur ordinateur, elle reste visible à gauche. Utilisez l’en-tête pour changer d’établissement, ouvrir les notifications, le profil et vous déconnecter.',
        ],
      ),
      (
        title: '2. Créer un établissement — Fondateur',
        steps: [
          'Après avoir créé votre compte personnel et ouvert « Rejoindre ou créer un établissement », remplissez « Nom du nouvel établissement » et « Type d’établissement ». Choisissez exactement Primaire, Collège ou Lycée : ce choix adapte les rôles et certains libellés.',
          'Validez « Créer un établissement ». Le serveur génère automatiquement un code privé unique ; le créateur devient fondateur et arrive dans l’espace de l’établissement.',
          'Le code généré s’affiche après la création. Copiez-le ou notez-le avant de continuer et gardez-le confidentiel. Il ne donne pas, à lui seul, accès à l’école : l’administration doit d’abord enregistrer le membre et lui attribuer son rôle.',
          'Pour rejoindre un établissement existant, saisissez le code communiqué dans le champ Code de l’établissement, puis touchez « Rejoindre par code ». Le compte doit déjà avoir une adhésion créée par l’administration. N’utilisez pas la création si l’établissement existe déjà.',
        ],
      ),
      (
        title: '3. Paramétrer l’établissement et l’année scolaire',
        steps: [
          'Ouvrez Administration > Paramètres (disponible au fondateur). La fiche établissement contient : nom, code privé, libellé de l’année scolaire, date de début du cycle, date prévue d’archivage, adresse, téléphone et courriel. Remplissez les coordonnées exactes et enregistrez.',
          'Le proviseur peut consulter la fiche et certains réglages, mais le code privé est réservé au fondateur. Les réglages de notification activent ou désactivent les notifications sur cet appareil.',
          'L’année scolaire active est affichée dans l’en-tête. Avant la clôture, vérifiez les listes, les évaluations, les bulletins et les données financières. La commande de clôture archive l’année : elle n’est pas une simple actualisation.',
          'À la période suivante, choisissez « Ouvrir une nouvelle année », renseignez le libellé (par exemple 2026-2027), la date de début et la date d’archivage prévue, puis confirmez. Vérifiez ensuite l’année affichée avant de saisir les nouvelles données.',
          'La section abonnement présente les informations de paiement communiquées par le service. Suivez les instructions affichées et conservez la preuve de paiement selon la procédure de l’établissement.',
        ],
      ),
      (
        title: '4. Créer les classes, matières et emplois du temps',
        steps: [
          'Commencez par créer les matières dans Administration > Gestion des matières. Pour chaque matière, saisissez son nom et son coefficient numérique (1 par défaut si aucun autre coefficient n’est requis), puis validez. Corrigez ou supprimez une matière uniquement après vérification de son utilisation.',
          'Créez les enseignants et les classes avant de bâtir l’emploi du temps, afin que les listes de sélection soient disponibles.',
          'Dans Administration > Gestion des classes, saisissez le nom de classe (ex. 6e A ou CM2), le niveau, la capacité, les frais de scolarité si utilisés, et une description facultative. Activez « Classe d’examen » uniquement si elle doit être suivie comme telle ; associez ensuite le ou les enseignants proposés et enregistrez.',
          'Dans Emploi du temps, sélectionnez le jour puis « Ajouter un créneau ». Choisissez la matière, la classe et l’enseignant dans les listes, puis l’heure de début et l’heure de fin. Vérifiez que le créneau et les associations sont corrects avant de l’enregistrer. Répétez pour chaque cours/jour.',
        ],
      ),
      (
        title: '5. Gérer le personnel et inscrire un élève',
        steps: [
          'Dans Administration > Gestion du personnel, le fondateur, le proviseur ou le secrétaire autorisé choisit « Ajouter un membre ». Saisissez le nom complet, le téléphone, le courriel professionnel, un mot de passe temporaire et le poste proposé dans la liste. Le primaire propose notamment direction, secrétariat, comptabilité et maître/maîtresse ; le collège et le lycée proposent aussi les postes pédagogiques et de surveillance disponibles.',
          'Transmettez au membre ses identifiants par un canal privé et demandez-lui de se connecter puis de changer son mot de passe si cette option est disponible. Le poste choisi détermine les menus accessibles. La création de compte de personnel et la fiche enseignant pédagogique sont des parcours distincts lorsqu’ils sont proposés.',
          'Dans Élèves, choisissez « Inscrire un élève ». Renseignez prénom, nom, date de naissance, classe, nom du parent, téléphone du parent et, si connu, courriel du parent. À la création, un mot de passe temporaire pour le parent peut être fourni ; si le champ reste vide, l’application peut utiliser le numéro du parent comme mot de passe temporaire.',
          'Choisissez une classe réellement créée. Vérifiez attentivement le téléphone du parent : il permet au parent d’accéder à son espace. Enregistrez puis vérifiez la fiche. Les demandes en attente doivent être validées par un personnel autorisé en leur attribuant une classe.',
        ],
      ),
      (
        title: '6. Guide par rôle — Fondateur',
        steps: [
          'Crée l’établissement, configure l’identité, l’année, les classes, les matières et le personnel. Vérifie les effectifs, les accès et les rapports.',
          'Suit les activités scolaires et financières disponibles : élèves, enseignants, classes, emploi du temps, notes, publications de bulletins, discipline, absences, paiements, dépenses, pensions, examens, événements et rapports.',
          'Pour un nouvel exercice, clôture l’année seulement après contrôle, puis ouvre et configure l’année suivante. La clôture/archive est une opération importante.',
        ],
      ),
      (
        title: '7. Guide par rôle — Direction, censeur et secrétariat',
        steps: [
          'Proviseur (ou directeur/directrice au primaire) : supervise l’établissement, les effectifs, le personnel, les classes, les bulletins, les opérations financières autorisées et le suivi des professeurs pendant les cours. Au primaire, le rôle reste techniquement « proviseur », mais l’app affiche « Directeur/Directrice ».',
          'Censeur (collège/lycée) : suit les activités pédagogiques et les évaluations, les classes et matières, les bulletins et les fonctions de vie scolaire présentées dans son menu.',
          'Secrétaire : traite les dossiers administratifs et les opérations de personnel qui lui sont permises ; selon le niveau et la configuration, participe au suivi scolaire et aux communications.',
          'Avant de publier, valider ou modifier une donnée officielle, vérifiez l’élève, la classe, la période et l’année scolaire sélectionnés.',
        ],
      ),
      (
        title: '8. Guide par rôle — Comptable',
        steps: [
          'Dans Paiements, enregistrez soit les frais scolaires d’un élève existant (recherchez son nom ou son identifiant et sélectionnez sa fiche), soit un paiement simple avec le nom du payeur/bénéficiaire.',
          'Renseignez le montant numérique et une description explicite. Pour des frais scolaires, l’élève doit être sélectionné dans les résultats ; le montant peut être prérempli depuis les frais configurés pour sa classe : vérifiez-le toujours avant validation.',
          'Après enregistrement, vérifiez la liste et le total. Utilisez l’option de reçu pour imprimer ou exporter le justificatif dans la langue choisie.',
          'Les dépenses, pensions et états financiers ne doivent être saisis que dans l’écran correspondant et selon les règles comptables de l’établissement.',
        ],
      ),
      (
        title: '9. Guide par rôle — Enseignant / Maître ou maîtresse',
        steps: [
          'Ouvrez Emploi du temps pour voir les cours qui vous sont associés. Prévenez l’administration si un cours, une classe ou une matière manque.',
          'Utilisez Appel pour renseigner les élèves présents ou absents du cours, et Notes/Évaluations pour les évaluations que votre rôle vous permet de saisir. Vérifiez la classe et l’évaluation avant de sauvegarder.',
          'Le cahier de texte et le suivi du programme servent à documenter les cours et l’avancement. Les informations publiées peuvent être visibles par la direction ou les parents selon le parcours.',
          'Dans Présence des professeurs en cours, consultez les contrôles d’absence vous concernant et envoyez une justification quand nécessaire. Cette page n’enregistre pas votre arrivée à l’école.',
          'Dans Pointage du personnel (QR), autorisez la caméra sur le téléphone et scannez le code du jour affiché par l’établissement : le premier scan pointe l’arrivée, le second le départ.',
          'Au primaire uniquement, l’application affiche « Maître / Maîtresse » en français et « Primary Teacher » en anglais. Il s’agit du même rôle technique enseignant.',
        ],
      ),
      (
        title: '10. Guide par rôle — Surveillant général et surveillant',
        steps: [
          'Consultez l’emploi du temps et ouvrez Présence des professeurs en cours pendant les créneaux concernés. Rendez-vous physiquement dans la salle : ne marquez présent/absent qu’après vérification.',
          'Sélectionnez le résultat correct pour le cours vérifié et enregistrez présent ou absent. Le suivi est associé au cours et à la date ; il est différent du pointage de l’arrivée du personnel.',
          'Le surveillant général autorisé peut afficher le QR quotidien pour l’équipe. Chaque membre scanne le QR avec son propre compte ; ne scannez pas à la place d’un collègue.',
          'Utilisez les écrans de discipline, absences et événements uniquement pour les faits constatés et les fonctions autorisées.',
        ],
      ),
      (
        title: '11. Guide par rôle — Parent',
        steps: [
          'Connectez-vous avec le compte parent créé/associé par l’établissement. Ouvrez l’espace Parents et sélectionnez l’enfant dans la liste si plusieurs enfants y figurent.',
          'Consultez les notes publiées, absences, bulletins disponibles, programme, événements, paiements et informations d’examen. Les informations dépendent de ce que l’école a saisi ou publié.',
          'L’espace parent est principalement en lecture seule. Pour corriger une identité, un numéro, une note ou un paiement, contactez l’administration au lieu d’essayer de modifier le dossier.',
        ],
      ),
      (
        title: '12. Notes, bulletins, cours, absences et discipline',
        steps: [
          'Notes/Évaluations : sélectionnez la classe, la matière ou l’évaluation proposée, renseignez les notes et vérifiez leur association avant d’enregistrer. Les droits de saisie et de validation dépendent du rôle.',
          'Bulletins : les rôles autorisés vérifient la classe, la période et les résultats, puis utilisent le statut de publication. Un bulletin publié peut être consulté ou téléchargé par les parents si l’établissement l’a rendu disponible.',
          'Appel des élèves et présence des professeurs en salle sont deux contrôles distincts : le premier concerne les élèves d’un cours ; le second est une visite physique de la salle par un responsable autorisé.',
          'Cahier de texte / suivi du programme : renseignez les informations du cours et le contenu demandé par l’écran, puis vérifiez la classe, la matière et le cours associé avant publication.',
          'Discipline, absences et événements : recherchez ou sélectionnez la personne/classe concernée, consignez les faits demandés et vérifiez la date avant validation. N’enregistrez que des informations exactes et nécessaires.',
        ],
      ),
      (
        title: '13. Pointage QR et contrôles physiques — mode d’emploi',
        steps: [
          'Le QR de présence à l’école est distinct du contrôle en salle. Le QR est disponible à partir de 6 h selon l’heure de l’établissement. Un responsable autorisé ouvre Pointage du personnel (QR), affiche le code à l’écran ; l’ordinateur peut servir à l’afficher.',
          'Le membre du personnel ouvre la même rubrique sur un téléphone, touche Scanner le QR, accepte l’autorisation caméra et cadre le code. Attendez la confirmation d’arrivée. Au départ, rescanner le QR du jour : le deuxième pointage enregistre la sortie.',
          'Le rapport mensuel est disponible aux rôles autorisés : choisissez la période/mois et vérifiez les noms, dates et heures. Contactez la direction si un pointage est manquant ou erroné.',
          'La présence en salle est effectuée par observation humaine pendant l’heure de cours ; elle n’utilise ni QR ni le bouton de pointage arrivée/départ. Les enseignants peuvent consulter et justifier les signalements qui les concernent.',
        ],
      ),
      (
        title: '14. Hors connexion, erreurs et bonnes pratiques',
        steps: [
          'Les écrans consultés avec Internet peuvent présenter les dernières données mises en cache lorsqu’on est hors connexion. Les premières données ne peuvent pas apparaître avant une première consultation en ligne.',
          'Les saisies et modifications hors connexion ne sont pas mises en attente : attendez une connexion et vérifiez le message de confirmation avant de quitter une saisie.',
          'Le bandeau « Aucune connexion Internet » indique que l’appareil n’a pas de réseau. Si Internet fonctionne mais que le serveur est inaccessible, le bandeau demande de réessayer plus tard.',
          'En cas de liste vide, vérifiez d’abord l’établissement actif, l’année scolaire, les filtres (classe, jour, recherche), puis actualisez. Pour les accès refusés, demandez au fondateur de vérifier votre rôle.',
          'Ne partagez jamais votre mot de passe, le code privé de l’établissement, ni le QR avec une personne non autorisée. Déconnectez-vous sur un appareil partagé.',
        ],
      ),
      (
        title: '15. Guide par rôle — Élève et membre',
        steps: [
          'Le rôle Élève ou Membre n’accorde pas automatiquement les outils de gestion du personnel. Ouvrez uniquement les rubriques qui apparaissent effectivement dans votre compte.',
          'Un élève ou un membre qui ne voit pas un écran attendu doit contacter le secrétariat ou la direction pour faire vérifier l’établissement actif et le rôle attribué.',
          'Ne partagez pas le compte d’un parent ou d’un membre du personnel pour accéder à des informations qui ne sont pas autorisées à votre compte.',
        ],
      ),
    ],
    'en': [
      (
        title: '1. Understand EduGest and prepare your access',
        steps: [
          'EduGest brings together school administration, teaching, school life, finance and communication.',
          'Sign in with the registered email address or phone number and password. After signing in, choose the school you want to use. If your account belongs to multiple schools, your role and data change with the selected school.',
          'Refresh the school list if it is empty. To access an existing school, ask its management for an invitation code or use “Join or create a school”.',
          'Menus depend on your role and school level. A missing menu is not permission to bypass access controls: ask the founder to check your membership and role.',
          'On a phone, tap ☰ to open the sidebar. On desktop, it remains on the left. Use the header to switch schools, open notifications and your profile, or sign out.',
        ],
      ),
      (
        title: '2. Create a school — Founder',
        steps: [
          'Create your personal account and open “Join or create a school”. Fill in “New school name” and “School type”. Choose Primary, Middle school or High school carefully: this sets available roles and some labels.',
          'Tap “Create school”. The server automatically generates a unique private code; the creator becomes the founder and enters the school workspace.',
          'The generated code is displayed after creation. Copy or write it down before continuing and keep it confidential. The code alone does not grant access: the administration must first register the member and assign a role.',
          'To join an existing school, enter its code in the School code field and tap “Join by code”. The account must already have a membership created by the administration. Do not create a duplicate school.',
        ],
      ),
      (
        title: '3. Configure the school and school year',
        steps: [
          'Open Administration > Settings (available to the founder). The school form contains name, private code, school-year label, cycle start date, planned archive date, address, phone and email. Enter accurate contact details and save.',
          'The principal can view the school record and some settings, but the private code is reserved for the founder. Notification settings enable or disable notifications on this device.',
          'The active school year appears in the header. Before closing it, check student lists, assessments, report cards and financial records. Closing archives the year; it is not a routine refresh.',
          'For the next period, choose “Open a new year”, enter a label (for example 2026-2027), start date and planned archive date, then confirm. Check the displayed year before entering new records.',
          'The subscription section displays payment details supplied by the service. Follow the instructions shown and keep payment evidence according to the school procedure.',
        ],
      ),
      (
        title: '4. Set up classes, subjects and timetables',
        steps: [
          'First add subjects in Administration > Subject management. Enter the subject name and numeric coefficient (1 by default unless another coefficient is required), then confirm. Check usage before editing or deleting a subject.',
          'Create staff and classes before building the timetable so the selection lists are available.',
          'In Administration > Class management, enter the class name (e.g. Grade 6A or CM2), level, capacity, tuition fee if used, and optional description. Select “Exam class” only when it should be tracked as one; then assign the listed teacher or teachers and save.',
          'In Timetable, select a day and tap “Add time slot”. Choose a subject, class and teacher from the lists, then set start and end times. Verify the slot and assignments before saving. Repeat for each lesson/day.',
        ],
      ),
      (
        title: '5. Manage staff and enroll a student',
        steps: [
          'In Administration > Staff management, an authorized founder, principal or secretary taps “Add staff”. Enter full name, phone, professional email, a temporary password and a position from the list. Primary schools offer management, secretary, accountant and primary teacher roles; middle/high schools also offer the available academic and supervisor roles.',
          'Share credentials privately and ask the staff member to sign in and change the temporary password if available. The selected position determines menus. Staff account registration and the teaching-staff record are separate workflows when both are offered.',
          'In Students, tap “Register student”. Enter first name, last name, date of birth, class, parent name, parent phone and, if known, parent email. When creating the record, you may provide a temporary parent password; if left blank, the app may use the parent phone as a temporary password.',
          'Choose an existing class. Carefully verify the parent phone number, which is used for parent access. Save and review the record. Authorized staff can approve pending registrations by assigning a class.',
        ],
      ),
      (
        title: '6. Role guide — Founder',
        steps: [
          'Create the school, configure its identity and year, classes, subjects and staff. Review enrollment, access and reports.',
          'Oversee available school and finance work: students, teachers, classes, timetables, grades, report-card publication, discipline, absences, payments, expenses, tuition, exams, events and reports.',
          'Close the year only after checking the records, then open and configure the next year. Closing/archiving is an important operation.',
        ],
      ),
      (
        title: '7. Role guide — Management, academic supervisor and secretary',
        steps: [
          'Principal (displayed as School Director in primary school): oversee students, staff, classes, report cards, authorized finance and teacher classroom checks. In primary school the internal role remains “principal”, while the app displays “School Director”.',
          'Academic Supervisor (Censor, middle/high school): oversee available academic work, assessments, classes and subjects, report cards and school-life features shown in the role menu.',
          'Secretary: handle permitted administrative records and staff workflows; depending on school level and configuration, assist with school follow-up and communication.',
          'Before publishing, validating or changing an official record, check the student, class, period and active school year.',
        ],
      ),
      (
        title: '8. Role guide — Accountant',
        steps: [
          'In Payments, record either school fees for an existing student (search by name or ID and select the student) or a simple payment with the payer/recipient name.',
          'Enter a numeric amount and clear description. For school fees, select the student from the results; the amount may be prefilled from the class fee, so always verify it before confirming.',
          'After saving, check the list and total. Use the receipt option to print or export proof in the chosen language.',
          'Enter expenses, tuition and finance records only in their corresponding screens and according to the school accounting process.',
        ],
      ),
      (
        title: '9. Role guide — Teacher / Primary Teacher',
        steps: [
          'Open Timetable to see lessons assigned to you. Tell the administration if a lesson, class or subject is missing.',
          'Use Student attendance to record which students are present or absent in class, and Grades/Assessments for assessments your role may enter. Check the class and assessment before saving.',
          'The lesson book and curriculum tracking document lessons and teaching progress. Published information may be visible to management or parents depending on the workflow.',
          'In Teacher presence during lessons, review classroom absence checks concerning you and submit a justification when needed. This screen does not record arrival at school.',
          'In Staff attendance (QR), allow camera access on your phone and scan the school’s daily code: the first scan records arrival and the second records departure.',
          'In primary schools only, the teacher role is displayed as “Maître / Maîtresse” in French and “Primary Teacher” in English. It is the same internal teacher role.',
        ],
      ),
      (
        title: '10. Role guide — General supervisor and supervisor',
        steps: [
          'Check the timetable and open Teacher presence during lessons for relevant time slots. Physically visit the room; only record present/absent after checking.',
          'Select the correct lesson result and save present or absent. The check belongs to the lesson and date; it is separate from staff arrival/departure.',
          'An authorized general supervisor can display the daily QR code. Each staff member must scan it using their own account; do not scan on a colleague’s behalf.',
          'Use discipline, absences and events screens only for verified facts and permitted tasks.',
        ],
      ),
      (
        title: '11. Role guide — Parent',
        steps: [
          'Sign in with the parent account created or linked by the school. Open the Parent space and select a child if multiple children are listed.',
          'View published grades, absences, available report cards, curriculum, events, payments and exam information. The available information depends on what the school has entered or published.',
          'The parent space is primarily read-only. Contact the school to correct a name, phone number, grade or payment rather than trying to edit the record.',
        ],
      ),
      (
        title: '12. Grades, report cards, lessons, absences and discipline',
        steps: [
          'Grades/Assessments: choose the offered class, subject or assessment, enter grades and verify their association before saving. Entry and validation permissions depend on the role.',
          'Report cards: authorized roles check the class, period and results, then use the publication status. Parents can view or download a published report card when the school makes it available.',
          'Student attendance and teacher classroom presence are different: the first records students attending a lesson; the second is a physical classroom check by an authorized staff member.',
          'Lesson book/curriculum tracking: enter the lesson information requested by the screen, then verify its class, subject and lesson before publishing.',
          'Discipline, absences and events: find or select the relevant person/class, enter the requested facts and verify the date before saving. Record only accurate and necessary information.',
        ],
      ),
      (
        title: '13. QR attendance and physical checks — instructions',
        steps: [
          'School staff QR attendance is separate from classroom presence checks. The daily QR is available from 6:00 a.m. in the school’s time zone. An authorized staff member opens Staff attendance (QR) and displays the code; a computer can display it.',
          'The staff member opens the same menu on a phone, taps Scan QR, allows camera access and points the camera at the code. Wait for arrival confirmation. At departure, scan that day’s code again; the second scan records departure.',
          'Authorized roles can open the monthly report, choose a month and review names, dates and times. Contact management about missing or incorrect entries.',
          'Classroom presence is a human observation during a lesson; it does not use the QR or arrival/departure controls. Teachers can review and justify checks concerning them.',
        ],
      ),
      (
        title: '14. Offline use, errors and good practices',
        steps: [
          'Screens viewed online may show their latest locally cached data when offline. Data cannot be shown from cache until the screen has been loaded online at least once.',
          'Offline edits are not queued. Wait for a connection and check for a success message before leaving an edit screen.',
          'The “No internet connection” banner means the device has no network. If Internet works but the server cannot be reached, a separate banner asks you to try again later.',
          'If a list is empty, check the active school, school year and filters (class, day, search), then refresh. For denied access, ask the founder to check your role.',
          'Never share your password, the school private code or a QR code with unauthorized people. Sign out on shared devices.',
        ],
      ),
      (
        title: '15. Role guide — Student and member',
        steps: [
          'The Student or Member role does not automatically grant staff-management tools. Use only the sections that actually appear in your account.',
          'If a student or member cannot see an expected screen, contact the secretary or management to verify the active school and assigned role.',
          'Do not use a parent or staff member account to access information that your account is not authorized to view.',
        ],
      ),
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _sectionIcon(int index) {
    return switch (index) {
      0 => Icons.explore_outlined,
      1 => Icons.add_business_outlined,
      2 => Icons.tune_outlined,
      3 => Icons.account_tree_outlined,
      4 => Icons.groups_outlined,
      5 => Icons.workspace_premium_outlined,
      6 => Icons.admin_panel_settings_outlined,
      7 => Icons.account_balance_wallet_outlined,
      8 => Icons.menu_book_outlined,
      9 => Icons.fact_check_outlined,
      10 => Icons.family_restroom_outlined,
      11 => Icons.school_outlined,
      12 => Icons.qr_code_2_outlined,
      13 => Icons.wifi_off_outlined,
      _ => Icons.help_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final isFrench = language != 'en';
    final allSections = _manuals[isFrench ? 'fr' : 'en']!;
    final query = _query.trim().toLowerCase();
    final sections = allSections.asMap().entries.where((entry) {
      final section = entry.value;
      return query.isEmpty ||
          section.title.toLowerCase().contains(query) ||
          section.steps.any((step) => step.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isFrench ? 'Manuel d’utilisation EduGest' : 'EduGest User Guide',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 32.0;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  36,
                ),
                children: [
                  _buildWelcomeCard(context, isFrench),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: isFrench
                          ? 'Rechercher dans le manuel...'
                          : 'Search this guide...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: isFrench ? 'Effacer' : 'Clear',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isFrench ? 'Parcourir le guide' : 'Browse the guide',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Text(
                        isFrench
                            ? '${sections.length} sections'
                            : '${sections.length} sections',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (sections.isEmpty)
                    _buildEmptySearch(context, isFrench)
                  else
                    for (final entry in sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSectionCard(
                          context,
                          entry.key,
                          entry.value,
                          isFrench,
                          query,
                        ),
                      ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isFrench
                                ? 'Les champs et options peuvent varier selon les droits de votre compte. Suivez les libellés affichés dans votre application.'
                                : 'Fields and options can vary depending on your account permissions. Follow the labels shown in your app.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.text, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isFrench) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sidebarBg, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.sidebarBg.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFrench
                      ? 'Tout EduGest, expliqué simplement'
                      : 'EduGest, clearly explained',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFrench
                      ? 'Un guide global pour créer votre école, configurer les outils et comprendre chaque rôle.'
                      : 'A complete guide to creating your school, setting up tools and understanding every role.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _headerTag(
                      isFrench ? 'Tous les rôles' : 'Every role',
                      Icons.groups_2_outlined,
                    ),
                    _headerTag(
                      isFrench
                          ? 'Primaire · Collège · Lycée'
                          : 'Primary · Middle · High',
                      Icons.school_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    int index,
    ({String title, List<String> steps}) section,
    bool isFrench,
    String query,
  ) {
    final titleMatches = section.title.toLowerCase().contains(query);
    final steps = query.isEmpty || titleMatches
        ? section.steps
        : section.steps
              .where((step) => step.toLowerCase().contains(query))
              .toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        key: ValueKey('manual-section-$index-$query'),
        initiallyExpanded: query.isNotEmpty,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 20, 20),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_sectionIcon(index), color: AppColors.primary, size: 21),
        ),
        title: Text(
          section.title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            isFrench
                ? '${steps.length} étapes pratiques'
                : '${steps.length} practical steps',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context, bool isFrench) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            isFrench ? 'Aucun résultat trouvé' : 'No results found',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFrench
                ? 'Essayez un autre mot ou effacez la recherche.'
                : 'Try another word or clear your search.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
