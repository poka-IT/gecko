# Gecko — Wallet Duniter v2s

## What This Is

Ğecko est un wallet mobile Flutter pour la blockchain Duniter v2s (Ḡ1v2). Il offre la gestion de wallets, les paiements, la certification d'identités, des alertes visuelles de certification (expiration/renouvellement), et un outil d'analyse de marché pour auditer l'activité transactionnelle sur une période.

## Core Value

Les utilisateurs doivent pouvoir gérer leur monnaie libre, surveiller la santé de leur réseau de certifications et analyser leur activité transactionnelle sans quitter l'app.

## Current State

**v0.2 shipped** (2026-03-25) — 2 phases, 4 plans, +1314 LOC
- Alertes de certification visibles depuis l'accueil, les contacts et la liste des certifications
- Analyse de marché avec sélection de période/contacts, totaux par contact, découverte d'autres contacts, export markdown

## Requirements

### Validated

- ✓ Gestion de wallets (création, import, PIN) — existing
- ✓ Paiements et transferts — existing
- ✓ Certification d'identités — existing
- ✓ Historique de transactions — existing
- ✓ Recherche de wallets membres — existing
- ✓ Contacts favoris — existing
- ✓ Migration v1 → v2 — existing
- ✓ Multi-wallet (coffre fort) — existing
- ✓ Support desktop et mobile — existing
- ✓ Mode hors-ligne partiel — existing
- ✓ Alertes de certification (icones expirée/bientôt expirée) — v0.2
- ✓ Indicateur d'alerte certification depuis l'accueil/contacts — v0.2
- ✓ Analyse de marché : sélection de période (max 365 jours) — v0.2
- ✓ Analyse de marché : sélection de contacts à analyser — v0.2
- ✓ Analyse de marché : totaux envoyés/reçus par contact — v0.2
- ✓ Analyse de marché : découverte des autres contacts — v0.2
- ✓ Analyse de marché : export markdown — v0.2

### Active

(No active requirements — start next milestone with `/gsd:new-milestone`)

### Out of Scope

- Recherche par nom de portefeuille simple — attend solution Duniter off-chain data indexation
- Affichage clé publique v1 — Gecko cible les futurs junistes, pas de rétro-compatibilité v1
- Mode web app (PWA) — risques de sécurité pour un wallet crypto
- Import EWIF/trousseau Cesium — le scan de phrase mnémonique est l'approche Gecko

## Context

- Retours utilisateur de Ma.aude sur le forum, power-user gérant plusieurs comptes pour une épicerie participative
- Ginkgo (dans `../ginkgo`) sert de référence fonctionnelle pour les nouvelles features
- Architecture Riverpod 3 : providers manuels (pas de codegen), AsyncNotifier pour l'état async
- durt2 fournit les souscriptions blockchain et l'accès à l'indexeur Squid (GraphQL)

## Constraints

- **Tech stack**: Flutter/Dart, Riverpod 3 (pas de codegen), durt2 pour blockchain
- **Données**: Certifications via durt2 storage subscriptions, transactions via Squid indexer
- **UX**: Portrait only (mobile), libre (desktop)
- **Inspiration**: Ginkgo (`../ginkgo`) comme référence fonctionnelle

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Alertes visibles depuis l'accueil | Ma.aude : "s'entraider" vs "chacun pour soi" | ✓ Delivered (v0.2) |
| Analyse de marché complète | Besoin épiceries participatives + vérification d'activité | ✓ Delivered (v0.2) |
| Dot indicator (pas de compteur) | Simplicité visuelle, indicateur worst-status | ✓ Good |
| calendar_date_picker2 pour range picker | Validé par Ginkgo, meilleur UX que 2x showDatePicker | ✓ Good |
| Pas de recherche par nom simple | Risque usurpation, attend solution Duniter | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-03-25 after v0.2 milestone completion*
