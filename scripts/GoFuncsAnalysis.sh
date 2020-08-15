#!/bin/bash

case "$1" in
    -h | --help | ?)
        echo "Usage: $0 [PACKAGE]"
        echo "Count all funcs in the specified package of Go"
        echo ""
        echo "With no PACKAGE, Count all funcs in the root dir of Go."
        echo ""
        echo "  -h, --help     display this help and exit"
        exit 0
    ;;
esac

pkg=$1
if [[ "${GOROOT}" == "" ]] || [[ ! -d "${GOROOT}/src" ]]; then
    echo "Please set the correct 'GOROOT' first !!"
    exit 1
fi
src_dir="${GOROOT}/src"
pkg_dir="${src_dir}"
output="go_analysis.csv"
if [[ "${pkg}" != "" ]]; then
    pkg_dir="${src_dir}/${pkg}"
    if [[ ! -d "${pkg_dir}" ]]; then
        echo "Package dir `${pkg_dir}` not found !"
        exit 1
    fi

    output="${pkg}_analysis.csv"
fi

echo "编号,包名,子包,文件,函数名,依赖关系（关键调用）,ARM与X86优化差异分析,涉及的数学理论,SIMD优化,算法改进（时间/空间）,cache优化,位宽对齐,SSA规则优化,汇编优化,CleanCode,备注" > ${output}
num=0
IFS=$'\n'                                               # 指定 for...in...仅使用"\n"切分（shell默认以空白符切分）
for fl in `find ${src_dir}/${pkg} -name "*.go" -type f | grep -v "_test.go"`; do
                                                        # eg. fl="$GOROOT/src/math/rand/rng.go"
    file_path=${fl#*${src_dir}/}                        # 文件所在go包位置: "math/rand/rng.go"（即：fl 中"${src_dir}/"后的字符）
    file_name=${file_path##*/}                          # go文件名："rng.go"（即：file_path 最右侧 "/" 后的字符）

    full_len=`expr ${#file_path} - ${#file_name} - 1`   # 完整包长度=文件路径长度-文件名长度-"/"
    full_pkg=${file_path:0:${full_len}}                 # 完整包名:"math/rand"（file_path 中，从 0 开始的 full_pkg_len 个字符）

    pkg_name=${full_pkg%%/*}                            # 包名："math"（full_pkg 最左侧 "/" 前的字符）
    sub_pkg=${full_pkg#*/}                              # 子包名："rand" （full_pkg 最左侧 "/" 后的字符）

    if [[ "${sub_pkg}" == "${pkg_name}" ]]; then
        sub_pkg=""
    fi

    for line in `grep "^func " ${fl}`; do
                                                        # eg. line="func NormFloat64() float64 {"
        num=`expr ${num} + 1`                           # 序号增加
        nosign=${line#*func}                            # 去除行首的"func "标识，即: "NormFloat64() float64 {"
        func_name=${nosign%%(*}                         # 方法名: "NormFloat64",（即：nosign 最左侧"("前的字符）
        if [[ "${func_name}" == "" ]]; then
                                                        # 针对 "(r *Rand) NormFloat64" 的情况
            struct_sign="${nosign%%\)*} "               # 仅从左侧截取，可防止返回值或处理也在一行且有括号的情况
            nostruct=${nosign:${#struct_sign}}          # 如： ""LeadingZeros(x uint) int { return UintSize - Len(x) }"
            func_name="${struct_sign}${nostruct%%\(*}"
        fi
        echo "${num},${pkg_name},${sub_pkg},${file_name},${func_name}" >> ${output}
    done
done
