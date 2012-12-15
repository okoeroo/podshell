#!/bin/bash

PODLIST="podcast.list"
TMPDIR="/tmp/podget"
PODDROPDIR="${TMPDIR}/poddropdir"
TMPFILE="${TMPDIR}/foo.tmp"
TOP=3

TEMPLATE_PODLIST_FILE="podlist.xml"
TEMPLATE_TO_DOWNLOAD_URLS="to_download.urls"
TEMPLATE_SUCCESSFUL_DOWNLOAD_URLS="successful_downloads.urls"
TEMPLATE_FAILED_DOWNLOAD_URLS="failed_downloads.urls"


function download_rss() {
    i=0
    cat "${PODLIST}" | while read PODURL; do
        mkdir -p "${PODDROPDIR}/$i" || exit 1

        echo ":: \"$PODURL\" to \"${PODDROPDIR}/$i/${TEMPLATE_PODLIST_FILE}\" ::"
        curl -s -o "${PODDROPDIR}/$i/${TEMPLATE_PODLIST_FILE}" $PODURL

        i=$(($i+1))
    done
}

function deduct_filename_from_url() {
    URL=$1
    FILE=`basename ${URL}`

    # Remove URL Query
    echo "$FILE" | sed 's/\(.*\)?.*/\1/'
    return 0
}

function parse_download_url_from_rss() {
    for pod in ${PODDROPDIR}/*/; do
        # URLs
        echo ":: Extract URLs from \"${pod}/${TEMPLATE_PODLIST_FILE}\" into \"${pod}/${TEMPLATE_TO_DOWNLOAD_URLS}\""
        cat "${pod}/${TEMPLATE_PODLIST_FILE}" | \
            grep enclosure | \
            sed 's/.*<enclosure url="\([^"]*\).*/\1/' > "${pod}/${TEMPLATE_TO_DOWNLOAD_URLS}"

    done
}

function download_urls() {
    for pod in ${PODDROPDIR}/*/; do
        cat "${pod}/${TEMPLATE_TO_DOWNLOAD_URLS}" | head -n ${TOP} | while read PODCAST_URL; do
            # Generate a proper filename
            FILE=$(deduct_filename_from_url ${PODCAST_URL})

            echo ":: Downloading \"${PODCAST_URL}\" as \"${PODDROPDIR}/${FILE}\" ::"
            curl --continue-at - --location --output ${PODDROPDIR}/${FILE} ${PODCAST_URL}
            RC=$?
            if [ "$RC" = "0" ]; then
                echo "${PODCAST_URL}" >> ${pod}/${TEMPLATE_SUCCESSFUL_DOWNLOAD_URLS}
            else
                echo "${PODCAST_URL}" >> ${pod}/${TEMPLATE_FAILED_DOWNLOAD_URLS}
            fi
        done
    done
}


function create_tmpdir() {
    echo ":: Create \"${TMPDIR}\" ::"
    mkdir -p "${TMPDIR}"

    echo ":: Create \"${PODDROPDIR}\" ::"
    mkdir -p "${PODDROPDIR}"
}


### MAIN ###
create_tmpdir
download_rss
parse_download_url_from_rss
download_urls
