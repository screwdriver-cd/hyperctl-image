#!/bin/bash -e

# Trap these SIGNALs to cleanup workspace and update build status to failure
trap cleanUp HUP INT QUIT TERM EXIT

function cleanUp {
    if [ "$?" = "0" ]
    then
        cleanupWorkspaces
        echo "exit with exit code 0"
        exit 0
    fi
    echo "exit with non-zero code"

    cleanupWorkspaces
    updateBuildStatus
}

function cleanupWorkspaces {
    echo "cleanup used vm..."
    $HYPERCTL rm "builder-$ID_WITH_PREFIX"
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
    -d '{"status": "FAILURE", "statusMessage": "'"$ERROR"'"}' "$URL"
}

function log {
  MESSAGE="$1"
  echo "$MESSAGE"
}

function printUsage {
  USAGE="hyper-runner.sh --container <build_container>
                --api_uri <sd_api_uri>
                --build_id <build_id>
                --job_id <job_id>
                --event_id <event_id>
                --pipeline_id <pipeline_id>
                --store_uri <store_uri>
                --ui_uri <sd_ui_uri>
                --id_with_prefix <build_id_with_prefix>
                --build_token <sd_token>
                --cpu <cpu>
                --memory <memory>
                --build_timeout <seconds>
                --launcher_version <launcher_version_tag>
                --cache_strategy <cache_strategy (disk | s3)>
                --cache_path <cache_path (if cache_strategy is disk)>
                --cache_compress <cache_compress>
                --cache_md5check <cache_md5check>
                --cache_max_size_mb <cache_max_size_mb>
                --cache_max_go_threads <cache_max_go_threads>"

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
    -c|--container)               BUILD_CONTAINER="$2"      ; checkVal $1 $2 ; shift 2 ;;
    -a|--api_uri)                 API_URI="$2"              ; checkVal $1 $2 ; shift 2 ;;
    -b|--build_id)                BUILD_ID="$2"             ; checkVal $1 $2 ; shift 2 ;;
    -j|--job_id)                  JOB_ID="$2"               ; checkVal $1 $2 ; shift 2 ;;
    -e|--event_id)                EVENT_ID="$2"             ; checkVal $1 $2 ; shift 2 ;;
    -p|--pipeline_id)             PIPELINE_ID="$2"          ; checkVal $1 $2 ; shift 2 ;;
    -s|--store_uri)               STORE_URI="$2"            ; checkVal $1 $2 ; shift 2 ;;
    -ui|--ui_uri)                 UI_URI="$2"               ; checkVal $1 $2 ; shift 2 ;;
    -i|--id_with_prefix)          ID_WITH_PREFIX="$2"       ; checkVal $1 $2 ; shift 2 ;;
    -u|--build_token)             BUILD_TOKEN="$2"          ; checkVal $1 $2 ; shift 2 ;;
    -cpu|--cpu)                   CPU="$2"                  ; checkVal $1 $2 ; shift 2 ;;
    -m|--memory)                  MEMORY="$2"               ; checkVal $1 $2 ; shift 2 ;;
    -t|--build_timeout)           SD_BUILD_TIMEOUT="$2"     ; checkVal $1 $2 ; shift 2 ;;
    -v|--launcher_version)        LAUNCHER_VERSION="$2"     ; checkVal $1 $2 ; shift 2 ;;
    -cs|--cache_strategy)         CACHE_STRATEGY="$2"       ; checkVal $1 $2 ; shift 2 ;;
    -chp|--cache_path)            CACHE_PATH="$2"           ; checkVal $1 $2 ; shift 2 ;;
    -cc|--cache_compress)         CACHE_COMPRESS="$2"       ; checkVal $1 $2 ; shift 2 ;;
    -cm5|--cache_md5check)        CACHE_MD5CHECK="$2"       ; checkVal $1 $2 ; shift 2 ;;
    -cb|--cache_max_size_mb)      CACHE_MAX_SIZE_MB="$2"    ; checkVal $1 $2 ; shift 2 ;;
    -cgt|--cache_max_go_threads)  CACHE_MAX_GO_THREADS="$2" ; checkVal $1 $2 ; shift 2 ;;
    -h|--help)               printUsage                              ; shift 1 ;;
    -*) echo "Unkown argument: \"$key\"" ; printUsage                ; exit 1  ;;
    *)                                                                 break   ;;
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
if [[ -z "$JOB_ID" ]]; then
  log "--job_id is a required argument";
  printUsage;
fi
if [[ -z "$EVENT_ID" ]]; then
  log "--event_id is a required argument";
  printUsage;
fi
if [[ -z "$PIPELINE_ID" ]]; then
  log "--pipeline_id is a required argument";
  printUsage;
fi
if [[ -z "$STORE_URI" ]]; then
  log "--store_uri is a required argument";
  printUsage;
fi
if [[ -z "$UI_URI" ]]; then
  log "defaulting ui_uri to http://localhost:4200";
  UI_URI="http://localhost:4200";
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
if [[ -z "$SD_BUILD_TIMEOUT" ]]; then
  log "defaulting build timeout to 5400s";
  SD_BUILD_TIMEOUT=5400;
fi
if [[ -z "$LAUNCHER_VERSION" ]]; then
  log "--launcher_version is a required argument";
  printUsage;
fi

# Remove leading and trailing quotes from CPU and MEMORY
CPU=$(sed -e 's/^"//' -e 's/"$//' <<< "$CPU")
MEMORY=$(sed -e 's/^"//' -e 's/"$//' <<< "$MEMORY")

# Copy over setup script to share mount sdlauncher
cp /sd/setup.sh /opt/sd/

# Pull latest docker image
HYPERCTL=/usr/bin/hyperctl
# Making sure hyperd is not crashed
$HYPERCTL info
if $HYPERCTL pull "$BUILD_CONTAINER"
then
    echo "Successfully pulled the image"
else
    updateBuildStatus "Build failed to start. Please check if your image is valid."
    exit 0
fi

DISK_CACHE_STRATEGY="disk"
HYPER_TEMPLATE="/sd/hyper-pod-template.json"
HYPER_POD_SPEC="/tmp/hyper-pod.json"

if [[ "$CACHE_STRATEGY" == "$DISK_CACHE_STRATEGY" && ! -z "$CACHE_PATH" ]]; then
  HYPER_TEMPLATE="/sd/hyper-pod-cache-volumes-template.json"
fi

sed -e "s|BUILD_CONTAINER|${BUILD_CONTAINER}|g;
        s|API_URI|${API_URI}|g;
        s|BUILD_ID|${BUILD_ID}|g;
        s|JOB_ID|${JOB_ID}|g;
        s|EVENT_ID|${EVENT_ID}|g;
        s|PIPELINE_ID|${PIPELINE_ID}|g;
        s|SD_BUILD_TIMEOUT|${SD_BUILD_TIMEOUT}|g;
        s|STORE_URI|${STORE_URI}|g;
        s|UI_URI|${UI_URI}|g;
        s|BUILD_TOKEN|${BUILD_TOKEN}|g;
        s|ID_WITH_PREFIX|${ID_WITH_PREFIX}|g;
        s|\"CPU\"|${CPU}|g;
        s|\"MEMORY\"|${MEMORY}|g;
        s|LAUNCHER_VERSION|${LAUNCHER_VERSION}|g;
        s|CACHE_STRATEGY|${CACHE_STRATEGY}|g;
        s|CACHE_PATH|${CACHE_PATH}|g;
        s|CACHE_COMPRESS|${CACHE_COMPRESS}|g;
        s|CACHE_MD5CHECK|${CACHE_MD5CHECK}|g;
        s|CACHE_MAX_SIZE_MB|${CACHE_MAX_SIZE_MB}|g;
        s|CACHE_MAX_GO_THREADS|${CACHE_MAX_GO_THREADS}|g;" $HYPER_TEMPLATE > $HYPER_POD_SPEC;

log 'Running hyperctl...'
res=$($HYPERCTL run --rm -a -p $HYPER_POD_SPEC)
log "Build finished with exit code $? : $res"
