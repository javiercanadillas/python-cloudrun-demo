#!/usr/bin/env bash
# Import config vars
. config_vars
# Styling echo
bold=$(tput bold)
normal=$(tput sgr0)

# Prepare environment
prep_env() {
    echo "${bold}Preparing environment...${normal}"
    gcloud config set project "${PROJECT_ID}"
    gcloud config set compute/zone "${ZONE}"
    # Enable these APIs in the project, needed to create the cluster, build and publish the container into GCR
    gcloud services enable \
        container.googleapis.com \
        containerregistry.googleapis.com \
        cloudbuild.googleapis.com
}

# Create Cluster
create_cluster() {
    echo "${bold}Creating Cloud Run ready GKE cluster...${normal}"
    gcloud container clusters create "${CLUSTER_NAME}" \
        --zone="${ZONE}" \
        --addons=HttpLoadBalancing,CloudRun \
        --machine-type=n1-standard-2 \
        --num-nodes=3 \
        --cluster-version="${GKE_VERSION}" \
        --enable-stackdriver-kubernetes
}

# Setup Cloud Run
setup_cloudrun() {
    echo "${bold}Setting up Cloud run in ${1} mode...${normal}"
    gcloud config set run/platform "${1}"
    case $1 in
    gke)
        gcloud config set run/cluster "${CLUSTER_NAME}"
        gcloud config set run/cluster_location "${ZONE}"
        gcloud container clusters get-credentials "${CLUSTER_NAME}"
        ;;
    managed)
        gcloud config set run/region "${REGION}"
        ;;
    esac
}

# Create Cloud Run namespace in the cluster
setup_namespace() {
    echo "${bold}Setting up GKE Cloud Run namespace...${normal}"
    kubectl create namespace "${NAMESPACE}"
    gcloud config set run/namespace "{$NAMESPACE}"
}

# Help
usage() {
    echo "Usage: $0 [-h] -m MODE <gke|managed> create | function <function_name>" 1>&2
    exit 1
}

# List all functions
list() {
    declare -F | awk '{print $3}'
}

while getopts ":m:h" o; do
    case "${o}" in
    m)
        MODE="${OPTARG}"
        ;;
    h)
        usage
        ;;
    \?)
        echo "Invalid Option: -${OPTARG}" 1>&2
        exit 1
        ;;
    :) 
        echo "Invalid Option: -${OPTARG} requires an argument" 1>&2
        exit 1
        ;;
    esac
done
# Process additional parameters after options. Not used for now.
shift "$((OPTIND - 1))"

# Process subcommands, mainly create, function and submit
subcommand=$1; shift
case "${subcommand}" in
    create)
        case "${MODE}" in
        gke)
            prep_env &&
            create_cluster &&
            setup_cloudrun "${MODE}" &&
            setup_namespace
            ;;
        managed)
            prep_env &&
            setup_cloudrun "${MODE}"
            ;;
        *)
            echo "Unrecognized mode. Try 'gke' or 'managed'."
            exit 1
            ;;
        esac
        ;;
    function)
        FUNCTION=$1; shift
        "${FUNCTION}" "${MODE}" 
        ;;
    submit)
        gcloud builds submit \
            --config=cloudbuild-"${MODE}".yaml \
            --substitutions=_SERVICENAME="${SERVICENAME}", \
                _CLUSTER_NAME="${CLUSTER_NAME}", \
                _ZONE="${ZONE}", \
                _MODE="${MODE}" \
                _REGION="${REGION}" \
            .
        ;;
    *)
        echo "You must provide a command."
        exit 1
        ;;
esac