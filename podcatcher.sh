#!/bin/bash

PODLIST="podcast.list"
TMPFILE="foo.tmp"

cat "${PODLIST}" | while read PODURL; do
    echo ": $PODURL :"
    curl -o "${TMPFILE}" $PODURL 
    cat "${TMPFILE}"  | grep enclosure | sed 's/.*<enclosure url="\([^"]*\).*/\1/' > "${TMPFILE}.2"

    cat "${TMPFILE}.2" | while read URL; do
        curl -o `basename $URL` $URL
    done
    rm "${TMPFILE}.2"
    rm "${TMPFILE}"
done

