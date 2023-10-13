#!/bin/bash

######################################################################################################
# ParseOptions variables
OPTS_SHORT="c:d:h"
OPTS_LONG="config_file:,deps_node:,help"

# ParseOptions variables
MSG_c="Location of the xml file which contains the dependency structure of the project."
MSG_d="Location of the node in the configuration file where information about dependencies is stored."
MSG_USAGE="Usage: $0 [-c arg] [-d arg]\r\n\
\t-c --config_file\t${MSG_c}\r\n\
\t-d --deps_node\t${MSG_d}\r\n\r\n\
Example: $0 -c \"config.xml\" -d \"config/Dependencies/\""
MSG_OPT_ERROR="An error ocurred while parsing option: $1"
######################################################################################################

################################################################################################
# CreateSymLinks variables
PATH_DEPS_LIST="Temp/deps_list.txt"
PATH_DEPS_FILES="Temp/deps_files.txt"

# CreateSymLinks messages
MSG_CREATING_SYM_LINKS="********************\r\nCreating symbolic links\r\n********************"
################################################################################################

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
OPT_VALUES["DEPS_NODE"]="config/Dependencies/"
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

            -d | --deps_node)
                OPT_VALUES["DEPS_NODE"]="$2"
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

###############################################################################################################################################
# Brief: generate symbolic links based on what is found within the nodes of the configuration file.
# $1: $CONFIG_FILE      (example: "config.xml")
# $2: $DEPS_NODE        (example: "config/Dependencies/")
# $3: $PATH_DEPS_LIST   
# $4: $PATH_DEPS_FILES
# Returns: 1 if the configuration file could not be found, 0 otherwise.
###############################################################################################################################################
CreateSymLinks()
{
    local config_file="$1"
    local deps_node="$2"
    local path_deps_list="$3"
    local path_deps_files="$4"

    # Check if configuration file exists.
    if [ ! -e $config_file ]
    then
        echo "Config file $config_file could not be found."
        exit 1
    fi

    # Generate temporary directory which stores a file that includes the list of directories to generate.
    if [ ! -d Temp ]; then
        mkdir Temp
    fi

    # Get depenedencies.
    local deps_dest=$(xmlstarlet sel -t -v "${deps_node}@Dest" $config_file)
    echo "Destination: $(pwd)/${deps_dest}"

    xmlstarlet el -a ${config_file} | grep ${deps_node} | grep -v "@" > ${path_deps_list}
    
    while read -r line
    do
        dep_API_xml_path="${line}"
        dep_name="${line/#$deps_node}"
        
        declare -A dep_data

        dep_data["local_path"]=""
        dep_data["URL"]=""
        dep_data["version_major"]=""
        dep_data["version_minor"]=""
        dep_data["version_mode"]=""

        for key in "${!dep_data[@]}"
        do
            dep_data["$key"]="$(xmlstarlet sel -t -v "${dep_API_xml_path}/@${key}" $config_file)"
        done

        version_suffix=""
        if [ ${dep_data["version_mode"]} == "DEBUG" ]
        then
            version_suffix="_DEBUG"
        fi

        full_version="v${dep_data["version_major"]}_${dep_data["version_minor"]}${version_suffix}"
        dep_api_path="$(eval echo ${dep_data["local_path"]}/API/${full_version})"
        
        dep_details="*************************\r\n\
Name: ${dep_name}\r\n\
Version: ${full_version}\r\n\
Local path: ${dep_data["local_path"]}\r\n\
API path: ${dep_api_path}\r\n\
URL: ${dep_data["URL"]}"

        echo -e "${dep_details}"

        # Create symbolic links for API header files.
        local dep_header_files_path="${dep_api_path}/Header_files/"

        if [ ! -d "${dep_header_files_path}" ]
        then
            echo "${dep_header_files_path} does not exist!"
            exit 1
        fi

        ls "${dep_header_files_path}" > ${path_deps_files}        
        while read -r line
        do
            echo "Creating symbolic link: ${deps_dest}/Header_files/${line} -> ${dep_header_files_path}${line}"
            ln -sf "${dep_header_files_path}${line}" "${deps_dest}/Header_files/${line}"
        done < ${path_deps_files}

        # Create symbolic links for API SO files.
        local dep_SO_files_path="${dep_api_path}/Dynamic_libraries/"

        if [ ! -d "${dep_SO_files_path}" ]
        then
            echo "${dep_SO_files_path} does not exist!"
            exit 1
        fi
        
        ls "${dep_SO_files_path}" > ${path_deps_files}
        while read -r line
        do
            lib_no_version=${line%%.so*}.so
            echo "Creating symbolic link: ${deps_dest}/Dynamic_libraries/${line} -> ${dep_SO_files_path}${lib_no_version}"
            ln -sf "${dep_SO_files_path}${line}" "${deps_dest}/Dynamic_libraries/${lib_no_version}"
        done < ${path_deps_files}

    done < ${path_deps_list}

    # Delete temporary files directory if it still exists.
    if [ -d Temp ]; then
        rm -rf Temp
    fi
}

#######################################################################################################################
# Main
#######################################################################################################################
echo -e "*********************************************************************************************************\r\n\
GET DEPENDENCIES\r\n\
*********************************************************************************************************"
if [ $# -eq 0 ]; then echo  ${MSG_NO_OPT}; fi
ParseOptions $@
if [ $? -eq 1 ];then exit 1; fi
CheckOptionValues OPT_VALUES
if [ $? -eq 1 ];then exit 1; fi
CreateSymLinks ${OPT_VALUES["CONFIG_FILE"]} ${OPT_VALUES["DEPS_NODE"]} $PATH_DEPS_LIST $PATH_DEPS_FILES
if [ $? -eq 1 ];then exit 1; fi
echo "*********************************************************************************************************"
#######################################################################################################################
