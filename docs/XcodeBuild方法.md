打包
----
```shell
xcodebuild -project xxx.xcodeproj -scheme xxx -configuration Debug -sdk iphonesimulator -derivedDataPath ./_derivedPath/ DWARF_DSYM_FOLDER_PATH='./_binaryPath/' DEBUG_INFORMATION_FORMAT='dwarf-with-dsym' CONFIGURATION_BUILD_DIR='./_binaryPath/'
```

参数
----
* **DWARF_DSYM_FOLDER_PATH**: 设置生成dSYM文件到特定的路径下。
* **DEBUG_INFORMATION_FORMAT**: `dwarf-with-dsym` 生成dSYM文件。
* **CONFIGURATION_BUILD_DIR**: 编译最终文件的目标目录。

Universal的脚本参考
----
```bash
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-Universal
# Make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
# Next, work out if we're in SIMULATOR or REAL DEVICE
xcodebuild -target "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -target "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphoneos ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"
# Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
BUILD_PRODUCTS="${SYMROOT}/../../../../Products"
cp -R "${BUILD_PRODUCTS}/Debug-iphonesimulator/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/." "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule"
# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_PRODUCTS}/Debug-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}"
# Step 5. Convenience step to copy the framework to the project's directory
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework" "${PROJECT_DIR}"
# Step 6. Convenience step to open the project's directory in Finder
open "${PROJECT_DIR}"
```