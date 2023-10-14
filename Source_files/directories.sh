#!/bin/bash

#######################################################################################
# ParseOptions variables
OPTS_SHORT="c:d:h"
OPTS_LONG="config_file:,dirs_node:,help"

# ParseOptions messages.
MSG_c="Location of the xml file which contains the directory structure of the project."
MSG_d="Node of the xml file that describes the target directory structure."
MSG_USAGE="Usage: $0 [-c] [-d] [-h]\r\n\
\t-c --c --config_file\t${MSG_c}\r\n\
\t-d --dirs_node\t\t${MSG_d}\r\n\r\n\
Example: $0 -c config.xml -d config/Directories/"
MSG_OPT_ERROR="An error ocurred while parsing option: $1"
#######################################################################################

########################################################################################
# GenerateDirectories variables
PATH_DIR_LIST="Temp_directories/directory_list.txt"

# GenerateDirectories messages
MSG_CREATING_DIRS="********************\r\nCreating directories\r\n********************"
########################################################################################

#####################################################
# Main messages.
MSG_NO_OPT="No input parameters were provided for $0"
#####################################################

#################################################################################
# Global variables
# Map in which every value will store each input parameter option provided value.
declare -A OPT_VALUES

# Associate each option internal variable with its default value (if any).
OPT_VALUES["CONFIG_FILE"]="config.xml"
OPT_VALUES["DIRS_NODE"]="config/Directories/"
#################################################################################

#########################################################################
# Brief: Parse input arguments passed to the current file.
# Returns: 1 if an unexpected option or -h (help) was found, 0 otherwise.
#########################################################################
ParseOptions()
{
    # Retrieve provided option values.
    OPTS=$(getopt --options $OPTS_SHORT --longoptions $OPTS_LONG -- "$@")

    if [ $? -eq 1 ]
    then
        echo "${MSG_OPT_ERROR}"
        exit 1
    fi

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
                exit 1
                ;;

            --) 
                shift
                break 
                ;;
            
            *)
                echo "${MSG_OPT_ERROR}"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Brief: Check whether or not every option has an associated value.
# $1: OPT_VALUES
# Returns: 1 if any of the input arguments has no associated value, 0 otherwise.
################################################################################
CheckOptionValues()
{
    local -n options_map="$1"
    for key in "${!options_map[@]}"
    do
        if [ -z "${options_map[$key]}" ];
        then
            echo "${key} has no associated value"
            exit 1
        fi
    done
}

################################################################################################
# Brief: generate directories based on what is found within the nodes of the configuration file.
# $1: OPT_VALUES["CONFIG_FILE"]
# $2: OPT_VALUES["DIRS_NODE"]
# $3: PATH_DIR_LIST
# Returns: 1 if the configuration file could not be found, 0 otherwise.
################################################################################################
GenerateDirectories()
{
    local config_file="$1"
    local dirs_node="$2"
    local dirs_list="$3"

    # Check if configuration file exists.
    if [ ! -e $config_file ]
    then
        echo "Config file $config_file could not be found."
        exit 1
    fi

    # Generate temporary directory which stores a file thatincludes the list
    # of directories to generate.
    if [ ! -d Temp_directories ]; then
        mkdir Temp_directories
    fi

    # Get the list of directories to generate from configuration xml file.
    xmlstarlet el $config_file | grep $dirs_node > $PATH_DIR_LIST

    echo -e ${MSG_CREATING_DIRS}

    # Read temporary file in order to know the paths of directories to create.
    while read -r line
    do
        new_dir=${line/#$dirs_node}
        if [ ! -d $new_dir ]
        then
            echo "Creating $new_dir directory ..."
            mkdir $new_dir
        else
            echo "$new_dir directory already exists"
        fi
    done < $PATH_DIR_LIST

    # Delete temporary files directory if it still exists.
    if [ -d Temp_directories ]; then
        rm -rf Temp_directories
    fi
}

#######################################################################################################################
# Main
#######################################################################################################################
echo -e "*********************************************************************************************************\r\n\
CREATE DIRECTORIES\r\n\
*********************************************************************************************************"
if [ $# -eq 0 ]; then echo  ${MSG_NO_OPT}; fi
ParseOptions $@
if [ $? -eq 1 ];then exit 1; fi
CheckOptionValues OPT_VALUES
if [ $? -eq 1 ];then exit 1; fi
GenerateDirectories ${OPT_VALUES["CONFIG_FILE"]} ${OPT_VALUES["DIRS_NODE"]} $PATH_DIR_LIST
if [ $? -eq 1 ];then exit 1; fi
echo "*********************************************************************************************************"
#######################################################################################################################