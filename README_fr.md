# Tableau de bord du marché d'applications HarmonyOS

Dépôt du front-end HarmonyOS. Le projet global est un écosystème multi-plateforme piloté par un back end Rust, comprenant des éditions HarmonyOS, iOS, Android et Web ; ce dépôt ne contient que le front-end HarmonyOS.

Le nom de bundle actuel de l'application est `top.rayawa.dashboard`, la version actuelle est `3.0.0` (build `30000001`), et le module principal utilise le modèle Stage de HarmonyOS.

[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2023%2B-blue)](#)
[![Languages](https://img.shields.io/badge/Language-ArkTS%20%7C%20Rust-orange)](#)
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform%20Backend-lightgrey)](#)

## Positionnement du projet

Le tableau de bord du marché d'applications HarmonyOS sert à agréger et afficher les données du marché d'applications HarmonyOS, tout en fournissant des capacités de recherche d'applications, de soumission d'applications, de liens, de partage et de paramètres utilisateur.

À l'heure actuelle, cette application assume deux responsabilités :

- En tant que client de consultation du tableau de bord, elle prend en charge l'affichage multi-sites et les interactions de page
- En tant que point d'entrée des capacités système, elle reçoit les flux de partage, de recherche, de soumission et de partage inter-appareils

## Architecture globale

L'ensemble du projet est piloté par un back end unifié, tandis que plusieurs front ends consomment les mêmes capacités de données centrales.

### Back end

Le back end est implémenté avec une pile Rust et prend en charge l'agrégation de données, l'exposition des API, l'accès à la base de données et l'orchestration côté serveur.

- Langage : Rust `Edition 2024`
- Framework Web : Axum `0.8`
- Runtime asynchrone : Tokio `1.47`
- Base de données : PostgreSQL `12+`
- Pilote de base de données : SQLx `0.8`
- Client HTTP : Reqwest `0.12`
- Sérialisation : Serde + Serde JSON + TOML
- Journalisation : Tracing + Tracing Subscriber
- Compression : Tower HTTP, avec prise en charge de Brotli, Gzip, Deflate et Zstd

### Matrice front-end

Le projet existe sous les formes front-end suivantes :

- HarmonyOS
- iOS
- Android
- Web

Ce dépôt correspond au front-end HarmonyOS.

## Ce que couvre ce dépôt

Ce dépôt implémente le client HarmonyOS avec ArkTS, ArkUI et ArkWeb, et prend principalement en charge :

- La consultation multi-sites du tableau de bord
- Les pages de recherche d'applications et les points d'entrée de recherche via partage
- Les pages de soumission d'applications et les points d'entrée de soumission via partage
- Les pages utilisateur, les pages À propos et les pages de journal
- Les paramètres locaux, les données de profil utilisateur et le cache local
- Le partage système, le partage par contact et le partage par geste aérien
- L'adaptation des flux de pages et des interactions propres à HarmonyOS

## Fonctionnalités principales

- Page d'accueil `Dashboard`
  Permet de basculer entre T site, Egui et S site, et gère le rendu WebView, la barre de navigation, la barre inférieure, l'état de chargement, la synchronisation de partage et les boutons flottants.
- Recherche d'application
  Prend en charge les recherches dans l'application, ainsi que les flux de recherche déclenchés à partir de liens partagés externes.
- Soumission d'application
  Prend en charge des flux de soumission simples et complexes, tous deux déclenchables depuis les entrées de partage système.
- Utilisateur et paramètres
  Prend en charge le pseudo, les entrées de soumission/recherche, les informations de contact et les préférences.
- Liens
  Gère de manière centralisée les sites liés et les points d'entrée vers les boutiques d'applications.
- À propos et accords
  Affiche la documentation API, les journaux de mise à jour, l'accord utilisateur et la politique de confidentialité.
- Partage distribué
  Prend en charge la feuille de partage système, le partage passif, le partage par contact et le partage par geste aérien.

## Pile technologique

- Langage : ArkTS
- UI : ArkUI
- Conteneur Web : ArkWeb
- Modèle de projet : HarmonyOS Stage Model
- Outil de build : Hvigor
- Tests : Hypium / Hamock

## Environnement d'exécution

- DevEco Studio `6.1.0+`
- SDK HarmonyOS
  Recommandé selon la configuration du projet :
  - `targetSdkVersion: 6.1.0(23)`
  - `compatibleSdkVersion: 6.1.0(23)`
- Types d'appareil : phone / tablet / 2in1
- Appareil HarmonyOS ou émulateur

## Structure du projet

```text
.
├── AppScope/                         Configuration au niveau application et ressources globales
│   ├── app.json5                     Métadonnées de l'application : bundle, version, icône, libellé, etc.
│   └── resources/                    Ressources au niveau AppScope
│       ├── base/                     Ressources partagées du thème par défaut
│       │   ├── element/              Chaînes globales et ressources similaires
│       │   └── media/                Icônes, boutons, illustrations et autres médias de l'application
│       ├── dark/                     Médias surchargés pour le mode sombre
│       │   └── media/                Ressources d'images du thème sombre
│       └── phone-*/media/            Ressources d'icônes d'application pour différentes densités d'écran
├── entry/                            Module métier principal HarmonyOS
│   ├── src/main/                     Répertoire principal des sources du module
│   │   ├── ets/                      Répertoire des sources ArkTS
│   │   │   ├── ability/              Points d'entrée UIAbility / ShareExtensionAbility
│   │   │   ├── abilityPages/         Pages autonomes lancées par les abilities
│   │   │   ├── common/               Constantes, API, types, stockage, partage et utilitaires
│   │   │   ├── component/            Composants UI réutilisables
│   │   │   ├── pages/                Pages principales et sous-pages
│   │   │   └── utils/                Utilitaires de journalisation et aides similaires
│   │   └── resources/                Ressources au niveau module
│   │       ├── base/                 Ressources par défaut
│   │       │   ├── element/          Chaînes, couleurs, dimensions et ressources similaires du module
│   │       │   ├── media/            Images et icônes utilisées par le module
│   │       │   └── profile/          Tables de routage, enregistrement des pages, configuration de sauvegarde et ressources profile similaires
│   │       ├── dark/                 Ressources du mode sombre
│   │       │   └── element/          Surcharges de couleurs du thème sombre
│   │       └── rawfile/              Ressources de fichiers bruts
│   │           ├── arkdata/utd/      Configuration UTD et fichiers de données similaires
│   │           └── knock_share_guide/Ressources brutes comme les images du guide de partage par contact
├── build-profile.json5               Configuration de build et de signature
├── hvigorfile.ts                     Point d'entrée de build Hvigor
└── oh-package.json5                  Déclaration des dépendances
```

## Détail de `entry/src/main/ets`

Il s'agit du répertoire d'implémentation principal du projet. On peut le comprendre à travers les groupes `ability`, `abilityPages`, `pages`, `component`, `common` et `utils`.

### `ability/`

Cette couche est responsable des points d'entrée système, des points d'entrée de partage et de la gestion du cycle de vie des abilities autonomes.

- `ability/entry.ets`
  Point d'entrée principal `UIAbility`. Il charge `pages/Dashboard`, gère la restauration des données de continuation et utilise `AppStorage` pour participer à la continuation inter-appareils avec l'état de navigation courant.
- `ability/submitEntry.ets`
  `UIAbility` du flux de soumission. Il reçoit les paramètres issus du partage, les stocke dans `AppStorage`, puis charge `abilityPages/complexSubmit`.
- `ability/queryEntry.ets`
  `UIAbility` du flux de recherche. Il reçoit le lien cible, l'écrit dans `AppStorage`, puis charge `abilityPages/queryWeb`.
- `ability/query.ets`
  Ability d'extension de partage pour la recherche. Elle extrait le nom de package du contenu partagé par le système, appelle l'API back end pour obtenir l'identifiant de l'application, construit le lien final de la page de recherche, puis lance `queryEntryAbility`.
- `ability/simpleSubmit.ets`
  Ability d'extension de partage pour la soumission simple. Elle n'affiche pas de formulaire complexe ; elle extrait directement le nom de package ou l'identifiant de l'application du contenu partagé et l'envoie via l'API back end.
- `ability/complexSubmit.ets`
  Ability d'extension de partage pour la soumission complexe. Elle reçoit le contenu partagé et redirige l'utilisateur vers la page de formulaire afin qu'il puisse compléter et soumettre des informations supplémentaires.

### `abilityPages/`

Cette couche contient les pages autonomes lancées directement par les abilities, généralement pour des flux structurés comme le partage et la recherche.

- `abilityPages/loading.ets`
  Page de chargement minimale utilisée par les abilities d'extension de partage pour indiquer à l'utilisateur que l'application établit une communication avec la base de données.
- `abilityPages/queryWeb.ets`
  Page Web dédiée aux abilities de recherche. Elle lit l'URL de recherche transmise par l'ability, affiche les résultats avec ArkWeb et réutilise les boutons flottants, la détection de prise en main et les interactions de la barre de progression.
- `abilityPages/complexSubmit.ets`
  Page de formulaire de soumission complexe. Elle reçoit le contenu partagé, extrait automatiquement les informations de l'application, remplit le formulaire, organise les boutons de soumission et gère la logique de sortie. C'est la page centrale du flux de soumission.
- `abilityPages/continueWeb.ets`
  Page Web de continuation. Utilisée pour les scénarios de continuation inter-appareils avec affichage de contenu Web.

### `pages/`

Cette couche contient les pages de navigation classiques de l'application.

- `pages/Dashboard.ets`
  Page d'accueil de l'application et page principale du tableau de bord. Elle gère la configuration multi-sites, plusieurs instances de `WebviewController`, la progression de chargement, les onglets inférieurs, les boutons flottants, la synchronisation de partage, l'état de continuation et l'adaptation aux dispositions en écran partagé. C'est la page centrale du client.
- `pages/friend.ets`
  Page de liens. Elle regroupe les sites communautaires, les boutiques tierces et les entrées d'applications liées, et gère soit l'ouverture de sites externes, soit le saut vers les pages de détail des boutiques d'applications.
- `pages/friendWeb.ets`
  Page de détail des liens. Elle ouvre des sites externes dans une WebView et avertit l'utilisateur que le contenu ne relève pas directement du tableau de bord, tout en conservant les capacités de partage, de défilement et de boutons flottants.
- `pages/queryWeb.ets`
  Page de recherche standard dans l'application. Elle est similaire à la page de recherche lancée par ability, mais sert à la navigation interne et affiche les résultats de recherche pour une URL donnée.
- `pages/tutorial.ets`
  Page de guidage de première utilisation. Présente aux nouveaux utilisateurs les fonctionnalités principales et le mode d'utilisation de l'application.
- `pages/user.ets`
  Page du centre utilisateur. Elle gère le nom d'utilisateur, les entrées de soumission et de recherche, les informations de contact et les panneaux de paramètres. C'est la page d'agrégation des actions et préférences utilisateur.

### `pages/user/`

Cette couche contient les sous-pages du centre utilisateur.

- `pages/user/about.ets`
  Page À propos. Elle affiche l'icône de l'application et les informations de version, et fournit des entrées vers la documentation API, les journaux de mise à jour Web, les journaux de mise à jour de l'application, l'accord utilisateur et la politique de confidentialité.
- `pages/user/aboutWeb.ets`
  Page de contenu Web de la section À propos. Elle sert à ouvrir la documentation API ou les journaux de mise à jour Web, tout en conservant le partage, la progression de chargement et les interactions flottantes.
- `pages/user/appLog.ets`
  Page du journal des mises à jour de l'application. Elle contient les changements de version intégrés et prend en charge le filtrage par `beta`, `rc` et `release`.
- `pages/user/htmlPage.ets`
  Page d'affichage HTML locale. Elle sert principalement à afficher des pages locales telles que `approve.html` et `privacy.html`, et prend aussi en charge la révocation du consentement, l'effacement de l'état local et la fermeture de l'application.

### `component/`

Cette couche contient des composants réutilisables plutôt que des pages routées autonomes, mais de nombreuses pages s'appuient sur eux pour composer leur interface.

- `component/settings.ets`
  Composant de panneau des paramètres, centralisant la gestion des préférences.
- `component/appQuery.ets`
  Composant de saisie pour la recherche.
- `component/appSubmit.ets`
  Composant de saisie pour la soumission.
- `component/contact.ets`
  Composant d'affichage des informations de contact.
- `component/submitButtons.ets`
  Groupe de boutons du flux de soumission.
- `component/queryButtons.ets`
  Groupe de boutons du flux de recherche.
- `component/confirmButtons.ets`
  Groupe de boutons d'action de confirmation.
- `component/warn.ets`
  Composant d'avertissement important ou d'accord utilisateur.
- `component/KnockShareGuideCard.ets`
  Carte de guidage pour le partage par contact.

### `common/`

Cette couche fournit la logique métier partagée et les capacités de base utilisées entre les pages.

- `common/constants.ets`
  Adresses des sites, version de l'application, UA personnalisée et autres constantes.
- `common/types.ets`
  Définitions de types.
- `common/url.ets`
  Utilitaires de construction d'URL.
- `common/utils.ets`
  Analyse de texte et logique utilitaire générale.
- `common/NaturalLanguageExtract.ets`
  Capacité d'extraction d'informations pour le flux de soumission, utilisée pour identifier les informations de l'application à partir d'une saisie en langage naturel.
- `common/DiskStorage.ets`
  Enveloppe de persistance locale.
- `common/SettingsStorage.ets`
  Enveloppe de stockage des paramètres.
- `common/profile.ets`
  Enveloppe de stockage pour les noms d'utilisateur et données de profil associées.
- `common/shareControl.ets`
  Contrôleur de partage, unifiant le partage système et le partage passif.
- `common/vibration.ets`
  Enveloppe de retour haptique.
- `common/got.ets`
  Implémentation réseau réservée / expérimentale.

### `utils/`

- `utils/Logger.ets`
  Enveloppe de journalisation utilisée par le partage et la logique commune.

## Sites principaux et configuration

Les constantes des sites principaux actuellement définies dans le code se trouvent dans `entry/src/main/ets/common/constants.ets` :

- `https://hmos.txit.top/`
- `https://shenjack.top:10003/`
- `https://shenjack.top:10003/egui/`

Si vous devez changer d'environnement ou remplacer des sites, commencez par modifier ce fichier.

## Permissions

Le module actuel déclare les permissions suivantes :

- `ohos.permission.INTERNET`
- `ohos.permission.DETECT_GESTURE`
- `ohos.permission.VIBRATE`
- `ohos.permission.DISTRIBUTED_DATASYNC`

La configuration des permissions se trouve dans `entry/src/main/module.json5`.

## Tests

Le dépôt contient déjà les répertoires de test de base :

- `entry/src/test/`
- `entry/src/ohosTest/`

Ce README ne développe pas les commandes de test, car le projet est principalement exécuté et débogué via le workflow DevEco Studio.

## Remarques connues

- Ce dépôt contient uniquement le front-end HarmonyOS et n'inclut pas le code source du back end Rust.
- `README_en.md` et `README_fr.md` sont désormais alignés sur la structure actuelle du README chinois.
- Le dépôt ne déclare pas actuellement de licence open source explicite. Si vous souhaitez le publier publiquement, ajoutez un fichier `LICENSE` et mettez à jour la déclaration dans `entry/oh-package.json5`.
