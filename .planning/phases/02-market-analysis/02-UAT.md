---
status: diagnosed
phase: 02-market-analysis
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md]
started: 2026-03-25T11:00:00Z
updated: 2026-03-26T10:00:00Z
---

## Current Test

[testing paused — diagnosing issues]

## Tests

### 1. Accès à l'analyse de marché
expected: Dans les options d'un wallet, un nouveau bouton "Analyse de marché" apparaît après le bouton Profil Cesium+. En appuyant dessus, l'écran d'analyse de marché s'ouvre.
result: pass

### 2. Sélection de période avec raccourcis
expected: Des boutons de raccourci permettent de sélectionner 30 jours, 90 jours, ou 365 jours. Les dates s'affichent et correspondent au nombre de jours sélectionné.
result: pass

### 3. Sélection de période personnalisée (calendrier)
expected: Un calendrier s'ouvre permettant de sélectionner une plage de dates. Si la plage dépasse 365 jours, un message d'erreur s'affiche.
result: pass

### 4. Sélection de contacts
expected: La liste des contacts favoris s'affiche avec des cases à cocher, l'avatar et le nom. Un bouton Tout sélectionner/désélectionner. Au moins un contact requis.
result: pass

### 5. Lancement et résultats de l'analyse
expected: L'analyse se lance avec barre de progression. Résultats : carte résumé agrégée et carte par contact avec totaux individuels.
result: pass

### 6. Découverte des autres contacts
expected: Sous les cartes des contacts sélectionnés, une section "Autres contacts" apparaît si des adresses non sélectionnées ont été trouvées dans les transactions analysées.
result: issue
reported: "La section autres contacts n'apparaît jamais. Bug architectural : les requêtes sont filtrées par contact, donc aucune adresse tierce n'est jamais dans les résultats. De plus, les cartes de résultats ne sont pas cliquables pour ouvrir le profil."
severity: blocker

### 7. Export markdown vers le presse-papier
expected: Un bouton d'export copie un résumé markdown dans le presse-papier avec snackbar de confirmation.
result: skipped
reason: Dépend de la correction des issues 6 pour avoir des données complètes à exporter

## Summary

total: 7
passed: 5
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "User sees a list of other contacts discovered from the analyzed transactions who were not in the initial selection"
  status: failed
  reason: "Bug architectural: fetchAllPages filtre par contactAddress, donc discoverOtherContacts ne trouve jamais d'adresse tierce. Il faut aussi requêter toutes les transactions du wallet sur la période sans filtre d'adresse."
  severity: blocker
  test: 6
  root_cause: "MarketAnalysisService.fetchAllPages ne requête que les transactions avec un contact spécifique. discoverOtherContacts parcourt ces résultats filtrés et ne peut jamais trouver d'adresses hors sélection."
  fix: "Ajouter une méthode fetchAllPagesUnfiltered qui requête toutes les transactions du wallet sur la période sans filtre addresses. Appeler cette méthode dans runAnalysis après la boucle per-contact et passer ses résultats à discoverOtherContacts."
  artifacts: ["lib/services/market_analysis_service.dart", "lib/providers/market_analysis_provider.dart"]
  missing: []

- truth: "User can tap on a contact card in analysis results to navigate to their profile"
  status: failed
  reason: "Les cartes de contacts dans AnalysisResults n'ont pas de onTap pour naviguer vers le profil. Fonctionnalité attendue par l'utilisateur."
  severity: major
  test: 6
  root_cause: "_buildContactCard retourne un Card sans GestureDetector/InkWell. Pas de navigation vers RouteNames.profileView."
  fix: "Wrapper les Cards dans un InkWell qui navigue vers RouteNames.profileView avec l'adresse du contact."
  artifacts: ["lib/widgets/market_analysis/analysis_results.dart"]
  missing: []
