#!/bin/bash

set -e

help_string=usage="$(basename "$0") -- script to remove unused files from Arch Linux base installation

Compulsory parameters:
    --root - path to root of Arch Linux installation
"

for i in "$@"
do
case $i in
    -h|--help)
    >&2 echo "$help_string"
    exit 1
    shift
    ;;
    --root=*)
    ARCH_LINUX_ROOT="${i#*=}"
    shift
    ;;
    *)
    >&2 echo "Uknown option '$i'"
    exit 1
    ;;
esac
done

if [ -z "$ARCH_LINUX_ROOT" ]; then
    >&2 echo "Assuming absolute file system root as Arch Linux installation to be looked at."
    ARCH_LINUX_ROOT="/"
fi;

if [ ! -d "$ARCH_LINUX_ROOT" ]; then
    >&2 echo "Incorrect path provided as root of Arch Linux installation."
    exit 1
fi;

cd "$ARCH_LINUX_ROOT"

# inspired by https://unix.stackexchange.com/questions/2027/how-do-i-minimize-disk-space-usage/233401#233401

echo "Removing unused locale, leaving only en_US locale"
mv -vf usr/share/locale/{en_US,locale.alias} /tmp
rm -rf usr/share/locale/*
mv -vf /tmp/{en_US,locale.alias} usr/share/locale/
mv -vf usr/share/i18n/locales/{en_US,en_GB,i18n,i18n_ctype,iso14651_t1,iso14651_t1_common,translit_*} /tmp
rm -rf usr/share/i18n/locales/*
mv -vf /tmp/{en_US,en_GB,i18n,i18n_ctype,iso14651_t1,iso14651_t1_common,translit_*} usr/share/i18n/locales/

echo "Removing unused timezones, leaving only UTC timezone"
mv -vf usr/share/zoneinfo/UTC /tmp
rm -rf usr/share/zoneinfo/*
mv -vf /tmp/UTC usr/share/zoneinfo

echo "Removing man pages"
rm -rf usr/share/man/*
rm -rf usr/share/info/*
rm -rf usr/share/doc/*

echo "Removing include and *.a files"
rm -f usr/lib/*.a
rm -rf usr/include/*

echo "Not planning to use programs written in GO"
rm -f usr/lib/libgo.so*
