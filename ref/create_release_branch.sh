#! /bin/sh
# use like :>
#   sh creat_release_branch.sh  release-universal/r5.21 push 5.21 6502

if [ $# -lt 1 ]; then
    echo 'no pars'
    exit 1
fi


biliShellDirPath=$(PWD)
universalInfoPlist=$(PWD)/bili-universal/bili-universal/Info.plist
widgetExtensionInfoPlist=$(PWD)/bili-universal/BiliWidgetExtension/Info.plist
iMessageExtensionInfoPlist=$(PWD)/bili-universal/BiliIMessageExtension/Info.plist

branchName=''
ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${universalInfoPlist}`
buildNum=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${universalInfoPlist}`
pushToRemote='false'
if [ $# -ge 1 ];then
    branchName=$1
    if [ ${branchName} == 'develop' ];then
        echo 'fuck you! stupid!'
        exit 1
    fi
    if [ ${branchName} == 'master' ];then
        echo 'fuck you! stupid!'
        exit 1
    fi
fi

if [ $# -ge 2 ];then
    if [ $2 == 'push' ];then
        pushToRemote='true'
    fi
fi

if [ $# -ge 3 ];then
    if [ $3 -gt 0 ];then
        ver=$3
    else
        echo 'pars 3 wrong'
    fi
fi

if [ $# -ge 4 ];then
    if [ $4 -gt 0 ];then
        buildNum=$4
    else
        echo 'pars 4 wrong'
    fi
fi


git fetch --all 
git branch --list | grep ${branchName}

if [ $? -eq 1 ];then
    git checkout develop
    git checkout -b $branchName
    # 修改Info.plist配置文件
    /usr/libexec/PlistBuddy -c "set CFBundleShortVersionString ${ver}" ${universalInfoPlist}
    /usr/libexec/PlistBuddy -c "set CFBundleVersion ${buildNum}" ${universalInfoPlist}
    /usr/libexec/PlistBuddy -c "set CFBundleShortVersionString ${ver}" ${widgetExtensionInfoPlist}
    /usr/libexec/PlistBuddy -c "set CFBundleVersion ${buildNum}" ${widgetExtensionInfoPlist}
    /usr/libexec/PlistBuddy -c "set CFBundleShortVersionString ${ver}" ${iMessageExtensionInfoPlist}
    /usr/libexec/PlistBuddy -c "set CFBundleVersion ${buildNum}" ${iMessageExtensionInfoPlist}
    if [ ${pushToRemote} == 'true' ];then
        git push origin $branchName:$branchName
    fi
fi

cd ${biliShellDirPath}/contrib/BBPhone
git fetch --all 
git branch --list | grep ${branchName}

if [ $? -eq 1 ];then
    git checkout develop
    git checkout -b $branchName
    if [ ${pushToRemote} == 'true' ];then
        git push origin $branchName:$branchName
    fi
fi


cd ${biliShellDirPath}/contrib/BBPad
git fetch --all
git branch --list | grep ${branchName}

if [ $? -eq 1 ];then
    git checkout develop
    git checkout -b $branchName
    if [ ${pushToRemote} == 'true' ];then
        git push origin $branchName:$branchName
    fi
fi

cd ${biliShellDirPath}
carthage update --no-build

cd ${biliShellDirPath}/contrib/BBPhone
carthage update --no-build

cd ${biliShellDirPath}/contrib/BBPad
carthage update --no-build
