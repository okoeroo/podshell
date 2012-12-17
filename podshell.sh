#!/bin/bash

# PODLIST="podcast.list"
# PODDROPDIR="/tmp/poddropdir"
# TOP=3

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

function already_downloaded() {
    URL="$1"
    POD="$2"

    ## When nothing is downloaded yet, the success-file doens't exist yet
    if [ ! -f "${POD}/${TEMPLATE_SUCCESSFUL_DOWNLOAD_URLS}" ]; then
        return 0
    fi

    ## Lookup entry in the success-file.
    grep "${URL}" ${POD}/${TEMPLATE_SUCCESSFUL_DOWNLOAD_URLS} > /dev/null
    RC=$?
    return $RC
}

function download_urls() {
    for pod in ${PODDROPDIR}/*/; do
        cat "${pod}/${TEMPLATE_TO_DOWNLOAD_URLS}" | head -n ${TOP} | while read PODCAST_URL; do
            # Generate a proper filename
            FILE=$(deduct_filename_from_url ${PODCAST_URL})

            already_downloaded "${PODCAST_URL}" "${pod}"
            RC=$?
            if [ ${RC} -eq 0 ]; then
                echo ":: Already downloaded \"${PODCAST_URL}\" as \"${pod}/${FILE}\" ::"
                continue
            fi

            echo ":: Downloading \"${PODCAST_URL}\" as \"${pod}/${FILE}\" ::"
            curl --continue-at - --location --output ${pod}/${FILE} ${PODCAST_URL}
            RC=$?
            if [ "$RC" = "0" ]; then
                echo "${PODCAST_URL}" >> ${pod}/${TEMPLATE_SUCCESSFUL_DOWNLOAD_URLS}
                ln -f -s ${pod}/${FILE} ${PODDROPDIR}/${FILE}
            else
                echo "${PODCAST_URL}" >> ${pod}/${TEMPLATE_FAILED_DOWNLOAD_URLS}
            fi
        done
    done
}


function create_tmpdir() {
    echo ":: Create \"${PODDROPDIR}\" ::"
    mkdir -p "${PODDROPDIR}"
}


### MAIN ###
CONF_FILE="podshell.conf"

while getopts c: options
do
    case "$options" in
    c)  CONF_FILE="$OPTARG";;
    *)  echo "Usage: "
        echo "       $0 [-c <path to configuration file>"
        exit 1;;
    esac
done;

if [ ! -f "${CONF_FILE}" ]; then
    echo ":: Error: The configuration file \"${CONF_FILE}\" does not exist ::"
    exit 1
else
    echo ":: Using configuration file \"${CONF_FILE}\" ::"
fi

# Source config
. "${CONF_FILE}"

create_tmpdir
download_rss
parse_download_url_from_rss
download_urls

exit 0
