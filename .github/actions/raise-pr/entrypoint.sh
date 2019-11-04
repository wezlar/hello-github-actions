#!/bin/bash

# Suggested by Github actions to be strict
set -e
set -o pipefail

################################################################################
# Global Variables (we can't use GITHUB_ prefix)
################################################################################

API_VERSION=v3
BASE=https://api.github.com
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
HEADER="Accept: application/vnd.github.${API_VERSION}+json"
HEADER="${HEADER}; application/vnd.github.antiope-preview+json; application/vnd.github.shadow-cat-preview+json"

# URLs
REPO_URL="${BASE}/repos/${GITHUB_REPOSITORY}"
PULLS_URL=$REPO_URL/pulls

################################################################################
# Helper Functions
################################################################################


check_credentials() {

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        echo "You must include the GITHUB_TOKEN as an environment variable."
        exit 1
    fi

}

check_events_json() {

    if [[ ! -f "${GITHUB_EVENT_PATH}" ]]; then
        echo "Cannot find Github events file at ${GITHUB_EVENT_PATH}";
        exit 1;
    fi
    echo "Found ${GITHUB_EVENT_PATH}";

}

create_pull_request() {

    SOURCE="${1}"  # from this branch
    TARGET="${2}"  # pull request TO this target
    BODY="${3}"    # this is the content of the message
    TITLE="${4}"   # pull request title

    # Check if the branch already has a pull request open

    DATA="{\"base\":\"${TARGET}\", \"head\":\"${SOURCE}\", \"body\":\"${BODY}\"}"
    RESPONSE=$(curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" --user "${GITHUB_ACTOR}" -X GET --data "${DATA}" ${PULLS_URL})
    PR=$(echo "${RESPONSE}" | jq --raw-output '.[] | .head.ref')
    echo "Response ref: ${PR}"

    # Option 1: The pull request is already open
    if [[ "${PR}" == "${SOURCE}" ]]; then
        echo "Pull request from ${SOURCE} to ${TARGET} is already open!"

    # Option 2: Open a new pull request
    else
        # Post the pull request
        DATA="{\"title\":\"${TITLE}\", \"body\":\"${BODY}\", \"base\":\"${TARGET}\", \"head\":\"${SOURCE}\"}"
        echo "curl --user ${GITHUB_ACTOR} -X POST --data ${DATA} ${PULLS_URL}"
        curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" --user "${GITHUB_ACTOR}" -X POST --data "${DATA}" ${PULLS_URL}
        echo $?
    fi
}


main () {

    # path to file that contains the POST response of the event
    # Example: https://github.com/actions/bin/tree/master/debug
    # Value: /github/workflow/event.json
    check_events_json;
    # Get the name of the action that was triggered
    BRANCH=$(jq --raw-output .ref "${GITHUB_EVENT_PATH}");
    BRANCH=$(echo "${BRANCH/refs\/heads\//}")
    echo "Found branch $BRANCH"

    # User specified branch to PR to, and check
    if [ -z "${BRANCH_FROM}" ]; then
        echo "No branch from is set, master will be used."
        BRANCH_FROM=GITHUB_REF
    fi
    BRANCH_FROM=$(echo "${BRANCH_FROM/refs\/heads\//}")
    echo "Pull request is raised from is $BRANCH_FROM"

    if [ -z "${BRANCH_TO}" ]; then
        BRANCH_TO=develop
    fi
    BRANCH_TO=$(echo "${BRANCH_TO/refs\/heads\//}")
    echo "Pull requests will go to ${BRANCH_TO}"

    # If it's to the target branch, ignore it
    if [[ "${BRANCH}" == "${BRANCH_TO}" ]]; then
        echo "Target and current branch are identical (${BRANCH}), skipping."
    else

        echo "=> DEAN TEST BRANCH: ${BRANCH} - ${BRANCH_FROM} "
        # If the from branch matches the to branch
        if  [[ $BRANCH == ${BRANCH_FROM} ]]; then

            # Ensure we have a GitHub token
            check_credentials

            # Pull request body (optional)
            if [ -z "${PULL_REQUEST_BODY}" ]; then
                echo "No pull request body is set, will use default."
                PULL_REQUEST_BODY="This is an automated pull request to update ${BRANCH_TO} with the latest code from ${BRANCH}"
            fi
            echo "Pull request body is ${PULL_REQUEST_BODY}"

            # Pull request title (optional)
            if [ -z "${PULL_REQUEST_TITLE}" ]; then
                echo "No pull request title is set, will use default."
                PULL_REQUEST_TITLE="${BRANCH} -> ${BRANCH_TO}"
            fi
            echo "Pull request title is ${PULL_REQUEST_TITLE}"

            create_pull_request "${BRANCH}" "${BRANCH_TO}" "${PULL_REQUEST_BODY}" "${PULL_REQUEST_TITLE}"

        fi

    fi
}

echo "==========================================================================
START: Running Pull Request on Branch Update Action!";
main;
echo "==========================================================================
END: Finished";
