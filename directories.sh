#!/bin/bash

PATH_DIR_LIST="Temp/directory_list.txt"
DIRS_NODE="config/Directories/"

MSG_USAGE="Usage: $0 [-c] [-h]"
MSG_c="Location of the xml file which contains the directory structure of the project."
MSG_d="Node of the xml file that describes the target directory structure."

OPTS_SHORT="c:h"
OPTS_LONG="config_file:,help"

OPTS=$(getopt --options $OPTS_SHORT --longoptions $OPTS_LONG -- "$@")

eval set -- "$OPTS"

while :
do
    case "$1" in
        -c | --config_file)
            PATH_CONFIG="$2"
            shift 2
            ;;

        -d | --directories_node)
            DIRS_NODE="$2"
            shift 2
            ;;

        -h | --help)
            echo "Usage: $0 [-c arg]"
            echo -e "-c --path_config\t${MSG_c}"
            echo -e "-d --dirs_node\t\t${MSG_d}"
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

list=("PATH_DIR_LIST" "DIRS_NODE")

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

xmlstarlet el $PATH_CONFIG | grep $DIRS_NODE >> $PATH_DIR_LIST

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
