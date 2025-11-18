# Tableau de Bord d'Application (Gallery Dashboard)

### [README Anglais](README_en.md) | [中文README](README.md)

Ce projet implémente une page de tableau de bord embarqué pour mobile avec barre de navigation, contrôles de menu, état de chargement de page et animations de retour en haut, basé sur ArkTS et ArkWeb WebView.

Les fonctionnalités principales incluent :
- Chargement, actualisation, arrêt du chargement et retour arrière des pages WebView
- Barre de navigation personnalisée (titre + entrée utilisateur + bouton menu)
- Fonctions du menu supérieur (retour, actualisation, arrêt de l'actualisation, retour en haut, changement de page)
- Barre de progression du chargement des pages
- Surveillance du défilement et effets d'animation de retour en haut
- Contrôle du mode sombre
- Autorisation du stockage DOM et configurations liées au WebView

## Sites Internes ArkWeb : [Site V2](https://hmos.txit.top/dashboard) | [Site V1](http://shenjack.top:10003/dashboard)
Remerciements : [shenjack](https://github.com/shenjackyuanjie), [2b2ttianxiu]()

## Résumé de la Structure du Projet

Fichier de page principal : `entry/src/main/ets/pages/Index.ets`

Fichiers de ressources : `AppScope/resources/base/media` | `AppScope/resources/dark/media` (mode sombre)

Composants principaux :
- V2 : Composant principal de la page Tableau de Bord
- WebviewController : Utilisé pour contrôler les comportements d'ArkWeb (actualisation, arrêt, défilement, navigation, etc.)
- TopNavBar : Fournit un style visuel et des fonctionnalités unifiés de barre de navigation globale, affichant le titre de la page, le bouton utilisateur et la barre de menu sur un flou gaussien. Améliore l'immersion et l'esthétique de la page tout en conservant les fonctionnalités globales.
- Menu : Composant de gestion unifié de la barre de menu de TopNavBar, appelé en utilisant `.bindMenu(this.Menu)`, facilitant la maintenance et l'ajout/suppression de contenu.

## Description des Fonctionnalités

### 1. Barre de Navigation Supérieure

Contient :
- Titre de la page (Tableau de Bord d'Application)
- Icône utilisateur (navigue vers la page utilisateur)
- Bouton menu (en haut à droite)

Caractéristiques de la barre de navigation :
- Positionnement fixe
- Arrière-plan flou
- Distinction en couches par rapport au contenu lors du défilement

### 2. Conteneur WebView

- `domStorageAccess(true)` : Autorise le stockage DOM
- `darkMode(this.mode)` : WebView suit le mode sombre de l'application
- `forceDarkAccess(this.access)` : Force le mode sombre
- `onPageBegin` : Début du chargement
- `onProgressChange` : Met à jour la barre de progression
- `onPageEnd` : Chargement terminé
- `onScroll` : Enregistre la distance de défilement

### 3. Barre de Progression Supérieure

Utilise le composant Progress synchronisé avec la progression du chargement.

### 4. Fonctions du Menu

- Retour : `backward()`
- Actualiser/Arrêter l'actualisation : `refresh()` / `stop()`
- Animation de retour en haut : `setInterval` + lissage cubique
- Changement de page : `router.pushUrl`

## Description des Champs d'État

`url` : URL de chargement  
`mode` : Mode sombre  
`access` : Forcer le mode sombre  
`isLoading` : État de chargement  
`progress` : Pourcentage de chargement  
`scrollY` : Position de défilement  
`NAV_HEIGHT` : Hauteur de la barre de navigation

## Logique de l'Animation de Retour en Haut

easing = 1 - (1 - progress)\^3\
newY = startY \* (1 - easing)

Animation de 60 images, 8,33 ms par image.
