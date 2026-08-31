# Dashboard d’applications pour HarmonyOS

Ce dépôt contient le client natif HarmonyOS de `harmony_get_market`. Il utilise les API `/api/v0` du back-end Rust et conserve l’entrée ArkWeb du site S.

- Bundle : `top.rayawa.dashboard`
- Version : `3.0.0`
- Build : `30000005`
- SDK cible et compatible : HarmonyOS `6.1.0(23)` (API 23)
- Appareils : téléphone, tablette et 2in1
- Branche de développement : `v3.0.0(23)`, issue de `shenjack`

## Interface de la version 3

La racine utilise `HdsNavigation`, les pages enfants utilisent `HdsNavDestination`, et cinq onglets sont réunis dans un `HdsTabs` à titre fixe. La barre inférieure ne se masque plus automatiquement et ne reçoit plus de taille manuelle :

1. Site Web S — comportement ArkWeb existant.
2. Accueil — bienvenue, état, totaux exacts du marché, nombre d’applications et dernières applications ajoutées.
3. Recherche — recherche, soumission simple, mise à jour query et unique entrée de partage système. Tous les résultats sont affichés en colonnes de 20 éléments avec défilement horizontal ; la mise à jour d’une application existante reste silencieuse.
4. Détails des applications — un segment fixe permet de basculer entre l’aperçu natif et la liste paginée, triable et défilable de 20/50/100 lignes.
5. Mon espace — icône et noms, réglages, liens « Plus » restaurés et informations de version/copyright/ICP.

Les listes, recherches, liens profonds et partages utilisent un modèle natif de détail commun :

```text
Trouver l’application → charger l’API avec un état d’attente → injecter les données → afficher le modèle de détail
```

La page de détail présente des métadonnées compactes, les captures, des courbes de téléchargements et de notes avec axes, défilement horizontal, zoom et sélection de point, ainsi que la description et les nouveautés. Les trois modes de partage y sont activés avec une miniature AppIcon et l’URL `https://shenjack.top:10003/dashboard?app_id=...`.

La continuité inter-appareils mémorise l’onglet, la sous-vue Détails, la cible et la position de défilement, puis restaure `pages/Dashboard` à l’emplacement natif correspondant. Seules les versions 3.0.0 ou ultérieures acceptent cet état.

Seules les barres de titre des pages principales, à l’exception du Site Web S, offrent un bouton Tutoriel ; les pages enfants ne le dupliquent pas. Un nouvel appui sur l’onglet courant remonte la page ; pour le Site Web S, il revient à l’accueil. La version 3.0.0 réaffiche une fois l’avertissement important après mise à niveau.

## Réseau et cache

- `common/MarketApi.ets` centralise les appels API et ajoute le User-Agent de l’application à chaque requête.
- Durée de fraîcheur : accueil 5 minutes, liste 2 minutes, détails et graphiques 30 minutes.
- En cas d’échec réseau, un cache âgé de 30 jours au plus peut être utilisé avec un avertissement explicite.
- Les soumissions ne sont jamais mises en cache et les mises à jour en arrière-plan ignorent le cache frais.
- « Effacer le cache » supprime les fichiers API, le stockage ArkWeb et les cookies, sans supprimer le nom d’utilisateur ni les réglages.
- La taille totale du cache est affichée à côté de cette action.

## Organisation du code

```text
entry/src/main/ets/
├── ability/              EntryAbility et unique shareAbility
├── abilityPages/         page de chargement de la session de partage
├── common/               API, cache, état, stockage, constantes, types et utilitaires
├── component/
│   ├── charts/           graphiques natifs de l’accueil
│   └── settings.ets      réglages et gestion du cache
└── pages/
    ├── Dashboard.ets     HdsNavigation et cinq HdsTabs fixes
    ├── main/             cinq onglets principaux
    ├── detail/           destination native commune de détail
    └── more/             tutoriel, liens, documents Web, journal et accords
```

Les couleurs sont définies pour les thèmes clair et sombre. Les points de rupture sont `<600vp`, `600–839vp` et `≥840vp`. Les interactions et contenus principaux possèdent des libellés d’accessibilité en chinois.

## Compilation et validation

Ouvrez le projet avec DevEco Studio 6.1 ou plus récent et installez les SDK HarmonyOS/HMS API 23. Configurez une signature locale valide, puis vérifiez les cibles téléphone, tablette et 2in1 : réseau faible, nettoyage complet du cache, thèmes clair/sombre, points de rupture, entrée de partage unique, trois modes de partage du détail, position de continuité, défilement/saut de page du tableau et lecture par le lecteur d’écran.

Copyright © 2026 Ray Chen (Rayawa). Tous droits réservés. Enregistrement ICP : 京ICP备2025153453号.
