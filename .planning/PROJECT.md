# Gecko — Wallet Duniter v2s

## What This Is

Ğecko est un wallet mobile Flutter pour la blockchain Duniter v2s (Ḡ1v2). Il offre la gestion de wallets, les paiements, la certification d'identités, des alertes visuelles de certification (expiration/renouvellement), et un outil d'analyse de marché pour auditer l'activité transactionnelle sur une période.

## Core Value

Les utilisateurs doivent pouvoir gérer leur monnaie libre, surveiller la santé de leur réseau de certifications et analyser leur activité transactionnelle sans quitter l'app.

## Current Milestone: v0.3 Noms CesiumPlus & Recherche

**Goal:** Intégrer les noms de portefeuilles CesiumPlus dans la recherche et l'affichage, avec une UX anti-usurpation qui distingue clairement les identités on-chain des noms CesiumPlus auto-déclarés.

**Target features:**
- Recherche hybride avec scoring multi-source (identités priorisées, CesiumPlus différenciés)
- Affichage des noms CesiumPlus pour les portefeuilles sans identité on-chain
- Enregistrement CesiumPlus quand l'utilisateur renomme un portefeuille (pas le nom par défaut)
- UX anti-usurpation : distinction visuelle claire entre noms vérifiés et auto-déclarés
- Cache Riverpod persisté avec invalidation robuste

## Current State

**v0.2 shipped** (2026-03-25) — 2 phases, 4 plans, +1314 LOC
- Alertes de certification visibles depuis l'accueil, les contacts et la liste des certifications
- Analyse de marché avec sélection de période/contacts, totaux par contact, découverte d'autres contacts, export markdown

**v0.3 Phase 3 complete** (2026-04-01)
- Trust visual system : cesiumNameProvider, cesiumNameConflictProvider, NameSourceBadge, NameByAddress avec fallback CesiumPlus, persistance Hive csName

**v0.3 Phase 4 complete** (2026-04-01)
- Hybrid search : searchByName() dans durt2, cesiumPlusSearchProvider, intégration dans 5 entry points UI (mobile + desktop), sections étiquetées, déduplication, TRUST-02 vérifié

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
- ✓ Affichage noms CesiumPlus pour portefeuilles sans identité — v0.3 Phase 3
- ✓ UX anti-usurpation (distinction visuelle identités vs noms auto-déclarés) — v0.3 Phase 3
- ✓ Cache Riverpod persisté pour noms CesiumPlus (Hive csName) — v0.3 Phase 3
- ✓ Recherche hybride identités + noms CesiumPlus avec sections étiquetées — v0.3 Phase 4

### Active

- [ ] Enregistrement noms de portefeuilles via API CesiumPlus

### Out of Scope

- ~~Recherche par nom de portefeuille simple~~ — Levé en v0.3 via CesiumPlus avec mécanismes anti-usurpation
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
| Pas de recherche par nom simple | Risque usurpation, attend solution Duniter | ⚠️ Revisit — v0.3 adresse via CesiumPlus + anti-usurpation |

## Evolution

This document evolves at phase transitions and milestone boundaries.

---
*Last updated: 2026-04-01 after Phase 4 completion*
