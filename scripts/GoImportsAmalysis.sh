#!/bin/bash
has_module=0
module=""
for arg in "$@"; do
    if [[ "${has_module}" == "1" ]]; then
        if [[ ${arg:0:1} != "-" ]]; then
            module=${arg}
        fi
        has_module=0
        continue
    fi
    case "${arg}" in
        -h | --help | ?)
            echo "Usage: $0 PROJECT_DIR [--module [MODULE_NAME]]"
            echo "Count the times of go modules be used (imported) in a project"
            echo ""
            echo "  -h, --help     display this help and exit"
            echo ""
            echo "  -m, --module   Specify the module to be counted. If not enabled,"
            echo "                 go source packages will be counted. If set to empty,"
            echo "                 the module will be \"golang.org/x\"."
            exit 0
        ;;
        -m | --module)
            module="golang.org/x/"
            has_module=1
        ;;
    esac
done

if [[ "${GOROOT}" == "" ]] || [[ ! -d "${GOROOT}/src" ]]; then
    echo "Please set the correct 'GOROOT' first !!"
    exit 1
fi

project_dir=$1
project_dir=${project_dir%*/}
if [[ "${project_dir}" == "" ]] || [[ ! -d "${project_dir}" ]]; then
    echo "Please input the correct 'PROJECT_DIR' !!"
    exit 1
fi

pkgs=""
src_dir="${GOROOT}/src/"
project=${project_dir##*/}
output="${project}_imports.csv"

pkg_arr=( )
sub_arr=( )
count_arr=( )

IFS=$'\n'

index=0
inGoPackage() {
    if [[ "${1}" != "" ]]; then
        if [[ "${2}" != "" ]]; then
            has=0
            for i in "${!sub_arr[@]}"; do
                if [[ "${sub_arr[${i}]}" == "${1}" ]]; then
                    has=1
                    break
                fi
            done
            if [[ "${has}" == "0" ]]; then
                return 0
            fi
        fi

        parent=${1%%/*}
        for j in "${!pkg_arr[@]}"; do
            if [[ "${pkg_arr[${j}]}" == "${parent}" ]]; then
                index=${j}
                return 1
            fi
        done
    fi
    return 0
}

getGoPackage() {
    for path in `find ${src_dir} -name "*" -type d | grep -v "vendor" | grep -v "issue" | grep -v "testdata" | grep -v "internal"`; do
        pkg=${path#*${src_dir}}
        if [[ "${pkg}" != "" ]]; then
            inGoPackage ${pkg}
            if [[ "$?" == "0" ]]; then
                num=${#pkg_arr[@]}
                pkg_arr[${num}]=${pkg%%/*}
                count_arr[${num}]=0
            fi
            sub_arr[${#sub_arr[@]}]=${pkg}
        fi
    done
}

countInGoPackage() {
    if [[ "${1}" != "" ]]; then
        inGoPackage ${1} "check sub"
        if [[ "$?" != "0" ]]; then
            count_arr[${index}]=`expr ${count_arr[${index}]} + 1`
        fi
    fi
}

countModulePackage() {
    if [[ ${#1} -gt ${#module} ]]; then
        if [[ "${1:0:${#module}}" == ${module} ]];then
            module_pkg=${1#*${module}}
            parent=${module_pkg%%/*}
            num=${#pkg_arr[@]}
            index_pkg=${num}
            for k in "${!pkg_arr[@]}"; do
                if [[ "${pkg_arr[${k}]}" == "${parent}" ]]; then
                    index_pkg=${k}
                fi
            done

            if [[ "${index_pkg}" == "${num}" ]]; then
                pkg_arr[${num}]=${parent}
                count_arr[${num}]=0
            fi

            count_arr[${index_pkg}]=`expr ${count_arr[${index_pkg}]} + 1`
        fi
    fi
}

countPackage(){
    if [[ "${module}" == "" ]]; then
        countInGoPackage $@
    else
        countModulePackage $@
    fi
}

countImportBlock() {
    rst=0
    for nl in `sed -n '/import (/,/)/p' ${1}`; do
        if [[ "${nl}" == "" ]] || [[ "${nl}" == "import (" ]] || [[ "${nl}" == ")" ]]; then
            continue
        fi
        len=`expr ${#nl} - 3`
        if [[ ${len} -gt 0 ]]; then
            countPackage ${nl:2:${len}}
            rst=1
        fi
    done
    return ${rst}
}

countImportLine() {
    for line in `grep "^import " ${1}`; do
        raw=${line#*import }
        rl=`expr ${#raw} - 2`
        if [[ ${rl} -gt 0 ]]; then
            countPackage ${raw:1:${rl}}
        fi
    done
}

countProject() {
    for fl in `find ${project_dir} -name "*.go" -type f`; do
        countImportBlock ${fl}
        if [[ $? -eq 0 ]]; then
            countImportLine ${fl}
        fi
    done
}

writeToFile() {
    echo "Number,Package,${project}" > ${output}
    for k in "${!pkg_arr[@]}"; do
        n=`expr ${k} + 1`
        echo "${n},${pkg_arr[${k}]},${count_arr[${k}]}" >> ${output}
    done
}

if [[ "${module}" == "" ]]; then
    getGoPackage
else
    module_name=`echo ${module} | sed 's/\//_/g'`
    output="${project}_${module_name}_imports.csv"
fi
countProject
writeToFile
