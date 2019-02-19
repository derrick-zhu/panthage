# 操作流程

1. 分析工程的 **Cartfile**和**Cartfile.private** 的依赖情况。
2. 如果有新的 repo 记录，需要将新的 repo 进行*Checkout*依赖 Repo 到*Carthage/Repo*目录下。否则进入第 5 步。
3. *Checkout*各个库的代码到*Carthage/Checkouts/*目录下
4. 遍历所有*Carthage/Checkouts/*目录下所有库的**Cartfile**和**Cartfile.private**的依赖情况。重复[2](#2)。
5. 下载所有二进制依赖的库文件到**Carthage/Build/iOS/**目录下。
6. 遍历当前工程和*Carthage/Checkouts/*中依赖工程，建构`xcodeproj`的依赖关系。