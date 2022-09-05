import 'package:flutter/material.dart';

// General
const keyInfoPopup = Key('keyInfoPopup');
const keyGoNext = Key('keyGoNext');
const keyCancel = Key('keyCancel');
const keyConfirm = Key('keyConfirm');
const keyAppBarSearch = Key('keyAppBarSearch');
const keyAppBarQrcode = Key('keyAppBarQrcode');
const keyAppBarChest = Key('keyAppBarChest');

// Home
const keyParameters = Key('keyParameters');
const keyContacts = Key('keyContacts');
const keyDrawerMenu = Key('keyDrawerMenu');
const keyOpenWalletsHomme = Key('keyOpenWalletsHomme');
const keyOpenSearch = Key('keyOpenSearch');
const keyRestoreChest = Key('keyRestoreChest');
const keyOnboardingNewChest = Key('keyOnboardingNewChest');

// Wallets home
const keyImportG1v1 = Key('keyImportG1v1');
const keyChangeChest = Key('keyChangeChest');
const keyListWallets = Key('keyListWallets');
const keyAddDerivation = Key('keyAddDerivation');

// Wallet options
const keyCopyAddress = Key('keyCopyAddress');
const keyOpenActivity = Key('keyOpenActivity');
const keyManageMembership = Key('keyManageMembership');
const keySetDefaultWallet = Key('keySetDefaultWallet');
const keyDeleteWallet = Key('keyDeleteWallet');
const keyWalletName = Key('keyWalletName');
const keyRenameWallet = Key('keyRenameWallet');
const keyConfirmIdentity = Key('keyConfirmIdentity');
const keyEnterIdentityUsername = Key('keyEnterIdentityUsername');

// Chest options
const keyShowSeed = Key('keyShowSeed');
const keyChangePin = Key('keyChangePin');
const keycreateRootDerivation = Key('keycreateRootDerivation');
const keyDeleteChest = Key('keyDeleteChest');

// Manage membership
const keyMigrateIdentity = Key('keyMigrateIdentity');
const keyRevokeIdty = Key('keyRevokeIdty');

// Choose chest
const keyCreateNewChest = Key('keyCreateNewChest');
const keyImportChest = Key('keyImportChest');

// Profile view
const keyViewActivity = Key('keyViewActivity');
const keyCertify = Key('keyCertify');
const keyPay = Key('keyPay');
const keyAmountField = Key('keyAmountField');
const keyConfirmPayment = Key('keyConfirmPayment');
const keyCloseTransactionScreen = Key('keyCloseTransactionScreen');

// Activity view
const keyListTransactions = Key('keyListTransactions');

// Unlock wallet
const keyPinForm = Key('keyPinForm');
const keyPopButton = Key('keyPopButton');
const keyCachePassword = Key('keyCachePassword');

// Settings
const keyDeleteAllWallets = Key('keyDeleteAllWallets');
const keySelectDuniterNodeDropDown = Key('keySelectDuniterNodeDropDown');
const keyCustomDuniterEndpoint = Key('keyCustomDuniterEndpoint');
const keyConnectToEndpoint = Key('keyConnectToEndpoint');

// Onboarding
const keyPastMnemonic = Key('keyPastMnemonic');
const keyBubbleSpeak = Key('keyBubbleSpeak');
const keyGenerateMnemonic = Key('keyGenerateMnemonic');
const keyAskedWord = Key('keyAskedWord');
const keyInputWord = Key('keyInputWord');
const keyGeneratedPin = Key('keyGeneratedPin');
const keyGoWalletsHome = Key('keyGoWalletsHome');

// Search
const keySearchField = Key('keySearchField');
const keyConfirmSearch = Key('keyConfirmSearch');

// Import Cesium wallet
const keyCesiumId = Key('keyCesiumId');
const keyCesiumPassword = Key('keyCesiumPassword');
const keySelectWallet = Key('keySelectWallet');
const keyCesiumIdVisible = Key('keyCesiumIdVisible');

// Items keys
Key keyTransaction(int keyId) => Key('keyTransaction$keyId');
Key keyMnemonicWord(String word) => Key('keyMnemonicWord$word');
Key keySearchResult(String address) => Key('keySearchResult$address');
Key keySelectDuniterNode(String endpoint) =>
    Key('keySelectDuniterNode$endpoint');
Key keyOpenWallet(String address) => Key('keyOpenWallet$address');
Key keySelectThisWallet(String address) => Key('keySelectThisWallet$address');
