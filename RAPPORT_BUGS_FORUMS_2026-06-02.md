# Rapport bugs Ğecko — Forums Duniter & Monnaie Libre (depuis 2026-04-27)

**Date du rapport :** 2026-06-02
**Version Gecko analysée :** 1.2.6+192 (HEAD `master` `1dcc9879`)
**Périmètre :** tous les messages mentionnant Gecko (catégorie dédiée + mentions dans le titre/corps, toutes catégories) sur forum.duniter.org et forum.monnaie-libre.fr, datés du 2026-04-27 ou après.

---

## 1. Méthodologie

- **forum.duniter.org** : catégorie Ğecko (id 55) + recherches `gecko`, `Ğecko`, `tag:bugv2` + topics transverses (Cesium, Support) mentionnant Gecko. API REST Discourse (compte admin lecture seule `g1-monitor`).
- **forum.monnaie-libre.fr** : catégorie Gecko (id 154) + recherches `gecko`. API REST publique.
- Lecture intégrale de chaque topic pertinent, puis analyse du code Gecko (`/Users/poka/dev/gecko`) et de durt2 (`/Users/poka/dev/durt2`) pour déterminer l'origine (Gecko / durt2 / build), si déjà corrigé en HEAD, et s'il s'agit d'un vrai bug ou d'un malentendu UX.
- Croisement avec les 25 issues ouvertes du dépôt GitLab `clients/gecko` (id 474).

**Topics couverts :** Duniter #9367, #9372, #13736, #13757, #13783, #13806, #13826, #13832, #13833, #13837, #13842, #13847, #13850, #13852, #13857, #13861, #13862, #13864, #13870, #13872 — Monnaie Libre #33507, #33589, #33613, #33615, #33644, #33654, #33658, #33707, #33722 (+ topics survolés sans contenu Gecko).

---

## 2. Synthèse exécutive

| # | Problème | Sévérité | Origine | Déjà corrigé HEAD ? | Issue GitLab |
|---|----------|----------|---------|---------------------|--------------|
| B1 | File de certif : dernière entrée fantôme | 🔴 Critique | Gecko | Non | À créer |
| B2 | Coffre orphelin après migration id/mdp (g1v1) | 🟠 Haute | Gecko | Non | À créer |
| B3 | Perte coffre/photos/perso après MAJ desktop (Windows) | 🔴 Critique (perte de données) | Gecko (régression 1.2.6) | Non | À créer |
| B4 | macOS : l'app ne s'ouvre pas | 🟠 Haute | Build/CI (signature/notarisation) | Non | À créer |
| B5 | i18n FR « identité révoqué » → « révoquée » | 🟢 Trivial | Gecko | Non | Mineur |
| B6 | Migration identité : `OwnerKeyAlreadyRecentlyChanged` non traduit + délai non affiché | 🟡 Moyenne | Gecko (i18n) + durt2 (pré-check) | Non | À créer |
| U7 | Renouvellement adhésion : bouton grisé / erreurs nœud non affichées | 🟡 Moyenne | Gecko | Partiel | **#192 (existe)** |
| U8 | Desktop : fenêtre grand écran non réductible + flash vert | 🟡 Moyenne | Config plateforme | Partiel | À créer |
| U9 | Onboarding : création de coffre par erreur au lieu de restaurer | 🟡 Moyenne | Gecko (UX) | — | À créer |
| U10 | Paiement : sélecteur du portefeuille émetteur peu découvrable | 🟢 Mineure | Gecko (UX) | — | À créer |
| U11 | Restauration multi-portefeuilles desktop : ordre/impression de perte | 🟢 Mineure | Gecko (UX) | — | À créer |
| U12 | Windows : faux positifs antivirus + droits admin | 🟡 Moyenne | Build (signature exe) | Non | À créer |
| U13 | Packaging NixOS / échec install Xubuntu | 🟢 Mineure | Distribution | — | (cf. #158 .appimage) |
| U14 | Suggestion coffres style Ğ1nkgo | 🟢 Feature | — | — | À créer |

**Résolus / non-bugs :** QR code grand écran (corrigé 1.2.6), ajout compte révoqué à la file (corrigé 1.1.4), site gecko-wallet.app down (résolu), blocage App Store iOS (résolu ~2026-05-01), déclenchement distance/adhésion à la 5e certif (durt2 correct, simplement asynchrone).

---

## 3. Bugs de code confirmés

### B1 — File de certification : la dernière entrée ne se supprime jamais 🔴

**Le bug le plus rapporté, multi-plateforme.**

- **Sources :** Duniter #13837 (Chiara07, Android 1.2.6), #13850 pt2 (Chiara07), #13870 (Dio, PC/Android) — Monnaie Libre #33707 (Saamour, iOS iPhone 14 / XS, 1.2.6).
- **Symptôme :** quand il ne reste qu'**une seule** certification dans la file, après l'avoir effectuée elle **reste indéfiniment** ; à chaque ouverture de l'app, une popup invite à recertifier. La suppression « se vide puis revient ». Contournements connus des utilisateurs : ajouter un autre juniste dans la file, ou supprimer l'entrée depuis Cesium2. Parfois état « X jours avant recertif » bloqué.
- **Cause racine (Gecko) :** `lib/providers/certification_queue_provider.dart:415-441`, méthode `pushToRemote`. Un bloc « recovery on empty local » (introduit par le commit `b80c12c78` du 19/04/2026 pour éviter d'écraser le pod après un reset local) : quand la file locale est vide, il **relit le pod Cesium+, le retrouve encore peuplé** (l'entrée n'a jamais été poussée comme supprimée), considère ça comme une perte de données, **ré-adopte la file distante**, ré-écrit le local, re-notifie la cert « ready », et retourne `true`. Il ne distingue pas « local vidé volontairement par l'utilisateur » de « local vidé par sinistre ». durt2 est correct (`saveCertificationQueue` saurait écrire une file vide).
  - Popup récurrente : `lib/widgets/certify/ready_certification_listener.dart:88-95`.
  - Persistance : local Hive `lib/services/certification_queue_service.dart` ; distant `durt2/lib/src/services/cesium_plus_service.dart:654,688` (champ `certificationQueue` du profil Cesium+, partagé avec Cesium2).
- **État HEAD :** présent (`b80c12c78` non révoqué, bloc intact).
- **Correction proposée :** dans `pushToRemote`, lorsque le local est vide, comparer `remoteQueue.lastUpdated` au `lastUpdated` local. Si le local vide est plus **récent** (suppression volontaire — `removeFromQueue` pose `lastUpdated: now`), pousser la file vide (`saveCertificationQueue`). Sinon (placeholder epoch-0 = réelle perte de données), conserver la récupération actuelle. Le code utilise déjà `lastUpdated.isBefore(...)` comme arbitre ailleurs (`:360`, `:685`). Variante : flag explicite `intentionalEmpty`.

### B2 — Coffre orphelin après migration depuis un compte id/mot de passe (flux g1v1) 🟠

- **Source :** Monnaie Libre #33722 (Jade ; **confirmé bug par Maaltir** : « Gecko garde un coffre pour l'ancien compte, c'est un bug, Gecko devrait l'oublier automatiquement »).
- **Symptôme :** après migration en partant de l'authentification Identifiant+Mot de passe (Cesium v1), Gecko conserve **deux coffres** — l'ancien vide à 0 Ğ1 et le compte membre migré. Le PIN ramène par défaut sur le coffre vide. Contournement : changer de coffre manuellement.
- **Cause racine (Gecko) :** il existe **deux systèmes de migration** ; seul l'ancien (`lib/screens/onBoarding/10.dart` → `_deleteLegacySafeAndSyncState` à `:429`) supprime l'ancien coffre. Le **flux moderne « g1v1 »** mis en avant dans l'UI (`lib/screens/myWallets/g1v1_migration/steps/step_confirmation.dart`, jumeau desktop `lib/widgets/desktop/modals/legacy_migration_modal.dart`) appelle `duniterService.migrateCsToV2()` → `transferAll` (vide le compte source) **mais n'appelle jamais `deleteSafe`** ni ne réassigne le coffre par défaut. L'ancien coffre legacy importé reste donc, à 0 Ğ1, et peut être le coffre n°0 affiché en premier. durt2 expose pourtant `deleteSafe()`/`reassignSafeNumber()` — c'est Gecko qui ne les appelle pas dans ce flux.
- **État HEAD :** présent.
- **Correction proposée :** après succès (`inBlock`/`finalized`) du flux g1v1, retrouver le coffre `SafeType.legacy` correspondant à `flowState.v2Address`, supprimer ses files de certif, `deleteSafe`, puis resynchroniser `defaultSafeBoxNumberProvider`/`walletsListProvider` vers le coffre cible. Mutualiser la logique de `10.dart:_deleteLegacySafeAndSyncState` dans un service partagé.

### B3 — Perte du coffre, des photos et de la personnalisation après mise à jour desktop 🔴 (perte de données)

- **Sources :** Duniter #13861 (Dio, Windows : contacts récupérés mais pas le coffre ; photos de profil perdues ; personnalisation reset ; deux comptes qui étaient dans le même coffre désormais séparés) — recoupé par #13850 pt6 (photos disparues après restauration).
- **Cause racine (régression Gecko v1.2.6, commit `449790ec7`) :** les **contacts sont en Hive** (`~/.gecko/db`, chemin stable → survivent), **tout le reste est en ObjectBox** (coffres, `WalletEntity` nom/couleur/`imagePath` des photos). En v1.2.0→1.2.5 ObjectBox vivait dans `~/Documents/objectbox` (défaut durt2). En v1.2.6 le chemin passe à `~/.gecko/objectbox` avec une migration `runDesktopMigrations`/`_migrateObjectBox` (`lib/services/storage_init_service.dart:162-198`) qui **hardcode `%UserProfile%/Documents/objectbox`**. Sur Windows avec redirection OneDrive (`%UserProfile%\OneDrive\Documents`), dossier localisé, ou suite au passage **per-user install** (commit `f76c757c4`), l'ancien dossier réel diffère → migration vide → ObjectBox démarre **vierge** → coffre/photos/perso perdus.
  - Photos : `WalletEntity.imagePath` (`~/.gecko/avatars/`) en ObjectBox.
  - Deux coffres non fusionnables : à la réimportation, le coffre est identifié par `SafeEntity.fingerprint` (SHA-256 du mnémonique) — réimporter via deux mnémoniques/dérivations distinctes crée deux fingerprints.
  - Aggravant : la clé maître `obx_master_key` (FlutterSecureStorage/DPAPI) n'est migrée **que sur macOS** (`if (Platform.isMacOS)`), donc un changement d'install peut invalider le déchiffrement sur Windows/Linux.
- **État HEAD :** la régression EST en HEAD (introduite par 1.2.6).
- **Correction proposée :** dériver l'ancien chemin via `path_provider.getApplicationDocumentsDirectory()` (vrai ancien chemin) au lieu du hardcode ; tester aussi `OneDrive\Documents` ; migrer `obx_master_key` sur Windows/Linux ; logguer/Sentry si aucune DB source trouvée alors que l'app n'est pas une première installation.

### B4 — macOS : l'application refuse de se lancer 🟠 (signalé 2× sans réponse)

- **Sources :** Duniter #9372 post#812 (thierry1769, macOS 26.5, 1.2.6), #13857 (thierry1769), #13872 post#4 (« signalé à plusieurs personnes, jamais eu de réponse », macOS 26.5 Intel) — Monnaie Libre #33644.
- **Symptôme :** « Impossible d'ouvrir l'application », même après « ouvrir quand même » dans les réglages de sécurité.
- **Cause racine (build/CI, pas le code Dart) :** le script `scripts/build-macos-dmg.sh` fait `flutter build macos --release` + `hdiutil` **sans `codesign` Developer ID, sans `notarytool`, sans `stapler`, sans re-signature des frameworks embarqués**. Le projet est en signature ad-hoc (`CODE_SIGN_IDENTITY = "-"`). Le job CI macOS qui contenait toute la chaîne de signature/notarisation est **entièrement commenté** (`.gitlab-ci.yml` ~l.591-1180). Une signature ad-hoc cassée par `hdiutil`/copie produit « Impossible d'ouvrir » même après autorisation Gatekeeper. **L'architecture n'est PAS le souci** : le binaire local est universel (Intel + arm64).
- **État HEAD :** présent (commit « macos icons » ne touche que des PNG).
- **Correction proposée :** signer en **Developer ID Application** (`codesign --options runtime --deep` + re-signature des frameworks), **notariser** (`xcrun notarytool submit`) et **stapler** ; réactiver le job CI. À défaut de compte Apple Developer, documenter `xattr -dr com.apple.quarantine /Applications/gecko.app` (absent du `INSTALL.txt`).

### B5 — Faute d'orthographe i18n FR 🟢

- **Source :** Duniter #13783 post#3 (Spiranne).
- **Cause :** `assets/translations/fr.json:176` → `"identityRevoked": "Identité révoqué"` (féminin manquant). Voir aussi `:566` `"identityStatusRevoked": "Révoqué"`.
- **Correction :** « Identité révoquée » (et accorder les libellés de statut selon contexte).

### B6 — Migration d'identité : message d'erreur incompréhensible + délai non affiché 🟡

- **Source :** Duniter #13852 (CHOUCHA ; kapis et vit expliquent le délai de 6 mois `OwnerKeyAlreadyRecentlyChanged`).
- **Cause racine :**
  - **(i18n, Gecko)** `lib/widgets/transaction_status.dart` — `errorTransactionMap` ne contient **aucune** entrée `identity.OwnerKeyAlreadyRecentlyChanged` → `lookupTransactionError` renvoie `null` → l'UI affiche brut « Erreur technique : identity.OwnerKeyAlreadyRecentlyChanged » (`transaction_progress_modal.dart:358`, `screens/transaction_in_progress.dart:376`). *(vérifié : 0 occurrence de la clé dans `lib/`.)*
  - **(pré-check, durt2)** le délai restant existe dans la donnée mais n'est **utilisé nulle part** dans Gecko, et le calcul `ownerKeyBondInfo` de `duniter_storage_service.dart:917-958` est **faux pour ce cas** (il lit la caution SMITH/validateur `smithMembers...lastOnline + reportLongevity` au lieu de `IdtyValue.oldOwnerKey` + `changeOwnerKeyPeriod`).
  - **Garde « coffre cible a déjà une identité » : déjà présente et OK** (`cannotMigrateIdentityToIdentity`, `migrate_identity.dart:466-471`).
- **État HEAD :** non traité.
- **Correction proposée :** ajouter `'identity.OwnerKeyAlreadyRecentlyChanged'` dans `errorTransactionMap` + clé i18n (en/fr/es/it) expliquant le délai ~6 mois ; corriger `getMigrateWalletChecks` (durt2) pour lire `identity.identities(idtyIndex).oldOwnerKey` + `changeOwnerKeyPeriod` ; consommer `migrationChecks.ownerKeyBondInfo` dans `migrate_identity.dart` pour afficher le délai et désactiver le bouton en amont.

---

## 4. Frictions UX / demandes

### U7 — Renouvellement d'adhésion : bouton grisé, erreurs nœud non affichées 🟡 — **GitLab #192 existe**
- Sources : Duniter #13850 pt7 (texte grisé après adhésion périmée avec 5 certifs) ; recoupe #13757, #13833, #13864 (Gecko cité comme l'app qui *sait* renouveler, vs Cesium).
- Cause (Gecko) : `lib/screens/myWallets/manage_membership.dart:155-230` grise le bouton sur heuristique **locale** (`!info.canRenew`, gate `notEnoughCertsReceived` via `membership_renewal.dart`) au lieu de laisser le nœud valider et remonter une erreur lisible. `renewMembership` (durt2) déclenche en réalité `distance.requestDistanceEvaluation()`. Erreurs des pallets `distance`/`membership` non mappées dans `errorTransactionMap` → affichage brut.
- État HEAD : partiel (gate ajouté par `2446f17a2`). Vérifier que `receivedCount` ne compte que les certifs **actives** ; ne pas sur-bloquer en local ; compléter `errorTransactionMap`.

### U8 — Desktop : fenêtre forcée en grand écran non réductible + flash vert au lancement 🟡
- Source : Duniter #13850 pt8.
- Cause (config plateforme) : `flutter_native_splash` configuré android/ios uniquement → sur desktop la fenêtre native s'affiche avec sa couleur de fond avant la 1re frame Flutter ; sur Linux `linux/runner/my_application.cc:60` fait `gtk_widget_show` **immédiatement** → flash + maximize par certains WM avant que `window_manager` applique la taille (`lib/main.dart:170-208`). `minSize 800×600` (`:186`) est voulu (toggle `bypassMinWindowSize` existe) mais piège les petits écrans.
- Correction : config splash desktop (couleur marque) ; retarder le `show` Linux (cf. macOS `orderOut(nil)`) ; clamper `minSize` à la taille d'écran.

### U9 — Onboarding : utilisateurs créent un coffre par erreur au lieu de restaurer 🟡
- Sources : Duniter #13864 (Erika ne trouve que « transférer ancien compte id/mdp », crée un nouveau compte par inadvertance) ; recoupe ML #33654.
- Piste : rendre l'option « restaurer mes portefeuilles » (phrase 12 mots) plus évidente et distincte de l'import id/mdp v1.

### U10 — Paiement : sélecteur du portefeuille émetteur peu découvrable 🟢
- Source : ML #33658 (levaldande ne trouve pas comment payer depuis son 2e portefeuille ; poka sollicite des idées d'amélioration). Pas de bug technique confirmé — découvrabilité du sélecteur.

### U11 — Restauration multi-portefeuilles desktop : ordre / impression de perte 🟢
- Source : Duniter #13850 pt5 (compte principal restauré en 2e position, impression d'avoir perdu un portefeuille ; demande de choix des portefeuilles à restaurer).

### U12 — Windows : faux positifs antivirus + droits admin requis 🟡
- Source : Duniter #13833 (lancement en administrateur obligatoire, antivirus 360 Total Security bloque). Piste : signer l'exécutable Windows.

### U13 — Packaging NixOS / échec installation Linux 🟢
- Sources : Duniter #13832 (vincentux, NixOS, sans réponse) ; ML #33615 (échec install Xubuntu). Lié à l'issue GitLab existante **#158** (.appimage via CI).

### U14 — Suggestion UX : coffres style Ğ1nkgo 🟢
- Source : Duniter #13862 (hypericum : tous les portefeuilles d'un coffre ouverts, même couleur ; standardisation entre clients).

---

## 5. Résolus / non-bugs / malentendus

- **QR code disparu en grand écran** (#13826, #13850 pt3) → **corrigé en 1.2.6**.
- **Compte révoqué ajoutable à la file de certif** (#13783) → **corrigé en 1.1.4**.
- **Site gecko-wallet.app indisponible** (#33507) → **résolu** (poka, 28/04).
- **iOS : portefeuilles qui disparaissent / version obsolète** (#13806, v1.1.0) → blocage App Store **levé ~2026-05-01**. ⚠️ *À vérifier sur versions récentes :* persistance du bug + **non-synchronisation des modifs de profil ordinateur → iOS** (jamais traité explicitement).
- **Pas membre malgré 5 certifs + distance / DU non créé** (ML #33615, #33613) → **pas un bug Gecko** : `durt2 certify()` ajoute bien `requestDistanceEvaluationFor` au batch quand `receivedCount >= minCerts-1` ; l'adhésion v2s est acquise **automatiquement** par le runtime (pas de `claimMembership` client) ; l'évaluation de distance est **asynchrone** (perçu comme « ça ne marche pas »). Recommandation : clarifier l'attente (« évaluation en cours, adhésion sous X jours »).
- **« Migrer vers Gecko coupe l'accès Cesium »** (#13757) → **faux** (même phrase de 12 mots, multi-app).
- **PIN 4 chiffres** (#13872) → Gecko le fait déjà ; demande adressée surtout à Cesium.

---

## 6. Issues GitLab — état des lieux

**Issues ouvertes correspondant à des retours forum :**
- **#192** « Gecko fails to display validation errors from Duniter node during membership renewal » → **U7** (partiellement traité ; à compléter).
- **#191** « Certification sur compte expiré ne passe pas » (mars) → à recroiser : le forum indique au contraire que Gecko *sait* certifier/renouveler (vs Cesium) — vérifier si toujours d'actualité.
- **#193** « Mise à jour de la photo Avatar » → connexe à **B3** (gestion des photos de profil).
- **#195** « Position des boutons certifications expirées » / **#158** « .appimage via CI » (lié **U13**).

**Nouvelles issues à créer (aucune existante) :**
1. **B1** — File de certif : dernière entrée fantôme (🔴 p1).
2. **B3** — Perte coffre/photos/perso après MAJ desktop Windows (🔴 p1, perte de données).
3. **B2** — Coffre orphelin après migration id/mdp g1v1 (🟠 p2).
4. **B4** — macOS : l'app ne s'ouvre pas — signature/notarisation (🟠 p2).
5. **B6** — Migration identité : message `OwnerKeyAlreadyRecentlyChanged` non traduit + délai (🟡 p2).
6. **B5** — i18n « identité révoquée » (🟢 p3, quick win).
7. **U8** — Fenêtre desktop non réductible + flash (🟡 p3).
8. **U9** — Onboarding restauration vs import id/mdp (🟡 p2/UX).
9. **U10/U11** — UX paiement multi-portefeuille / restauration desktop (🟢 p3).
10. **U12** — Signature exécutable Windows (🟡 p3).

---

## 7. Recommandation de priorisation

1. **B3** (perte de données Windows à la MAJ) et **B1** (file de certif fantôme) — impact utilisateur immédiat et large, les deux en régression/connus.
2. **B4** (macOS) — signalé plusieurs fois sans réponse, mauvaise image ; B2 (coffre orphelin) — confusion fréquente.
3. **B6**, **U7**, **U8**, **U9** — UX/erreurs.
4. Quick wins : **B5** (typo), **U10/U11** (UX paiement/restauration).

> Les `post_id` des captures d'écran (file de certif, message d'erreur de migration, état des coffres) ont été relevés pour chaque topic et peuvent être téléchargés via le JSON du post pour enrichir les issues GitLab.
