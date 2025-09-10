# Variables CI/CD pour Gecko

Ce document liste toutes les variables d'environnement nécessaires pour les pipelines CI/CD de Gecko.

## Variables iOS (obligatoires)

### Apple Developer Account
- `APPLE_TEAM_ID` : ID de l'équipe Apple Developer (ex: `2P2PNF45VD`)

### App Store Connect API
- `APP_STORE_CONNECT_API_KEY_ID` : ID de la clé API (ex: `H97R7Y2F97`)
- `APP_STORE_CONNECT_API_KEY_BASE64` : Contenu de la clé privée `.p8` encodé en base64
- `APP_STORE_CONNECT_API_ISSUER_ID` : ID de l'émetteur (ex: `124d44c9-b55d-4c70-b263-8f5f09834ff6`)

### App Store Deployment (optionnel)
- `IOS_APP_IDENTIFIER` : Bundle ID de l'app iOS (ex: `fr.axiom-team.gecko`)

## Variables Android (obligatoires)

### Google Play Store
- `GOOGLE_PLAY_JSON_KEY_BASE64` : Clé de service Google Play encodée en base64
- `ANDROID_PACKAGE_NAME` : Package name Android (ex: `fr.axiom-team.gecko`)
- `GOOGLE_PLAY_TRACK` : Track de déploiement (`internal`, `alpha`, `beta`, `production`)
- `GOOGLE_PLAY_RELEASE_STATUS` : Statut de release (`draft`, `completed`)

### Android Signing
- `ANDROID_KEYSTORE_BASE64` : Keystore Android encodé en base64
- `ANDROID_KEYSTORE_PASSWORD` : Mot de passe du keystore
- `ANDROID_KEY_ALIAS` : Alias de la clé de signature
- `ANDROID_KEY_PASSWORD` : Mot de passe de la clé de signature

## Comment configurer les variables

1. **Dans GitLab** : Aller dans Settings > CI/CD > Variables
2. **Marquer comme protégées** : Cocher "Protected" pour les variables sensibles
3. **Masquer les valeurs** : Cocher "Masked" pour les clés/mots de passe

## Génération des clés base64

### Pour la clé App Store Connect (.p8)
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

### Pour le keystore Android
```bash
base64 -i release-key.keystore | pbcopy
```

### Pour la clé Google Play (JSON)
```bash
base64 -i google-play-service-account.json | pbcopy
```
