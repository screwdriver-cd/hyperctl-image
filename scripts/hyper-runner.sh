#!/bin/bash -e

# Trap the EXIT SIGNAL and update build status to failure
trap cleanUp EXIT

function cleanUp {
    if [ "$?" = "0" ]
    then
        echo "exit with exit code 0"
        exit 0
    fi
    echo "exit with non-zero code"
    updateBuildStatus
}

function updateBuildStatus {
    ERROR="$1"

    # If no custom error, then use the generic one
    if [[ -z "$ERROR" ]]
    then
        ERROR="Build failed to start. Please reach out to your cluster admin for help."
    fi

    URL=$API_URI/v4/builds/$BUILD_ID
    echo "Updating build status: $URL"
    curl -X PUT -H "Authorization: Bearer $BUILD_TOKEN" -H "Content-Type: application/json" \
    -d '{"status": "FAILURE", "statusMessage": "'"$ERROR"'"}' $URL
}

function log {
  MESSAGE="$1"
  echo "$MESSAGE"
}

function printUsage {
  USAGE="hyper-runner.sh --container <build_container>
                --api_uri <sd_api_uri>
                --build_id <build_id>
                --store_uri <store_uri>
                --id_with_prefix <build_id_with_prefix>
                --build_token <sd_token>
                --cpu <cpu>
                --memory <memory>"
  log "$USAGE";
  exit 1;
}

function checkVal {
  ARGUMENT="$1"
  VALUE="$2"
  if [[ -z "$VALUE" || "$VALUE" == -* ]]; then
    log "Argument $ARGUMENT needs value"
    printUsage;
  fi;
}

# Capture input arguments
while [[ $# -gt 0 ]]
 do
  key="$1"

  case $key in
    -c|--container)          BUILD_CONTAINER="$2"; checkVal $1 $2 ; shift 2 ;;
    -a|--api_uri)            API_URI="$2"        ; checkVal $1 $2 ; shift 2 ;;
    -b|--build_id)           BUILD_ID="$2"       ; checkVal $1 $2 ; shift 2 ;;
    -s|--store_uri)          STORE_URI="$2"      ; checkVal $1 $2 ; shift 2 ;;
    -i|--id_with_prefix)     ID_WITH_PREFIX="$2" ; checkVal $1 $2 ; shift 2 ;;
    -u|--build_token)        BUILD_TOKEN="$2"    ; checkVal $1 $2 ; shift 2 ;;
    -cpu|--cpu)              CPU="$2"            ; checkVal $1 $2 ; shift 2 ;;
    -m|--memory)             MEMORY="$2"         ; checkVal $1 $2 ; shift 2 ;;
    -h|--help)               printUsage                           ; shift 1 ;;
    -*) echo "Unkown argument: \"$key\"" ; printUsage             ; exit 1  ;;
    *)                                                              break   ;;
  esac
done

# If any of the required arguments are unset or set to empty, exit gracefully
# PS: Do not use array of key value pairs to shorten the below code. It works
# with bash 4 on linux but not on Alpine bash!. Been there.
if [[ -z "$BUILD_CONTAINER" ]]; then
  log "--container is a required argument";
  printUsage;
fi
if [[ -z "$API_URI" ]]; then
  log "--api_uri is a required argument";
  printUsage;
fi
if [[ -z "$BUILD_ID" ]]; then
  log "--build_id is a required argument";
  printUsage;
fi
if [[ -z "$STORE_URI" ]]; then
  log "--store_uri is a required argument";
  printUsage;
fi
if [[ -z "$ID_WITH_PREFIX" ]]; then
  log "--id_with_prefix is a required argument";
  printUsage;
fi
if [[ -z "$BUILD_ID" ]]; then
  log "--build_id is a required argument";
  printUsage;
fi
if [[ -z "$CPU" ]]; then
  CPU=2;
fi
if [[ -z "$MEMORY" ]]; then
  MEMORY=2048;
fi

# Remove leading and trailing quotes from CPU and MEMORY
CPU=`sed -e 's/^"//' -e 's/"$//' <<< "$CPU"`
MEMORY=`sed -e 's/^"//' -e 's/"$//' <<< "$MEMORY"`

# Pull latest docker image
HYPERCTL=/usr/bin/hyperctl
# Making sure hyperd is not crashed
$HYPERCTL info
if $HYPERCTL pull $BUILD_CONTAINER
then
    echo "Successfully pulled the image"
else
    updateBuildStatus "Build failed to start. Please check if your image is valid."
    exit 0
fi

HYPER_TEMPLATE="/sd/hyper-pod-template.json"
HYPER_POD_SPEC="/tmp/hyper-pod.json"
sed -e "s|BUILD_CONTAINER|${BUILD_CONTAINER}|g;
        s|API_URI|${API_URI}|g;
        s|BUILD_ID|${BUILD_ID}|g;
        s|STORE_URI|${STORE_URI}|g;
        s|BUILD_TOKEN|${BUILD_TOKEN}|g;
        s|ID_WITH_PREFIX|${ID_WITH_PREFIX}|g;
        s|\"CPU\"|${CPU}|g;
        s|\"MEMORY\"|${MEMORY}|g;" $HYPER_TEMPLATE > $HYPER_POD_SPEC;

log 'Running hyperctl...'
res=`$HYPERCTL run --rm -a -p $HYPER_POD_SPEC`
log "Build finished with exit code $? : $res"
