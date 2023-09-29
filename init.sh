#!/bin/bash

./clean.sh

read -p "Enter game name: " gameName
read -p "Enter game id: " gameId
rm constants.yaml
printf "gameName: $gameName\n" >> constants.yaml
printf "gameId: $gameId\n" >> constants.yaml
printf "gameVersion: 1.0.0\n" >> constants.yaml
printf "windowSize: 1600x900" >> constants.yaml

read -p "Create new repo? (y/n): " createRepo
if [ $createRepo == "y" ]; then
    gh auth login
    repoName="${gameName// /-}"
    read -p "Enter GitHub token: " token
    cp -r .git/hooks .
    sudo rm -rf .git
    git init
    git branch -m main
    rm .git/hooks -r
    mv hooks .git
    git add .
    gh repo create $repoName --private
    git remote add origin https://jebouin:${token}@github.com/jebouin/${repoName}.git
    git commit -m "Initial commit"
fi
php ./commandbar.php > .vscode/commandbar.json