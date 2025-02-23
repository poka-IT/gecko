#/bin/bash

cd ios/
rm -f Podfile.lock 
rm -rf Pods/
pod install --repo-update
fvm flutter clean && fvm flutter pub get
cd ..

