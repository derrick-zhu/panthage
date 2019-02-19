#!/bin/sh
set -e
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

if ! type "carthage" &> /dev/null; then
    echo "Detected that you have not installed carthage"
    echo "Please install carthage manually"
    echo "Using brew install carthage"
    exit 1
fi

if ! type "xcodeproj" &> /dev/null; then
    echo "Detected that you have not install xcodeproj"
    echo "Please install xcodeproj manually"
    echo "Using sudo gem install xcodeproj"
    exit 1
fi

export PATH="`pwd`/tools":$PATH
ARG=$1
TARGET=$2

echo "Usage: sh build.sh user|sync|carthage blue|universal|ipad|all"

if [ "${ARG}" = "" ]; then
    ARG=user
fi
if [ "$TARGET" = "" ]; then
    TARGET=universal
fi

. repo-bin.sh

CONTRIB_ROOT=contrib
function do_repo_sync()
{
    REPO_NAME=$1
    REPO_URL=$2
    REPO_HASH=$3
    if [ -z $1 -o -z $2 -o -z $3 ]; then
        echo "invalid call repo_sync() '$1' '$2' '$3'"
    else
    git fetch --all --tags
        git checkout $REPO_HASH -B sandbox
    fi
}

function do_check_bin_sync()
{
    REPO_NAME=$1
    REPO_EXPECT_HASH=$2
    if [ ! -d $REPO_NAME ] || [ ! -f $REPO_NAME/version.txt ] ; then
        if [ ! -f .warehouse/$REPO_EXPECT_HASH ] ; then
            mkdir -p .warehouse
            curl -o .warehouse/$REPO_EXPECT_HASH.tar.bz2 http://172.16.0.97:7070/ibili-ios/bin/ffmpeg/ffmpeg-fat-$REPO_EXPECT_HASH.tar.bz2
        fi
        mkdir -p .warehouse/$REPO_EXPECT_HASH
        tar xvf .warehouse/$REPO_EXPECT_HASH.tar.bz2 -C .warehouse/$REPO_EXPECT_HASH
        ln -s .warehouse/$REPO_EXPECT_HASH/build/universal $REPO_NAME
    fi
    cd $REPO_NAME
    HASH=`cat version.txt`
    if [  $HASH = $REPO_EXPECT_HASH ]; then
        cd ../
        echo "$REPO_NAME is latest"
    else
        cd ../
        rm -rf $REPO_NAME
        do_check_bin_sync $1 $2 
    fi
}

function do_check_res_sync()
{
    # 如果已经检出了 ijkplayer 源码，将之前下载的 ffmpeg 软链到 ijkplayer 工程目录中
    if [ -d Carthage/Checkouts/ijkplayer/ios/ ]; then
        mkdir -p Carthage/Checkouts/ijkplayer/ios/build/
        ln -sf ../../../../../ffmpeg-bin3 Carthage/Checkouts/ijkplayer/ios/build/universal
    fi
    mkdir -p resource-bin
    # 如果已经检出了 BFC 源码，将资源映射到虚拟链接
    if [ -d Carthage/Checkouts/BFC/Components/BFCTXPlayer ]; then
        ln -sf ../Carthage/Checkouts/BFC/Components/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/QLBase.bundle resource-bin/QLBase.bundle
        ln -sf ../Carthage/Checkouts/BFC/Components/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/QLFacility.bundle resource-bin/QLFacility.bundle
        ln -sf ../Carthage/Checkouts/BFC/Components/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/TADAdVideo.bundle resource-bin/TADAdVideo.bundle
        ln -sf ../Carthage/Checkouts/BFC/Components/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/TADQQVideo.bundle resource-bin/TADQQVideo.bundle
    elif [ -d Carthage/Checkouts/BFCTXPlayer ]; then
        ln -sf ../Carthage/Checkouts/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/QLBase.bundle resource-bin/QLBase.bundle
        ln -sf ../Carthage/Checkouts/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/QLFacility.bundle resource-bin/QLFacility.bundle
        ln -sf ../Carthage/Checkouts/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/TADAdVideo.bundle resource-bin/TADAdVideo.bundle
        ln -sf ../Carthage/Checkouts/BFCTXPlayer/BFCTXPlayer/Player/TVKPlayer/TADQQVideo.bundle resource-bin/TADQQVideo.bundle
    elif [ -d Carthage/Build/iOS/BFCTXMediaPlayerUniversal.framework ]; then # 寻找Carthage/Build/下的资源映射到虚拟链接
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerUniversal.framework/QLBase.bundle resource-bin/QLBase.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerUniversal.framework/QLFacility.bundle resource-bin/QLFacility.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerUniversal.framework/TADAdVideo.bundle resource-bin/TADAdVideo.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerUniversal.framework/TADQQVideo.bundle resource-bin/TADQQVideo.bundle
    elif [ -d Carthage/Build/iOS/BFCTXMediaPlayerHD.framework ]; then # 寻找Carthage/Build/下的资源映射到虚拟链接
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerHD.framework/QLBase.bundle resource-bin/QLBase.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerHD.framework/QLFacility.bundle resource-bin/QLFacility.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerHD.framework/TADAdVideo.bundle resource-bin/TADAdVideo.bundle
        ln -sf ../Carthage/Build/iOS/BFCTXMediaPlayerHD.framework/TADQQVideo.bundle resource-bin/TADQQVideo.bundle
    else
        echo "Can not found TXPlayer resource"
        exit 1
    fi
}

rm -f "${CONTRIB_ROOT}/lastHash"
rm -f "${CONTRIB_ROOT}/changeLogs"
rm -f "${CONTRIB_ROOT}/lastHash.txt"
rm -f "${CONTRIB_ROOT}/changeLogs.html"
#清除Carthage/Checkouts目录下所有文件
do_check_bin_sync ffmpeg-bin3 $REPO_FFMPEG_BIN_HASH

if [ "$ARG" != "sync" ]; then
    if [ ${TARGET} = "universal" -o ${TARGET} = "all" ]; then
	cp tools/template/universal-project.pbxproj bili-universal/bili-universal.xcodeproj/project.pbxproj
    fi
    if [ ${TARGET} = "blue" -o ${TARGET} = "all" ]; then
	cp tools/template/blue-project.pbxproj bili-blue/bili-blue.xcodeproj/project.pbxproj
    fi
    if [ ${TARGET} = "ipad" -o ${TARGET} = "all" ]; then
	cp tools/template/ipad-project.pbxproj bili-ipad/bili-ipad.xcodeproj/project.pbxproj
    fi

    rm -rf ./Carthage/Checkouts
    rm -rf ./Carthage/Build
    if [ "$ARG" == "builder" ]; then
        rm -rf ./Carthage
    fi
fi

if [ ${TARGET} = "universal" -o ${TARGET} = "all" ]; then
    ruby tools/create_xcodeproj.rb universal $ARG
fi
if [ ${TARGET} = "blue" -o ${TARGET} = "all" ]; then
    ruby tools/create_xcodeproj.rb blue $ARG
fi
if [ ${TARGET} = "ipad" -o ${TARGET} = "all" ]; then
    ruby tools/create_xcodeproj.rb ipad $ARG
fi

do_check_res_sync

cat -b Cartfile.resolved
echo "done"
