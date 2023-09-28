#!/bin/bash

PATH_DIR_LIST="Temp/directory_list.txt"

MSG_c="Location of the xml file which contains the directory structure of the project."
MSG_d="Node of the xml file that describes the target directory structure."
MSG_USAGE="Usage: $0 [-c] [-h]\r\n\
\t-c --c --config_file\t${MSG_c}\r\n\
\t-d --dirs_node\t\t${MSG_d}"
MSG_NO_OPT="No input parameters were provided for $0"

OPTS_SHORT="c:d:h"
OPTS_LONG="config_file:,dirs_node:,help"

# Check if no input parameter were passed.
if [ $# -eq 0 ]; then
    echo  ${MSG_NO_OPT}
fi

# declare a map in which every value will store each input parameter option provided value.
declare -A OPT_VALUES

OPT_VALUES["CONFIG_FILE"]="config.xml"
OPT_VALUES["DIRS_NODE"]="config/Directories/"

# Parse options.
OPTS=$(getopt --options $OPTS_SHORT --longoptions $OPTS_LONG -- "$@")

eval set -- "$OPTS"

while :
do
    case "$1" in
        -c | --config_file)
            OPT_VALUES["CONFIG_FILE"]="$2"
            shift 2
            ;;

        -d | --directories_node)
            OPT_VALUES["DIRS_NODE"]="$2"
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

# Check whether or not every option has an associated value.
for key in "${!OPT_VALUES[@]}"
do
    if [ -z "${OPT_VALUES[$key]}" ];
    then
        echo "${key} has no associated value"    
        exit 1
    else
        echo "${key} = ${OPT_VALUES[$key]}"
    fi
done

# Generate directories.
if [ ! -d Temp ]; then
    mkdir Temp
fi

xmlstarlet el ${OPT_VALUES["CONFIG_FILE"]} | grep ${OPT_VALUES["DIRS_NODE"]} >> $PATH_DIR_LIST

echo "********************"
echo "Creating directories"
echo "********************"

while read -r line
do
    new_dir=${line/#${OPT_VALUES["DIRS_NODE"]}}
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
