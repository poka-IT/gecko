# Ğecko

Ğecko is mobile client for Duniter v2s blockchain (Ḡ1v2): https://duniter.org/blog/duniter-substrate<br>
It use polkawallet_sdk package to interact with Duniter: https://github.com/polkawallet-io/sdk

This application is maintained by [Axiom-Team association](https://axiom-team.fr/).

You can download the last version of the app [here](https://forum.duniter.org/t/gecko-gdev-last-build/9367/last).<br>
You can ask questions about Ḡecko developpement in our [Duniter forum](https://forum.duniter.org/t/gecko-talks-user-support/9372/last).


<div align="center">

![Demo Gif](https://git.duniter.org/clients/gecko/-/raw/master/images/demo-0.0.9+2.gif)

<br><br>
</div>

## Develop

To contribute to the code, we advise you to install the following development environment:

1. [Android Studio](https://developer.android.com/studio/install)
2. [Flutter](https://docs.flutter.dev/get-started/install)
3. [VSCode](https://code.visualstudio.com/docs/setup/linux) or [VSCodium](https://vscodium.com/)

This will take about 12GB on your drive and 20 min of your time (with a good connection). Don't
hesitate to ask on the forum for a peer-coding session if you are stuck.

At the end, `flutter doctor` command should be OK for what you need.

### Android Studio

Android Studio will let you set up an Android VM and install tools you need.

- Install [Android Studio](https://developer.android.com/studio/) using your favorite installation
  method.
- At startup, do not open a project but click "configure" at the bottom of the "Welcome" menu
- In "SDK Manager"
    - SDK Platforms tab
        - select Android 11 (R) API level 30 (default) or higher
- In "AVD Manager"
    - create a virtual machine

If you reach this point without trouble, you're good to go for the next step.

### iOS (Xcode on Mac)
TODO: documentation

### Flutter SDK

Flutter is a powerfull SDK to develop Android
apps. [Install it](https://flutter.dev/docs/get-started/install/linux) with your favorite
installation method.

### VSCode

We are using VSCode and therefore document the process for this IDE. Of course you're free to use
whatever you want.
Clone the ğecko repo and open a dart file (e.g. `lib/main.dart`). VSCode will suggest you to insall
relevant extensions.

### Launch the app in debug mode

Start a VM, then open a dart file (e.g. `lib/main.dart`), type the `F5` key to build the code. The app should open
automatically in your VM which is running.

### Build APK

You will need to generate PlayStore key or disable signing APK before continue.
Then, check this script and launch it:

```
./scripts/build-apk.sh 
```

### Translations

You can contribute to translation of the app via our weblate: https://translate.nikoserveur.com/projects/gecko/

### Unit tests

Run unit tests with:

```
flutter test
```

Tests use durt2's test mode (`DurtTestMode.init()`) to mock blockchain services without network connections. See `test/providers/` for examples.

### A problem ?

Please open an issue here: https://git.duniter.org/clients/gecko/-/boards
