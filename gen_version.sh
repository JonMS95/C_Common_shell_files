#!/bin/bash

################################################################################################################################################
# ParseOptions variables
OPTS_SHORT="c:v:m:a:h"
OPTS_LONG="config_file:,version_attr_path:,mode_attr_path:,api_dir_name:,help"

# ParseOptions variables
MSG_c="Location of the xml file which contains the dependency structure of the project."
MSG_v="Location of the attribute in the configuration file where version name is found."
MSG_m="Location of the attribute in the configuration file where version mode is found."
MSG_a="Location of the node in the configuration file where the paths to source SO files are stored."
MSG_USAGE="Usage: $0 [-c arg] [-v arg] [-m arg] [-a arg]\r\n\
\t-c --config_file\t${MSG_c}\r\n\
\t-v --version_attr_path\t${MSG_v}\r\n\
\t-m --mode_attr_path\t${MSG_m}\r\n\
\t-a --api_dir_name\t${MSG_a}\r\n\r\n\
Example: $0 -c config.xml -v \"config/@version\" -m \"config/@version_mode\" - a API"
MSG_OPT_ERROR="Unexpected option has been provided: $1"
################################################################################################################################################

#####################################################################################
# GenAPIVersion messages
MSG_WRONG_VERSION_NAME="Version mode should be RELEASE or DEBUG, no other."
MSG_RELEASE_MODE_EXISTS="RELEASE version could not be created, as it already exists."
#####################################################################################

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
OPT_VALUES["VERSION_ATTR_PATH"]="config/@version"
OPT_VALUES["MODE_ATTR_PATH"]="config/@version_mode"
OPT_VALUES["API_DIR"]="API"
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

            -v | --version_attr_path)
                OPT_VALUES["VERSION_ATTR_PATH"]="$2"
                shift 2
                ;;

            -m | --mode_attr_path)
                OPT_VALUES["MODE_ATTR_PATH"]="$2"
                shift 2
                ;;

            -a | --api_dir_name)
                OPT_VALUES["API_DIR"]="$2"
                shift 2
                ;;

            -h | --help)
                echo -e ${MSG_USAGE}
                exit 1
                ;;

            --) shift; 
                break 
                ;;
            
            *)
                echo ${MSG_OPT_ERROR}
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
        else
            echo "${key} = ${options_map[$key]}"
        fi
    done
}

######################################################################################################
# Brief: generate API version directory within API directory.
# $1: OPT_VALUES["CONFIG_FILE"]
# $2: OPT_VALUES["VERSION_ATTR_PATH"]
# $3: OPT_VALUES["MODE_ATTR_PATH"]
# $4: OPT_VALUES["API_DIR"]
# Returns: 1 if the version mode is not allowed or if the RELEASE version already exists, 0 otherwise.
######################################################################################################
GenAPIVersion()
{
    local config_file="$1"
    local version_attr="$2"
    local mode_attr="$3"
    local API_dir="$4"

    local version_node=$(xmlstarlet el -a "${config_file}" | grep -w "${version_attr}")
    local mode_node=$(xmlstarlet el -a "${config_file}" | grep -w "${mode_attr}")

    local version="$(xmlstarlet sel -t -v "//$version_node" ${config_file})"
    local mode="$(xmlstarlet sel -t -v "//$mode_node" ${config_file})"

    if [ ${mode} != "RELEASE" ] && [ ${mode} != "DEBUG" ]
    then
        echo "${MSG_WRONG_VERSION_NAME}"
        exit 1
    fi

    echo -e "VERSION:\t${version}"
    echo -e "MODE:\t\t${mode}"

    if [ ${mode} == "RELEASE" ] && [ -d "${API_dir}/${version}" ]
    then
        echo "${MSG_RELEASE_MODE_EXISTS}"
        exit 1
    else
        local version_suffix=""

        if [ ${mode} == "DEBUG" ]
        then
            rm -rf "${API_dir}/${version}_DEBUG"
            version_suffix="_DEBUG"
        fi

        # mkdir "${API_dir}/${version}${version_suffix}"
        mkdir -p ${API_dir}/${version}${version_suffix}/{Header_files,Dynamic_libraries}
        # mkdir "${API_dir}/${version}${version_suffix}/Dynamic_libraries"
    fi
}

#######################################################################################################################
# Main
#######################################################################################################################
if [ $# -eq 0 ]; then echo  ${MSG_NO_OPT}; fi
ParseOptions $@
if [ $? -eq 1 ];then exit 1; fi
CheckOptionValues OPT_VALUES
if [ $? -eq 1 ];then exit 1; fi
GenAPIVersion ${OPT_VALUES["CONFIG_FILE"]} ${OPT_VALUES["VERSION_ATTR_PATH"]} ${OPT_VALUES["MODE_ATTR_PATH"]} ${OPT_VALUES["API_DIR"]}
if [ $? -eq 1 ];then exit 1; fi
