#!/bin/sh
set -e
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

export PATH="$(pwd)/tools":$PATH

source "$(pwd)/tools/shell_helper.sh"
source "$(pwd)/tools/shell_const.sh"

OP_COMMAND=$CMD_UNKNOWN

USING_CARTHAGE=$FALSE
USING_SYNC=$FALSE
USING_REINSTALL=$FALSE

JOB_WORKSPACE=""
JOB_TARGET=""

for i in "$@"; do
    case $i in
    --install | -i) # install and fetch all dep sources
        OP_COMMAND=$CMD_INSTALL
        ;;
    --update | -u) # update resolve
        OP_COMMAND=$CMD_UPDATE
        ;;
    --bootstrap | -b) # build all dep project
        OP_COMMAND=$CMD_BOOTSTRAP
        ;;
    --target=* | -t=*)
        JOB_TARGET="${i#*=}"
        ;;
    # --reinstall | -r)
    #     USING_REINSTALL=$TRUE
    #   ;;
    --using-carthage | -c)
        USING_CARTHAGE=$TRUE
        ;;
    --sync | -s)
        USING_SYNC=$TRUE
        ;;
    *) # unknown, now maybe a fold
        JOB_WORKSPACE=$i
        ;;
    esac
done

if [ $OP_COMMAND = $CMD_UNKNOWN ]; then
    echo "unknown operation"
    showUsage
    exit 1
fi

if [ "$JOB_TARGET" = "" ]; then
    echo "target name was empty"
    showUsage
    exit 1
fi

if [ "$JOB_WORKSPACE" = "" ]; then
    JOB_WORKSPACE=$(pwd)
fi

# get full path about workspace
JOB_WORKSPACE=$(to_abs_path $JOB_WORKSPACE)

CONTRIB_ROOT=contrib

if [ $OP_COMMAND == $CMD_INSTALL ]; then
    cp $JOB_WORKSPACE/templates/panda-ios-project.pbxproj $JOB_WORKSPACE/$JOB_TARGET.xcodeproj/project.pbxproj

    rm -rf $JOB_WORKSPACE/Carthage/Checkouts
    rm -rf $JOB_WORKSPACE/Carthage/Build

    if [ $OP_COMMAND == $CMD_INSTALL ]; then
        rm -rf $JOB_WORKSPACE/Carthage
    fi
fi

# checkout the workspace basic env settings
do_check_env

# ready for call ruby project, before that, parameter list should be ready now.
params="--workspace=$JOB_WORKSPACE --target=$JOB_TARGET --command=$OP_COMMAND"
if [ $USING_CARTHAGE == $TRUE ]; then
    params="$params --using-carthage"
fi

if [ $USING_SYNC == $TRUE ]; then
    params="$params --sync"
fi

# if [ $USING_REINSTALL == $TRUE ]; then
#     params="$params --reinstall"
# fi

# echo $params
ruby tools/panthage_core.rb $params
