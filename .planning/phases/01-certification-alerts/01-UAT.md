---
status: complete
phase: 01-certification-alerts
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md]
started: 2026-03-26T11:00:00Z
updated: 2026-03-26T11:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Badges d'expiration dans la liste des certifications
expected: Dans la liste des certifications d'un wallet membre, chaque certification affiche un badge coloré indiquant son état (rouge/orange/ambre/vert).
result: pass

### 2. Dot d'alerte sur le medal icon (accueil)
expected: Sur l'écran d'accueil, les tuiles de wallets membres affichent un petit point coloré sur l'icône médaille.
result: issue
reported: "Fonctionne mais pas intuitif — on ne sait pas à quoi correspond le point. Invisible en vue desktop."
severity: minor

### 3. Alerte certification sur les contacts (mobile)
expected: Dans la liste des contacts (mobile), un point coloré apparaît à côté du solde pour les contacts avec certifications expirées/expirant bientôt.
result: pass
notes: Pas de données pour vérifier visuellement, mais même remarque UX — pas intuitif

### 4. Alerte certification sur les contacts (desktop)
expected: Dans le panneau contacts (desktop), un point d'alerte certification apparaît entre le nom et le solde.
result: pass
notes: Impossible à vérifier visuellement, considéré OK

### 5. Mise à jour automatique des indicateurs
expected: Quand une certification est renouvelée on-chain, les indicateurs se mettent à jour automatiquement sans refresh manuel.
result: skipped
reason: Pas testable actuellement (nécessite un renouvellement de certification on-chain)

## Summary

total: 5
passed: 3
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "Cert alert dot on home wallet tiles is intuitive and visible on desktop"
  status: failed
  reason: "Le point d'alerte fonctionne mais n'est pas intuitif (l'utilisateur ne sait pas ce qu'il signifie) et est invisible en vue desktop."
  severity: minor
  test: 2
  root_cause: "Le dot est un simple point coloré sans tooltip ni légende. Sur desktop, il est probablement trop petit ou mal positionné dans le layout desktop."
  fix: "Ajouter un tooltip au dot expliquant le statut. Vérifier la visibilité sur le layout desktop."
  artifacts: ["lib/widgets/cert_alert_dot.dart", "lib/widgets/wallet_tile_membre.dart"]
  missing: []
