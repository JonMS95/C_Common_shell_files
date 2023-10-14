#!/bin/bash

#################################################################################################################################################
# ParseOptions variables
OPTS_SHORT="c:n:a:k:s:h"
OPTS_LONG="config_file:,prj_info_node:,api_dir_name:,api_header_src:,api_so_src:,help"

# ParseOptions variables
MSG_c="Location of the xml file which contains the dependency structure of the project."
MSG_n="Location of the node in which project information is found."
MSG_a="Name of the directory in which new API files are meant to be copied."
MSG_k="Location of the API header file within the project."
MSG_s="Location of the API SO file within the project."
MSG_USAGE="Usage: $0 [-c arg] [-n arg] [-a arg] [-k arg] [-s arg]\r\n\
\t-c --config_file\t${MSG_c}\r\n\
\t-n --prj_info_node\t${MSG_v}\r\n\
\t-a --api_dir_name\t${MSG_a}\r\n\
\t-k --api_header_src\t${MSG_k}\r\n\
\t-s --api_so_src\t\t${MSG_s}\r\n\r\n\
Example: $0 -c \"config.xml\" -n \"config/Project_data/\" -a API -k Source_files/my_lib_api.h -s Dynamic_libraries/lib_prj.so"
MSG_OPT_ERROR="An error ocurred while parsing option: $1"
#################################################################################################################################################

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
OPT_VALUES["API_DIR"]="API"
OPT_VALUES["PRJ_INFO_NODE"]="config/Project_data/"
OPT_VALUES["API_HEADER_SOURCE"]="Source_files/$(ls Source_files | grep "_api\.h")"
OPT_VALUES["API_SO_SOURCE"]="Dynamic_libraries/$(ls Dynamic_libraries)"
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

            -n | --prj_info_node)
                OPT_VALUES["PRJ_INFO_NODE"]="$2"
                shift 2
                ;;

            -a | --api_dir_name)
                OPT_VALUES["API_DIR"]="$2"
                shift 2
                ;;

            -k | --api_header_src)
                OPT_VALUES["API_HEADER_SOURCE"]="$2"
                shift 2
                ;;

            -s | --api_so_src)
                OPT_VALUES["API_SO_SOURCE"]="$2"
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
        fi
    done
}

######################################################################################################
# Brief: generate API version directory within API directory.
# $1: OPT_VALUES["CONFIG_FILE"]
# $2: OPT_VALUES["API_DIR"]
# $3: OPT_VALUES["PRJ_INFO_NODE"]
# $3: OPT_VALUES["API_HEADER_SOURCE"]
# $4: OPT_VALUES["API_SO_SOURCE"]
# Returns: 1 if the version mode is not allowed or if the RELEASE version already exists, 0 otherwise.
######################################################################################################
GenAPIVersion()
{
    local config_file="$1"
    local API_dir="$2"
    local prj_data_node="$3"
    local api_header_src="$4"
    local api_so_src="$5"

    local prj_data_node="config/Project_data/"

    local version_major=$(xmlstarlet sel -t -v "${prj_data_node}@version_major" ${config_file})
    local version_minor=$(xmlstarlet sel -t -v "${prj_data_node}@version_minor" ${config_file})

    local version="v${version_major}_${version_minor}"
    local mode="$(xmlstarlet sel -t -v "${prj_data_node}@version_mode" ${config_file})"
    local URL="$(xmlstarlet sel -t -v "${prj_data_node}@URL" ${config_file})"

    # If version is either RELEASE or DEBUG, go on, otherwise, exit.
    if [ ${mode} != "RELEASE" ] && [ ${mode} != "DEBUG" ]
    then
        echo "${MSG_WRONG_VERSION_NAME}"
        exit 1
    fi

    echo -e "VERSION:\t${version}"
    echo -e "MODE:\t\t${mode}"
    echo -e "URL:\t\t${URL}"

    local new_api_dir=""

    # If RELEASE version already exists, it cannot be overwritten.
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

        new_api_dir="${API_dir}/${version}${version_suffix}/"

        mkdir -p ${new_api_dir}{Header_files,Dynamic_libraries}
    fi

    # Copy API files to newly created directories.
    cp ${api_header_src} "${new_api_dir}Header_files"
    cp ${api_so_src} "${new_api_dir}Dynamic_libraries"
}

#######################################################################################################################
# Main
#######################################################################################################################
echo -e "*********************************************************************************************************\r\n\
GENERATE VERSION\r\n\
*********************************************************************************************************"
if [ $# -eq 0 ]; then echo ${MSG_NO_OPT}; fi
ParseOptions $@
if [ $? -eq 1 ];then exit 1; fi
CheckOptionValues OPT_VALUES
if [ $? -eq 1 ];then exit 1; fi
GenAPIVersion ${OPT_VALUES["CONFIG_FILE"]} ${OPT_VALUES["API_DIR"]} ${OPT_VALUES["PRJ_INFO_NODE"]} ${OPT_VALUES["API_HEADER_SOURCE"]} ${OPT_VALUES["API_SO_SOURCE"]}
if [ $? -eq 1 ];then exit 1; fi
echo "*********************************************************************************************************"
