#!/bin/bash

for f in ./*.php; do
    if [ $f == "./commandbar.php" ] || [ $f == "./constants.php" ]; then
        continue
    fi
    php $f > ${f%.php}.hxml;
done
php ./commandbar.php > .vscode/commandbar.json