#!/bin/sh

SUBDIR=sources

if [ ! -f sources.list ] ; then
  echo "sources.list does not exists"
  exit 1;
fi

if [ ! -d "$SUBDIR" ] ; then mkdir "$SUBDIR"; fi
if [ ! -d "$SUBDIR" ] ; then
  echo "$SUBDIR subdirectory does not exists and cannot be created"
  exit 1;
fi

cat sources.list | grep -v -e "^#" -e "^\s*$" | while read A ; do
  echo $A
  (cd "$SUBDIR" && wget -nv -nc --no-check-certificate $A)
done
