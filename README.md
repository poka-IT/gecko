# Ğecko

Ğecko is a transaction client owned by [Axiom-Team association] and written in Dart. It is fast and secure thanks to native code compilation. It is not intended to manage member accounts, but rather simple wallets.

The development is quite early, you can participate in the discussion [on the Duniter forum](https://forum.duniter.org/t/gecko-nouveau-client-de-paiements-1-sur-mobile-en-cours-de-developpement-dart-flutter/7857) (mostly FR)

[Axiom-Team association]: https://axiom-team.fr/

## Getting Started

<div align="center">

![Demo Gif](https://git.duniter.org/clients/gecko/-/raw/master/images/demo-0.0.9+2.gif)

<br><br>
</div>

## Develop

To contribute to the code, we advise you to install the following development environment.

1. Android Studio
  - Android VM 
  - Android NDK
1. Flutter SDK
1. VSCode/Codium Flutter extension

This will take about 12GB on your drive and 30 min of your time (with a good connection). Don't hesitate to ask on the forum for a peer-coding session if you are stuck. 

### Android Studio

Android Studio will let you set up an Android VM and install tools you need.

- Install [Android Studio](https://developer.android.com/studio/) using your favorite installation method.
- At startup, do not open a project but click "configure" at the bottom of the "Welcome" menu
- In "SDK Manager"
    - SDK Platforms Ttab
        - note your SDK folder location (later used for Rust environment variables)
        - select Android 11 (R) API level 30 (default)
    - SDK Tools
        - select NDK (native development kit used to compile Rust to native target)
- In "AVD Manager"
    - create a virtual machine (ours is Pixel 4 32bits machine)
    - launch it in the emulator

If you reach this point without trouble, you're good to go for the next step.

### Flutter SDK

Flutter is a powerfull SDK to develop Android apps. [Install it](https://flutter.dev/docs/get-started/install/linux) with your favorite installation method.

### VSCode

We are using VSCode and therefore document the process for this IDE. Of course you're free to use whatever you want.
Clone the ğecko repo and open a dart file (e.g. `lib/main.dart`). VSCode will suggest you to insall relevant extensions.

### Build the app

In a dart file (e.g. `lib/main.dart`), type the `F5` key to build the code. The app should open automatically in your VM which is running.

### Build your app for Desktop

#### Linux

Install dependancies:

`sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`

Then build debug for linux:

`flutter run -d linux`

If you get this error:

```
flutter /usr/share/cmake-3.16/Modules/FindPkgConfig.cmake:643 (_pkg_check_modules_internal)
```

Please try:

`sudo apt install liblzma-dev`

then

`flutter clean && flutter run -d linux`

## Roadmap

-> https://pad.p2p.legal/gecko-roadmap-2022?view
