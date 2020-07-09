# tools
### 1. [GoFuncsAnalysis.sh](scripts/GoFuncsAnalysis.sh)
- 位置： [scripts/GoFuncsAnalysis.sh](scripts/GoFuncsAnalysis.sh)
- 用法：bash GoFuncsAnalysis.sh [PACKAGE]
- 描述：统计Go指定包（$GOROOT/src/PACKAGE）中的函数到 PACKAGE_analysis.csv 文件，未指定 PACKAGE 时则统计整个 src 包到 go_analysis.csv 文件
- 参数：  
   -h, --help  显示帮助信息，并退出脚本
### 2. [GoImportsAmalysis.sh](scripts/GoImportsAmalysis.sh)
- 位置： [scripts/GoImportsAmalysis.sh](scripts/GoImportsAmalysis.sh)
- 用法：bash GoImportsAmalysis.sh PROJECT_DIR [--module [MODULE_NAME]]
- 描述：统计项目（PROJECT_DIR）中go模块被使用（import）次数到 PROJECT_DIR[_MODULE_NAME]_imports.csv 文件  
- 参数：  
   -h, --help  显示帮助信息，并退出脚本  
   -m, --module  指定需要统计的模块。如果不启用，将对go源码包模块使用情况进行统计；指定空的名称将默认对“golang.org/x”进行统计