# Intégration UX/UI des Dividendes Universels

## Vue d'ensemble

L'intégration des dividendes universels (DU) dans l'écran d'activité a été conçue pour être **discrète mais pratique**, suivant les principes d'UX de l'application Gecko existante.

## Emplacement et Design

### Position : AppBar
- **Localisation** : Intégré dans le `WalletAppBar` à côté des actions existantes (contact et QR code)
- **Justification** : Position familière et accessible, suit les conventions UX standard
- **Cohérence** : S'intègre naturellement dans le design existant

### Icône et États Visuels

#### État DÉSACTIVÉ (par défaut)
- **Icône** : `Icons.savings_outlined` (contour)
- **Couleur** : `onSecondaryContainer` avec 60% d'opacité (grisée)
- **Tooltip** : "Afficher les dividendes universels"

#### État ACTIVÉ
- **Icône** : `Icons.savings` (pleine)
- **Couleur** : `primary` (couleur d'accent de l'app)
- **Tooltip** : "Masquer les dividendes universels"

## Comportement UX

### Interaction
1. **Tap simple** : Bascule instantanément entre les deux états
2. **Feedback visuel** : Changement immédiat d'icône et de couleur
3. **Feedback informatif** : Tooltip explicatif au survol
4. **Pas d'animation** : Transition instantanée pour une UX fluide

### Persistance d'État
- **Session courante** : L'état est maintenu pendant la navigation
- **Rafraîchissement automatique** : Les données se rechargent automatiquement
- **Pas de stockage persistant** : Retour à l'état par défaut à chaque ouverture

## Intégration Technique

### Provider Pattern
```dart
// Watch du state pour la réactivité
final historyState = ref.watch(transactionHistoryProvider(address));
final historyNotifier = ref.read(transactionHistoryProvider(address).notifier);

// Action simple
historyNotifier.toggleUniversalDividends();
```

### Localisation
- **4 langues supportées** : FR, EN, ES, IT
- **Clés de traduction** :
  - `showUniversalDividends`
  - `hideUniversalDividends`

## Avantages UX/UI

### ✅ **Discrétion**
- Ne perturbe pas le flux utilisateur existant
- Icône familière et intuitive (`savings`)
- Taille appropriée (24px) pour ne pas dominer l'interface

### ✅ **Praticité**
- Accessible en un seul tap
- Position logique (dans les actions du wallet)
- Feedback visuel clair de l'état actuel

### ✅ **Cohérence**
- Suit les patterns de design existants
- Même logique que les autres toggles de l'app
- Couleurs et espacements conformes au design system

### ✅ **Performance**
- Aucun impact sur les performances existantes
- Chargement intelligent (seulement si activé)
- Pagination maintenue

## États d'Usage

### Utilisateur Novice
- **Par défaut** : DU masqués pour éviter la confusion
- **Découverte** : Tooltip explicatif aide à comprendre la fonction
- **Learning curve** : Aucun impact sur l'apprentissage existant

### Utilisateur Avancé
- **Accès rapide** : Toggle facilement accessible
- **Contrôle granulaire** : Peut activer/désactiver selon le contexte
- **Vue complète** : Historique enrichi quand souhaité

## Exemples d'Utilisation

### Scénario 1 : Consultation rapide
L'utilisateur veut juste voir ses transactions récentes → DU désactivés par défaut

### Scénario 2 : Analyse complète
L'utilisateur veut analyser tous ses revenus → Active les DU d'un tap

### Scénario 3 : Démonstration
Un membre explique le système à un nouvel utilisateur → Toggle pour montrer/cacher les DU

## Future Évolutions Possibles

- **Persistance d'état** : Mémoriser la préférence utilisateur
- **Filtre avancé** : Options supplémentaires de filtrage
- **Indicateur de DU** : Badge montrant le nombre de DU dans la période
- **Mode compact** : Affichage condensé des DU

Cette intégration respecte la philosophie de Gecko : **simplicité, efficacité et respect de l'utilisateur**. 