import 'package:flutter/material.dart';

// General
const keyInfoPopup = Key('keyInfoPopup');
const keyGoNext = Key('keyGoNext');
const keyCancel = Key('keyCancel');
const keyConfirm = Key('keyConfirm');
const keyAppBarHome = Key('keyAppBarSearch');
const keyAppBarQrcode = Key('keyAppBarQrcode');
const keyAppBarSafe = Key('keyAppBarSafe');

// Home
const keyParameters = Key('keyParameters');
const keyDebugScreen = Key('keyDebugScreen');
const keyContacts = Key('keyContacts');
const keyDrawerMenu = Key('keyDrawerMenu');
const keyOpenWalletsHomme = Key('keyOpenWalletsHomme');
const keyOpenSearch = Key('keyOpenSearch');
const keyRestoreSafe = Key('keyRestoreSafe');
const keyOnboardingNewSafe = Key('keyOnboardingNewSafe');

// Wallets home
const keyImportG1v1 = Key('keyImportG1v1');
const keyChangeSafe = Key('keyChangeSafe');
const keyListWallets = Key('keyListWallets');
const keyAddDerivation = Key('keyAddDerivation');
// Removed problematic GlobalKeys - now using dynamic ValueKeys or local GlobalKeys

// Wallet options
const keyCopyAddress = Key('keyCopyAddress');
const keyCopyPubkey = Key('keyCopyPubkey');
const keyOpenActivity = Key('keyOpenActivity');
const keyManageMembership = Key('keyManageMembership');
const keySetDefaultWallet = Key('keySetDefaultWallet');
const keyDeleteWallet = Key('keyDeleteWallet');
const keyWalletName = Key('keyWalletName');
const keyRenameWallet = Key('keyRenameWallet');
const keyConfirmIdentity = Key('keyConfirmIdentity');
const keyEnterIdentityUsername = Key('keyEnterIdentityUsername');

// Safe options
const keyShowSeed = Key('keyShowSeed');
const keyRenameSafe = Key('keyRenameSafe');
const keyMigrateSafe = Key('keyMigrateSafe');
const keyChangePin = Key('keyChangePin');
const keycreateRootDerivation = Key('keycreateRootDerivation');
const keyDeleteSafe = Key('keyDeleteSafe');

// Manage membership
const keyMigrateIdentity = Key('keyMigrateIdentity');
const keyRevokeIdty = Key('keyRevokeIdty');

// Choose safe
const keyCreateNewSafe = Key('keyCreateNewSafe');
const keyImportSafe = Key('keyImportSafe');

// Profile view
const keyViewActivity = Key('keyViewActivity');
const keyCertify = Key('keyCertify');
const keyPay = Key('keyPay');
const keyAddToQueue = Key('keyAddToQueue');
const keyInQueue = Key('keyInQueue');
const keyExecuteQueued = Key('keyExecuteQueued');
const keyCertificationQueue = Key('keyCertificationQueue');
const keyAmountField = Key('keyAmountField');
const keyConfirmPayment = Key('keyConfirmPayment');
const keyCloseTransactionScreen = Key('keyCloseTransactionScreen');

// Activity view
const keyListTransactions = Key('keyListTransactions');
const keyActivityScreen = Key('keyActivityScreen');

// Certification view
const keyCertsReceived = Key('keyCertsReceived');

// Unlock wallet
const keyUnlockWallet = Key('keyUnlockWallet');
const keyPinForm = Key('keyPinForm');
const keyPopButton = Key('keyPopButton');
const keyCachePassword = Key('keyCachePassword');

// Settings
const keyDeleteAllWallets = Key('keyDeleteAllWallets');
const keySelectDuniterNodeDropDown = Key('keySelectDuniterNodeDropDown');
const keyCustomDuniterEndpoint = Key('keyCustomDuniterEndpoint');
const keyConnectToEndpoint = Key('keyConnectToEndpoint');
const keyUdUnit = Key('keyUdUnit');

// Onboarding
const keyPastMnemonic = Key('keyPastMnemonic');
const keyBubbleSpeak = Key('keyBubbleSpeak');
const keyGenerateMnemonic = Key('keyGenerateMnemonic');
const keyAskedWord = Key('keyAskedWord');
const keyInputWord = Key('keyInputWord');
const keyGoWalletsHome = Key('keyGoWalletsHome');

// Search
const keySearchField = Key('keySearchField');
const keyConfirmSearch = Key('keyConfirmSearch');

// Import Cesium wallet
const keyCesiumId = Key('keyCesiumId');
const keyCesiumPassword = Key('keyCesiumPassword');
const keySelectWallet = Key('keySelectWallet');
const keyCesiumIdVisible = Key('keyCesiumIdVisible');

const keyDropdownWallets = Key('keyDropdownKey');

// Items keys - using ValueKey to ensure uniqueness across rebuilds
Key keyTransaction(int keyId) => ValueKey('keyTransaction$keyId');
Key keyMnemonicWord(String word) => ValueKey('keyMnemonicWord$word');
Key keySearchResult(String address) => ValueKey('keySearchResult$address');
Key keySelectDuniterNode(String endpoint) => ValueKey('keySelectDuniterNode$endpoint');
Key keyOpenWallet(String address) => ValueKey('keyOpenWallet$address');
Key keySelectThisWallet(String address) => ValueKey('keySelectThisWallet$address');

const keyRenewMembership = Key('renewMembership');

// Mnemonic challenge
const keyMnemonicChallengeInput = Key('keyMnemonicChallengeInput');
const keyMnemonicChallengeConfirm = Key('keyMnemonicChallengeConfirm');
const keyMnemonicChallengeClose = Key('keyMnemonicChallengeClose');
Key keyMnemonicChallengeChip(int wordNumber) => ValueKey('keyMnemonicChallengeChip$wordNumber');

// Cesium profile view
const keyViewProfile = Key('keyViewProfile');
