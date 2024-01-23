#!/bin/bash

gameName=$(yq .gameName constants.yaml)
gameNameItch=$(echo "${gameName}" | perl -ne 'print lc' | perl -p -e 's/\ /-/g')
gameVersion=$(yq .gameVersion constants.yaml)
fileLinux="bin/${gameName} Linux.zip"
fileWindows="bin/${gameName} Windows.zip"

# Backup current version
rm -rf "bin/old/${gameVersion}"
mkdir "bin/old/${gameVersion}"
cp "${fileLinux}" "bin/old/${gameVersion}"
cp "${fileWindows}" "bin/old/${gameVersion}"