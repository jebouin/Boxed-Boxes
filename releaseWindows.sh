#!/bin/bash

gameName=$(yq .gameName constants.yaml)
gameId=$(yq .gameId constants.yaml)
releaseDir="bin/${gameName} Windows"

./prebuild.sh
haxe build.desktop.release.hxml
rm -rf "${releaseDir}"
cp -r bin/hashlink/windows "${releaseDir}"
cp "bin/release/${gameId}.hl" "${releaseDir}/hlboot.dat"
cp bin/pak/resDesktop.pak "${releaseDir}/res.pak"
mv "${releaseDir}/hl.exe" "${releaseDir}/${gameName}.exe"

# Remove unnecessary files
cd "${releaseDir}" || exit
rm -rf \
directx.hdll \
directx.lib \
dx12.hdll \
dx12.lib \
include/ \
mysql.hdll \
mysql.lib \
sqlite.hdll \
sqlite.lib
cd ../.. || exit

# Add icon
ffmpeg -y -i res/gfx/icons/icon.png res/gfx/icons/icon.ico
icotool -c -o res/gfx/icons/icon.ico res/gfx/icons/icon.png
(exec wine tools/rcedit.exe "${releaseDir}/${gameName}.exe" "--set-icon" "res/gfx/icons/icon.ico") & sleep 5 ; kill $!

# Create zip
cd bin || exit
rm -rf "${gameName} Windows.zip"
zip "${gameName} Windows.zip" -r "${gameName} Windows"
cd .. || exit
echo Done!