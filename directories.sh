#!/bin/bash

PATH_DIR_LIST="Temp/directory_list.txt"

MSG_c="Location of the xml file which contains the directory structure of the project."
MSG_d="Node of the xml file that describes the target directory structure."
MSG_USAGE="Usage: $0 [-c] [-h]\r\n\
\t-c --c --config_file\t${MSG_c}\r\n\
\t-d --dirs_node\t\t${MSG_d}"

OPTS_SHORT="c:d:h"
OPTS_LONG="config_file:,dirs_node:,help"

if [ $# -eq 0 ]; then
    echo -e ${MSG_USAGE}
    exit 1
fi

OPTS=$(getopt --options $OPTS_SHORT --longoptions $OPTS_LONG -- "$@")

eval set -- "$OPTS"

while :
do
    case "$1" in
        -c | --config_file)
            CONFIG_FILE="$2"
            shift 2
            ;;

        -d | --directories_node)
            DIRS_NODE="$2"
            shift 2
            ;;

        -h | --help)
            echo -e ${MSG_USAGE}
            exit 0
            ;;

        --) shift; 
            break 
            ;;
        
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

list=("CONFIG_FILE" "DIRS_NODE")

for var in "${list[@]}"
do
    if [ -z "${!var}" ]
    then
        echo "$var is NULL"
        exit 1
    else
        echo "$var = ${!var}"
    fi
done

if [ ! -d Temp ]; then
    mkdir Temp
fi

xmlstarlet el $CONFIG_FILE | grep $DIRS_NODE >> $PATH_DIR_LIST

echo "********************"
echo "Creating directories"
echo "********************"

while read -r line
do
    new_dir=${line/#$DIRS_NODE}
    if [ ! -d $new_dir ]
    then
        echo "Creating $new_dir directory ..."
        mkdir $new_dir
    else
        echo "$new_dir directory already exists"
    fi
done < $PATH_DIR_LIST

if [ -d Temp ]; then
    rm -rf Temp
fi
