# Dashboard d’applications

[简体中文](README.md) · [English](README_en.md) · [Français](README_fr.md)

Dashboard est le client natif de `harmony_get_market`. Il consulte les informations publiques de SDK, de version, de catégorie et de notation via les API `/api/v0` du back-end tout en conservant l’accès ArkWeb au site S.

- Nom du bundle : `top.rayawa.dashboard`
- Version : `3.0.0`
- Numéro de build : `30000005`
- Version système cible et compatible : `6.1.0(23)` (API 23)
- Appareils : téléphone, tablette et 2in1
- Branche : `v3.0.0(23)`, migrée depuis `shenjack`

## Interface de la version 3.0.0

La page racine utilise `HdsNavigation`, les pages enfants utilisent `HdsNavDestination` et quatre pages principales sont reliées par des `HdsTabs` à titre fixe. La barre inférieure ne se masque plus automatiquement et n’utilise plus de taille définie manuellement :

1. **Site S** — préchauffe et met en cache sa page ArkWeb au démarrage de l’application, puis permet de partager la page courante par le système, par contact ou par geste dans l’air. Un viewport Web indépendant maintient les fenêtres de détail flottantes dans la vue courante.
2. **Accueil** — indique que le total correspond aux applications plus les services atomiques ; sur écran large, les totaux, l’état du service et les derniers ajouts sont affichés côte à côte.
3. **Détails des applications** — regroupe en haut la recherche et le sélecteur aperçu/liste. La liste prend en charge les filtres par type et par champ, le tri et la pagination.
4. **Mon espace** — affiche l’icône et les noms de l’application, les réglages, les liens supplémentaires, la version, le copyright et les informations ICP. Le tutoriel n’est disponible qu’ici afin de ne pas le dupliquer dans la barre de titre ; « Nous contacter » ouvre une feuille semi-modale refermable.

La liste, les résultats de recherche, les liens profonds et l’entrée de partage système utilisent le même modèle natif de détail :

```text
Trouver l’application → charger l’API avec un état d’attente → injecter les données → afficher le modèle natif de détail
```

La page de détail contient un résumé, des métadonnées compactes sous forme d’étiquettes et de texte, les captures d’écran, les tendances de téléchargements et de notes, la description et les nouveautés. Les graphiques permettent de sélectionner un point, de zoomer avec deux doigts et de déplacer la vue avec un doigt. Le partage depuis cette page crée une fiche du site S accompagnée de l’icône de l’application.

La continuité inter-appareils mémorise l’onglet principal, la sous-vue Détails, la cible native et la position de défilement. L’appareil cible restaure `pages/Dashboard` avant de revenir à l’onglet ou au détail correspondant. Seule la version 3.0.0 ou ultérieure accepte le format actuel de continuité.

L’Accueil et les Détails des applications prennent en charge l’actualisation depuis le haut. Lors du partage, la barre de titre du site S lit l’URL ArkWeb courante : les trois modes de partage envoient donc toujours la page affichée. Lorsqu’une fenêtre de détail du site est ouverte, l’action Retour du système ou le geste de retour ferme d’abord cette fenêtre. Un nouvel appui sur l’onglet Site S sélectionné revient à la page d’accueil du site.

## Données, cache et réseau faible

Toutes les pages de données natives utilisent `common/MarketApi.ets` et ne construisent pas directement de requêtes HTTP. Chaque requête API inclut le même User-Agent de l’application.

- Les données de l’accueil restent fraîches 5 minutes, celles de la liste 2 minutes et celles des détails et graphiques 30 minutes.
- Une entrée de cache valide est lue directement depuis le stockage local afin de réduire l’attente au démarrage et lors de la navigation.
- Après expiration, l’application interroge le réseau ; en cas d’échec, elle peut revenir à des données en cache datant de 30 jours au plus.
- Les pages signalent clairement les données issues du cache hors ligne et affichent leur horodatage.
- Les soumissions ne sont jamais mises en cache et les mises à jour en arrière-plan d’applications existantes ignorent le cache frais.
- « Effacer le cache » supprime les fichiers API, le stockage ArkWeb et les cookies, sans supprimer le nom d’utilisateur ni les réglages.
- La taille actuelle du cache API est affichée à côté de cette action dans Mon espace → Réglages.

## Gestion des erreurs et journalisation

- Les appels liés aux fichiers, fenêtres, réseau, messages, sessions de partage et capacités facultatives disposent d’un traitement des exceptions ou des rejets.
- Les notifications passent par `common/safeUi.ets` ; l’indisponibilité temporaire du contexte d’interface est journalisée sans interrompre le flux principal.
- Les messages de console utilisent le préfixe `[Dashboard][chemin du module][niveau]` pour faciliter le filtrage.
- La fonction de prise intelligente vérifie `SystemCapability.MultimodalAwareness.Motion` et rétablit la disposition normale des boutons sur les appareils non compatibles.
- La vignette par défaut du partage système et les résultats de compatibilité des effets de vibration sont réutilisés après le premier accès afin d’éviter les lectures et requêtes répétées pendant une session.

## Réglages et capacités de l’appareil

Mon espace → Réglages enregistre le nom d’utilisateur, l’intensité des vibrations, l’effet de champ lumineux et le niveau de matériau immersif. Au démarrage, les valeurs sont hydratées depuis Preferences vers `AppStorage` ; les lectures suivantes utilisent le cache du processus, tandis que les écritures restent persistantes.

- Le nom d’utilisateur est joint aux demandes de soumission ; s’il est vide, le nom de l’appareil est utilisé.
- Les vibrations proposent les niveaux Désactivé, Dynamique et Fort. Le contrôle est masqué lorsqu’il n’existe pas de matériel de vibration.
- L’effet de champ lumineux propose les niveaux Faible, Lumineux et Haute luminosité. Le dernier dépend de la composition HDR de l’API 24 ; avec l’API 23 ou sans HDR global, l’application revient sans risque au niveau Lumineux.
- L’application déclare les autorisations réseau, état du réseau, luminosité HDR, détection de gestes et vibration. Les capacités optionnelles disposent d’un comportement de repli.

## Mise en page adaptative et accessibilité

Les pages utilisent les mêmes seuils de largeur :

- Petit écran : `< 600vp`
- Écran moyen : `600vp–839vp`
- Grand écran : `≥ 840vp`

Les cartes, graphiques et champs de détail adaptent leurs colonnes avec `GridRow/GridCol` ; la liste reste défilable horizontalement sur les écrans étroits. Les contrôles, graphiques, images, états et contenus principaux disposent de libellés chinois `accessibilityText`.

Les couleurs des thèmes sont définies dans :

- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/dark/element/color.json`

Toutes les couleurs `v3_*` possèdent une variante claire et sombre. L’arrière-plan d’attente ArkWeb du site S utilise `#EEF6FE` en mode clair et `#030712` en mode sombre.

## Répertoires principaux

```text
entry/src/main/ets/
├── ability/                  EntryAbility, page de chargement du partage et unique shareAbility
├── common/
│   ├── MarketApi.ets         client API commun
│   ├── CacheService.ets      cache de fichiers, taille et nettoyage complet
│   ├── appState.ets          état temporaire entre les Ability
│   ├── storage.ets           hydratation de Preferences et AppStorage
│   ├── safeUi.ets            appels PromptAction sûrs et repli de journalisation
│   ├── safeNavigation.ets    paramètres de route et helpers push/pop sûrs
│   ├── motion.ets            animations d’entrée et de transition partagée
│   ├── shareControl.ets      cycle de vie des partages système et reçus
│   ├── vibration.ets         vibrations courtes, retour, longues et d’erreur
│   ├── visualEffects.ets     repli de compatibilité champ lumineux et HDR
│   ├── dashboardConfig.ets   visibilité du tableau contrôlée par le serveur
│   ├── constants.ets         constantes communes
│   └── types.ets             types des API, pages et routes
├── component/
│   ├── charts/               graphiques natifs de l’accueil
│   ├── SettingsPanel.ets     réglages et gestion du cache
│   ├── WarningContent.ets    avis de premier lancement
│   └── ContactPanel.ets      contacts et actions de copie
└── pages/
    ├── Dashboard.ets         HdsNavigation et quatre HdsTabs fixes
    ├── main/
    │   ├── SStationPage.ets
    │   ├── HomePage.ets
    │   ├── SearchPage.ets
    │   ├── AppsPage.ets      page combinée aperçu/liste
    │   └── MyPage.ets
    ├── detail/               page native commune de détail
    ├── more/                 tutoriel, liens, journal, accords et développement
    └── web/WebPage.ets       destination Web distante commune
```

Consultez [ARCHITECTURE.md](ARCHITECTURE.md) pour les limites des modules, l’état, le cycle de vie et la gestion des ressources.

## Principales API

- `GET /api/v0/market_info`
- `GET /api/v0/apps/list/{page}`
- `GET /api/v0/apps/app_id/{app_id}`
- `GET /api/v0/apps/pkg_name/{pkg_name}`
- `GET /api/v0/apps/metrics/{pkg_name}`
- `GET /api/v0/rankings/rate_history?pkg_name={pkg_name}`
- `GET /api/v0/charts/rating`
- `GET /api/v0/charts/min_sdk`
- `GET /api/v0/charts/target_sdk`
- `GET /api/v0/charts/api_history`
- `POST /api/v0/submit`

Les routes réellement exposées par le back-end font foi. Consultez `API.md`, `API_DOCS.md` et `/openapi.json` dans le dépôt `harmony_get_market` pour la référence complète.

## Développement et validation

1. Ouvrez le projet avec DevEco Studio 6.1 ou une version plus récente.
2. Installez les SDK API 23 et système requis.
3. Configurez un profil de signature local valide ; les chemins absolus d’un autre poste ne peuvent pas être réutilisés directement.
4. Compilez et testez les cibles téléphone, tablette ou 2in1 sur un appareil ou un émulateur.
5. Vérifiez le repli en réseau faible, le nettoyage du cache, les thèmes clair/sombre, les seuils 600/840vp, l’unique entrée de partage reçue, les trois modes de partage sur le site S et la page de détail, la position de continuité, le défilement et le saut de page du tableau, ainsi que la lecture par le lecteur d’écran.
6. Sur les appareils avec et sans HDR et matériel de vibration, vérifiez l’affichage des réglages, les replis et l’avertissement de Haute luminosité.

## Confidentialité et mentions

Les données du marché sont collectées sur Internet et fournies à titre indicatif ; leur exactitude, leur exhaustivité et leur authenticité ne sont pas garanties. L’application utilise des informations sur l’appareil pour construire le User-Agent des requêtes et une télémétrie d’exécution anonyme. Un nom d’utilisateur explicitement défini est transmis avec les demandes de soumission. Consultez la politique de confidentialité intégrée pour plus de détails.

Copyright © 2026 Ray Chen (Rayawa). Tous droits réservés. Domaine déclaré : `rayawa.top` ; enregistrement ICP : 京ICP备2025153453号.
