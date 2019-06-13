#!/usr/bin/env bash

LOCKDIR="/tmp/google-terraform-url-map-updater-$URL_MAP_NAME"

if ! mkdir "$LOCKDIR" 2>/dev/null; then
    started="$(date +%s)"
    while true; do
        if ! mkdir "$LOCKDIR" 2>/dev/null; then
            if [[ "$((`date +%s` - $started))" -gt 300 ]]; then
                printf "been waiting for more than 300 seconds to update url-map. aborting.\n"
                exit 1
            fi

            printf "url-map is locked for updating. waiting to retry.\n"
            sleep 5
        else
            printf "url-map is open for updating. continuing to update.\n"
            break
        fi
    done
fi


set -ex

trap "rm -fr ${LOCKDIR}; exit" EXIT
export CLOUDSDK_CORE_PROJECT="$PROJECT_ID"

gcloud compute url-maps set-default-service "$URL_MAP_NAME" --default-service="$DUMMY_SERVICE_LINK"
gcloud compute url-maps remove-path-matcher "$URL_MAP_NAME" --path-matcher-name "$PATH_MATCHER_NAME"
