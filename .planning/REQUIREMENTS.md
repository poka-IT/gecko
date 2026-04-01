# Requirements: Gecko v0.3 — Noms CesiumPlus & Recherche

**Defined:** 2026-03-31
**Core Value:** Les utilisateurs doivent pouvoir gérer leur monnaie libre, surveiller la santé de leur réseau de certifications et analyser leur activité transactionnelle sans quitter l'app.

## v0.3 Requirements

Requirements pour l'intégration des noms CesiumPlus et la recherche hybride. Chaque requirement est mappé à une phase du roadmap.

### Recherche Hybride

- [x] **SRCH-01**: L'utilisateur peut rechercher des portefeuilles par nom CesiumPlus en plus des identités on-chain
- [ ] **SRCH-02**: Les résultats de recherche fusionnent identités et noms CesiumPlus avec les identités toujours au-dessus
- [ ] **SRCH-03**: Les résultats sont affichés en sections étiquetées ("Identités vérifiées" / "Noms auto-déclarés")
- [x] **SRCH-04**: La recherche d'identités continue normalement si le pod CesiumPlus est indisponible

### Affichage des Noms

- [x] **DISP-01**: L'utilisateur voit le nom CesiumPlus d'un portefeuille qui n'a pas d'identité on-chain
- [x] **DISP-02**: Les noms d'identité (vérifiés) et les noms CesiumPlus (auto-déclarés) sont visuellement distincts via badge/indicateur
- [x] **DISP-03**: La vue profil affiche un label "nom auto-déclaré" pour les profils CesiumPlus sans identité
- [x] **DISP-04**: Les noms CesiumPlus sont persistés dans Hive (`csName`) pour affichage hors-ligne

### Enregistrement CesiumPlus

- [ ] **REG-01**: Quand l'utilisateur renomme un portefeuille (nom non-défaut), le nom est publié comme profil CesiumPlus
- [ ] **REG-02**: En cas d'échec réseau, un indicateur de statut et un retry automatique sont disponibles

### Anti-usurpation

- [x] **TRUST-01**: Un nom d'identité on-chain n'est jamais remplacé ou masqué par un nom CesiumPlus
- [ ] **TRUST-02**: Aucun autocomplete de noms CesiumPlus dans les champs de paiement/transfert
- [x] **TRUST-03**: Un avertissement est affiché quand un nom CesiumPlus correspond exactement à une identité on-chain existante

## Future Requirements

### Cache Avancé

- **CACHE-01**: Cache persistant avec TTL configurable pour les noms CesiumPlus
- **CACHE-02**: Optimisation batch pour le lookup de noms de la liste de contacts
- **CACHE-03**: Rotation de pods CesiumPlus pour la haute disponibilité

## Out of Scope

| Feature | Reason |
|---------|--------|
| Autocomplete CesiumPlus dans le champ de paiement | Risque d'usurpation prouvé (attaques ENS, $600K/mois de pertes documentées) |
| Nom CesiumPlus comme identifiant principal | Dégrade la confiance dans les noms vérifiés (précédent Twitter Blue) |
| Nom CesiumPlus sur l'écran de confirmation de transaction | Vecteur d'interception de paiement |
| Scoring PageRank complexe | Overkill pour une communauté de milliers ; séparation en sections suffit |
| Rotation multi-pods CesiumPlus | Scalabilité v1+, un seul pod pour v0.3 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SRCH-01 | Phase 4 | Complete |
| SRCH-02 | Phase 4 | Pending |
| SRCH-03 | Phase 4 | Pending |
| SRCH-04 | Phase 4 | Complete |
| DISP-01 | Phase 3 | Complete |
| DISP-02 | Phase 3 | Complete |
| DISP-03 | Phase 3 | Complete |
| DISP-04 | Phase 3 | Complete |
| REG-01 | Phase 5 | Pending |
| REG-02 | Phase 5 | Pending |
| TRUST-01 | Phase 3 | Complete |
| TRUST-02 | Phase 4 | Pending |
| TRUST-03 | Phase 3 | Complete |

**Coverage:**
- v0.3 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-03-31*
*Last updated: 2026-03-31 after roadmap creation*
