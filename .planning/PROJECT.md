# Gecko — Nouvelles fonctionnalités v0.2

## What This Is

Ğecko est un wallet mobile Flutter pour la blockchain Duniter v2s (Ḡ1v2). Ce milestone ajoute deux fonctionnalités demandées par la communauté : des alertes visuelles de certification (expiration, renouvellement) visibles dès l'accueil, et un outil d'analyse de marché permettant d'auditer les transactions d'un compte sur une période donnée.

## Core Value

Les utilisateurs doivent pouvoir surveiller la santé de leur réseau de certifications et analyser leur activité transactionnelle sans quitter l'app.

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
- ✓ Alertes de certification dans la liste des certifications (icones expirée/bientôt expirée) — Validated in Phase 1: Certification Alerts
- ✓ Indicateur d'alerte certification visible depuis l'accueil/contacts — Validated in Phase 1: Certification Alerts
- ✓ Analyse de marché : sélection de période (max 365 jours) — Validated in Phase 2: Market Analysis
- ✓ Analyse de marché : sélection de contacts à analyser — Validated in Phase 2: Market Analysis
- ✓ Analyse de marché : totaux envoyés/reçus par contact — Validated in Phase 2: Market Analysis
- ✓ Analyse de marché : découverte des autres contacts impliqués dans les transactions — Validated in Phase 2: Market Analysis
- ✓ Analyse de marché : export/résumé markdown des résultats — Validated in Phase 2: Market Analysis

### Active

(No active requirements — all milestone v0.2 requirements validated)

### Out of Scope

- Recherche par nom de portefeuille simple — attend solution Duniter off-chain data indexation
- Affichage clé publique v1 — Gecko cible les futurs junistes, pas de rétro-compatibilité v1
- Mode web app (PWA) — risques de sécurité pour un wallet crypto
- Import EWIF/trousseau Cesium — le scan de phrase mnémonique est l'approche Gecko

## Context

- Retours utilisateur de Ma.aude sur le forum, power-user gérant plusieurs comptes pour une épicerie participative
- Ginkgo (dans `../ginkgo`) implémente déjà ces deux fonctionnalités et sert de référence
- Les alertes de certification dans Ginkgo utilisent `expireOn - currentBlockHeight` avec un seuil de ~835 jours (201600 blocs)
- L'analyse de marché dans Ginkgo utilise l'indexeur GraphQL Squid avec filtres `timestampFrom`/`timestampTo`
- Gecko utilise déjà `durt2` qui fournit les souscriptions blockchain et l'accès à l'indexeur Squid
- Architecture Riverpod 3 : les nouveaux providers doivent suivre les conventions existantes (pas de codegen, AsyncNotifier pour l'état async)

## Constraints

- **Tech stack**: Flutter/Dart, Riverpod 3 (pas de codegen), durt2 pour blockchain
- **Données**: Les données de certification (expireOn, isActive) viennent de durt2 storage subscriptions
- **Indexeur**: L'historique de transactions filtré par date nécessite l'indexeur Squid (GraphQL)
- **UX**: Portrait only (mobile), libre (desktop) — les deux layouts doivent être supportés
- **Inspiration**: Le code de Ginkgo (`../ginkgo`) sert de référence fonctionnelle, pas de copie de code

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Alertes visibles depuis l'accueil | Ma.aude souligne l'importance de "s'entraider" vs "chacun pour soi" | Delivered (Phase 1) |
| Analyse de marché complète (comme Ginkgo) | Besoin réel pour les épiceries participatives et vérification d'activité | Delivered (Phase 2) |
| Pas de recherche par nom de portefeuille simple | Problème de sécurité (usurpation), attend solution Duniter | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-25 after Phase 2 completion — all milestone v0.2 phases complete*
