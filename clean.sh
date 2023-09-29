#!/bin/bash

# Remove generated build files
for f in ./*.php; do rm -f ${f%.php}.hxml; done

# Remove binaries
rm -f bin/*.pak
rm -f bin/*.zip
rm -f bin/hl/*
rm -f bin/itch/*
rm -f bin/js/*.html
rm -f bin/js/*.pak
rm -f bin/js/*.js
rm -f bin/newgrounds/*