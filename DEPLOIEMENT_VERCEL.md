# Déployer EduGest en PWA sur Vercel

Le workflow GitHub Actions `.github/workflows/deploy-vercel.yml` compile
l’application Flutter pour le Web, puis envoie le résultat statique à Vercel.
Vercel ne compile donc pas Flutter lui-même.

## API EduGest sur le VPS

Le certificat HTTPS de l’API est valide pour `https://edugest.duckdns.org/`.
La PWA Flutter envoie ses appels à `/api/...` sur son propre domaine Vercel ;
la réécriture `/api/:path*` de `vercel.json` les relaie ensuite en HTTPS au VPS.
Le navigateur n’a donc pas besoin de résoudre `edugest.duckdns.org`. Android
et les applications de bureau utilisent directement cette URL HTTPS par
défaut. `EDUGEST_API_BASE_URL` reste disponible pour configurer ces clients
hors Web ; elle ne doit pas être configurée dans Vercel pour la PWA.

Le certificat seul ne garantit pas que Nginx transmet les requêtes à
l’application Java : vérifie que le bloc `server` pour `edugest.duckdns.org`
contient un `location /` avec `proxy_pass http://127.0.0.1:8003;` (ou
l’adresse réelle du serveur Java). Teste ensuite que
`https://edugest.duckdns.org/api/...` atteint bien l’API.

## Ne pas remplacer le portail administrateur

Le portail administrateur existant est servi par Spring Boot depuis
`lib/Edu/src/main/resources/static/` sur le VPS. Il partage le serveur Java
avec l’API. Garde donc `edugest.duckdns.org` et son hôte virtuel Nginx pour le
VPS : ne remplace pas sa racine, ne fais pas pointer le domaine administrateur
vers Vercel et ne remplace pas son `proxy_pass`.

La PWA Flutter est un déploiement Vercel distinct, accessible par le domaine
`*.vercel.app` fourni au projet. Les requêtes `/api/...` sont relayées par
Vercel vers `https://edugest.duckdns.org/api/...`. Ainsi, le portail
administrateur garde son URL et son hébergement actuels, tandis que les
utilisateurs ouvrent l’URL Vercel pour la PWA. Pour utiliser plus tard un
domaine personnalisé pour la PWA, il faudra un nom d’hôte distinct et le
configurer séparément dans Vercel ; ne réutilise pas le nom d’hôte du portail
administrateur.

Le backend contient déjà une configuration CORS qui accepte les origines, les
méthodes et les en-têtes des requêtes du navigateur, notamment les requêtes
`OPTIONS`. Elle autorise actuellement toutes les origines ; après validation,
il est préférable de la restreindre au domaine de production Vercel.
Vercel héberge l’application Flutter, pas le serveur Java ni sa base de
données.

## Configuration initiale

1. Créez un projet Vercel pour ce dépôt, puis liez le dépôt en local :

   ```sh
   npm install --global vercel
   vercel login
   vercel link
   ```

2. Ne configurez pas `EDUGEST_API_BASE_URL` dans Vercel : la PWA utilise son
   domaine Vercel et la réécriture `/api/...` relaie ses appels au VPS. La
   variable reste utilisable pour les builds Android et desktop, et doit
   contenir une URL HTTPS.

3. Dans le fichier `.vercel/project.json` créé par `vercel link`, récupérez
   `orgId` et `projectId`. Dans **GitHub > Settings > Secrets and variables >
   Actions**, ajoutez ces secrets :

   - `VERCEL_TOKEN` : un jeton créé dans les paramètres de votre compte Vercel ;
   - `VERCEL_ORG_ID` : la valeur `orgId` ;
   - `VERCEL_PROJECT_ID` : la valeur `projectId`.

4. Désactivez les déploiements Git automatiques du projet Vercel : le workflow
   GitHub Actions effectue le build avec Flutter installé, puis publie le
   résultat précompilé sur Vercel.

Après cette configuration, chaque push sur `main` déclenche un déploiement de
production. Vous pouvez aussi lancer le workflow manuellement depuis l’onglet
**Actions** de GitHub. L’URL `*.vercel.app` du projet fournit le HTTPS
nécessaire à l’installation de la PWA et ne change pas l’adresse du portail
administrateur sur le VPS.

## Utilisation de la PWA

- Android : ouvrir l’URL avec Chrome, puis choisir **Installer l’application**
  ou **Ajouter à l’écran d’accueil**.
- iPhone/iPad : ouvrir l’URL avec Safari, toucher **Partager**, puis **Sur
  l’écran d’accueil**.
- Sur ordinateur : utiliser l’option d’installation proposée par le navigateur,
  lorsqu’elle est disponible.

Le build Flutter comprend son service worker de cache. Les notifications Web
Firebase ne sont pas encore configurées. Le projet Firebase Web est déjà
déclaré dans `lib/firebase_options.dart` ; Firebase n’est pas requis pour
héberger l’app ni pour ses appels métier à l’API EduGest.

Pour activer les notifications push Web :

1. Dans **Firebase Console > Project settings > Cloud Messaging > Web Push
   certificates**, créez ou récupérez la clé publique VAPID.
2. Cette clé doit être passée à `FirebaseMessaging.getToken(vapidKey: ...)` ;
   l’appel Flutter actuel ne fournit pas encore cette clé.
3. Ajoutez le service worker Firebase Messaging `firebase-messaging-sw.js`
   dans `web/` et configurez-y la même application Firebase Web.
4. Sur le serveur Java, configurez un compte de service Firebase Admin avec
   `FIREBASE_SERVICE_ACCOUNT_PATH` (ou les identifiants Google Application
   Default Credentials). Gardez le fichier de compte de service sur le serveur,
   jamais dans GitHub, Vercel ou le dépôt.

La clé publique VAPID pourra être communiquée pour terminer ce branchement ;
ne transmettez jamais la clé privée ni le fichier du compte de service. Sur
iPhone, les notifications Web exigent iOS 16.4 ou ultérieur et que la PWA ait
été ajoutée à l’écran d’accueil. Le scan QR dans le navigateur dépend du
support caméra et de l’autorisation accordée au site HTTPS.
