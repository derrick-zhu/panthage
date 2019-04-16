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

