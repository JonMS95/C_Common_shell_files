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
PATH_DEPS_LIST="temp_sym_links/deps_list.txt"
PATH_DEPS_FILES="temp_sym_links/deps_files.txt"

# CreateSymLinks messages
MSG_CREATING_SYM_LINKS="********************\r\nCreating symbolic links\r\n********************"
MSG_CHECK_DEPS_EXIST="Check whether or not do dependencies exist."
MSG_API_FOUND="API_found, everything is OK."
MSG_CANNOT_SWITCH_TO_DEBUG="Cannot switch to DEBUG tag, as DEBUG versions are never tagged."
MSG_NO_URL_FOUND="The dependency could not be found locally and no URL has been provided."
MSG_CANNOT_DWNL_DEBUG="Cannot download DEBUG versions from GitHub."
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
    if [ ! -d temp_sym_links ]; then
        mkdir temp_sym_links
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
        dep_data["type"]=""
        dep_data["install_cmd"]=""

        for key in "${!dep_data[@]}"
        do
            dep_data["$key"]="$(eval echo $(xmlstarlet sel -t -v "${dep_API_xml_path}/@${key}" $config_file))"
        done

        # If type is built-in (i.e., it comes along with the OS), then follow the path below and continue to the next dependency.
        if [ -n "${dep_data[type]}" ]
        then
            if [ ${dep_data[type]} == "built-in" ]
            then
                lib_file_name=$(basename ${dep_data["local_path"]})

                dep_details="*************************\r\n\
Name: ${dep_name}\r\n\
Local path:  $(realpath ${dep_data["local_path"]})\r\n\
Type: ${dep_data["type"]}"
                echo -e ${dep_details}
                
                lib_no_version=${lib_file_name%%.so*}.so
                echo "Creating symbolic link: ${deps_dest}/lib/${lib_no_version} -> ${dep_data["local_path"]}"
                ln -sf "${dep_data["local_path"]}" "${deps_dest}/lib/${lib_no_version}"
                
            elif [ ${dep_data[type]} == "system" ]
            then
                dep_details="*************************\r\n\
Name: ${dep_name}\r\n\
Type: ${dep_data["type"]}"
                echo -e ${dep_details}

                if [ -n "${dep_data["install_cmd"]}" ]
                then
                    echo "Installing ${dep_name} ..."
                    eval ${dep_data["install_cmd"]}
                fi
            fi

            continue
        fi

        version_suffix=""
        if [ -n "${dep_data["version_mode"]}" ]
        then
            if [ ${dep_data["version_mode"]} == "DEBUG" ]
            then
                version_suffix="_DEBUG"
            fi
        fi

        full_version=""
        if [ -n "${dep_data["version_major"]}" ] && [ -n "${dep_data["version_minor"]}" ]
        then
            full_version="v${dep_data["version_major"]}_${dep_data["version_minor"]}${version_suffix}"
        fi
        
        if [ -n "${dep_data[type]}" ] && [ ${dep_data["type"]} == "data" ]
        then
            dep_api_path=${dep_data["local_path"]}
        else
            dep_api_path=${dep_data["local_path"]}/API/${full_version}
        fi

        # If no data type was specified, it is assumed to be JMS type library by default.
        # Apart from that, if no URL was provided, then the field should be filled either way.
        if [ -z ${dep_data["type"]} ]
        then
            dep_data["type"]="JMS"
        fi

        dep_details="*************************\r\n\
Name: ${dep_name}\r\n\
Version: ${full_version}\r\n\
Local path: $(realpath ${dep_data["local_path"]})\r\n\
API path: $(realpath ${dep_api_path})\r\n\
URL: ${dep_data["URL"]}\r\n\
Type: ${dep_data["type"]}"

        echo -e "${dep_details}"

        echo ${MSG_CHECK_DEPS_EXIST}
        local repo_parent_dir=$(dirname ${dep_data["local_path"]})
        local repo_dir=${dep_data["local_path"]}
        local current_dir=$(pwd)

        if [ -d ${dep_api_path} ]
        then
            if [ -d ${dep_api_path} ]
            then
                echo ${MSG_API_FOUND}
            else
                if [ ${dep_data["version_mode"]} == "DEBUG" ]
                then
                    echo ${MSG_CANNOT_SWITCH_TO_DEBUG}
                    exit 1
                fi

                cd ${repo_dir}

                git pull
                git checkout tags/${full_version}

                if [ ${dep_data["type"]} == "JMS" ]
                then
                    make exe
                fi
                
                git checkout main
                git pull

                cd ${current_dir}
            fi
        else
            if [ -n "${dep_data["version_mode"]}" ]
            then
                if [ ${dep_data["version_mode"]} == "DEBUG" ]
                then
                    echo ${MSG_CANNOT_DWNL_DEBUG}
                    exit 1
                fi
            fi

            if [ ! -d ${repo_parent_dir} ]
            then
                echo "${repo_parent_dir} DOES NOT EXIST"
                mkdir -p ${repo_parent_dir}
            fi

            cd ${repo_parent_dir}

            if [ -z ${dep_data["URL"]} ]
            then
                echo ${MSG_NO_URL_FOUND}
                exit 1
            fi

            git clone ${dep_data["URL"]}

            cd ${repo_dir}

            git checkout tags/${full_version}
            
            if [ ${dep_data["type"]} == "JMS" ]
            then
                make exe
            fi

            git checkout main
            git pull

            cd ${current_dir}
        fi

        if [ ${dep_data["type"]} == "data" ]
        then
            echo "Creating symbolic link: ${deps_dest}/Data/$(basename ${dep_data["local_path"]}) -> ${dep_data["local_path"]}"
            ln -sf "${dep_data["local_path"]}" "${deps_dest}/Data"
            continue
        fi

        # Create symbolic links for API header files.
        local dep_header_files_path="${dep_api_path}/inc/"

        if [ ! -d "${dep_header_files_path}" ]
        then
            echo "${dep_header_files_path} does not exist!"
            exit 1
        fi

        ls "${dep_header_files_path}" > ${path_deps_files}        
        while read -r line
        do
            inc_no_version=${line%%.h*}.h
            echo "Creating symbolic link: ${deps_dest}/inc/${inc_no_version} -> $(readlink -f ${dep_header_files_path}${line})"
            ln -sf "$(readlink -f ${dep_header_files_path}${line})" "${deps_dest}/inc/${inc_no_version}"
        done < ${path_deps_files}

        # Create symbolic links for API SO files.
        local dep_SO_files_path="${dep_api_path}/lib/"

        if [ ! -d "${dep_SO_files_path}" ]
        then
            echo "${dep_SO_files_path} does not exist!"
            exit 1
        fi
        
        ls "${dep_SO_files_path}" > ${path_deps_files}
        while read -r line
        do
            lib_no_version=${line%%.so*}.so
            echo "Creating symbolic link: ${deps_dest}/lib/${lib_no_version} -> $(readlink -f ${dep_SO_files_path}${line})"
            ln -sf "$(readlink -f ${dep_SO_files_path}${line})" "${deps_dest}/lib/${lib_no_version}"
        done < ${path_deps_files}

    done < ${path_deps_list}

    # Delete temporary files directory if it still exists.
    if [ -d temp_sym_links ]
    then
        rm -rf temp_sym_links
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
