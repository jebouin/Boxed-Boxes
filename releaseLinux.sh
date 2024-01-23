#!/bin/bash

gameName=$(yq .gameName constants.yaml)
gameId=$(yq .gameId constants.yaml)
releaseDir="bin/${gameName} Linux"

./prebuild.sh
haxe build.desktop.release.hxml
rm -rf "${releaseDir}"
cp -r bin/hashlink/linux "${releaseDir}"
cp "bin/release/${gameId}.hl" "${releaseDir}/hlboot.dat"
cp bin/pak/resDesktop.pak "${releaseDir}/res.pak"
mv "${releaseDir}/hl" "${releaseDir}/${gameName}"

cd "${releaseDir}" || exit
rm -rf \
Brewfile \
CMakeLists.txt \
hl.sln \
hl.vcxproj \
hl.vcxproj.filters \
include/ \
libhl.vcxproj \
libhl.vcxproj.filters \
libs/ \
LICENSE \
Makefile \
mysql.hdll \
other/ \
README.md \
sqlite.hdll \
src/
cd ../.. || exit

cd bin || exit
rm -rf "${gameName} Linux.zip"
zip "${gameName} Linux.zip" -r "${gameName} Linux"
cd .. || exit
echo Done!
