#!/bin/bash
################################################################################################################################################
# ParseOptions variables
OPTS_SHORT="c:p:P:s:S:h"
OPTS_LONG="config_file:,header_prefix:,header_dest:,so_prefix:,so_dest:,help"

# ParseOptions variables
MSG_c="Location of the xml file which contains the dependency structure of the project."
MSG_p="Location of the node in the config.xml file where the paths to source header files are stored."
MSG_P="Destination directory within the project where symbolic links to header files mentioned in the config.xml files are meant to be created."
MSG_s="Location of the node in the config.xml file where the paths to source SO files are stored."
MSG_S="Destination directory within the project where symbolic links to SO mentioned in the config.xml files are meant to be created."
MSG_USAGE="Usage: $0 [-c arg] [-p arg] [-P arg] [-s arg] [-S arg]\r\n\
\t-p --config_file\t${MSG_c}\r\n\
\t-p --header_prefix\t${MSG_p}\r\n\
\t-P --header_dest\t${MSG_P}\r\n\
\t-s --so_prefix\t\t${MSG_s}\r\n\
\t-S --so_dest\t\t${MSG_S}"
MSG_OPT_ERROR="Unexpected option has been provided: $1"
################################################################################################################################################

################################################################################################
# CreateSymLinks variables
PATH_DEPS_LIST="Temp/sym_links_list.txt"

# CreateSymLinks messages
MSG_CREATING_SYM_LINKS="********************\r\nCreating symbolic links\r\n********************"
################################################################################################

#################################################################################
# Global variables
# Map in which every value will store each input parameter option provided value.
declare -A OPT_VALUES

# Associate each option internal variable with its default value (if any).
OPT_VALUES["CONFIG_FILE"]="config.xml"
OPT_VALUES["HEADER_PREFIX"]=""
OPT_VALUES["HEADER_DEST"]=""
OPT_VALUES["SO_PREFIX"]=""
OPT_VALUES["SO_DEST"]=""
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

            -p | --header_prefix)
                OPT_VALUES["HEADER_PREFIX"]="$2"
                shift 2
                ;;

            -P | --header_dest)
                OPT_VALUES["HEADER_DEST"]="$2"
                shift 2
                ;;

            -s | --so_prefix)
                SO_OPT_VALUES["SO_PREFIX"]PREFIX="$2"
                shift 2
                ;;

            -S | --so_dest)
                OPT_VALUES["SO_DEST"]="$2"
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

###################################################################################################
# Brief: generate symbolic links based on what is found within the nodes of the configuration file.
# $1: $CONFIG_FILE
# $2: $FILE_PREFIX          (example: "config/Dependencies/Header_files")
# $3: $ORG_LOCATIONS_LIST   
# $4: $SYM_LINK_DEST        (example: "Dependency_files/Header_files")
# Returns: 1 if the configuration file could not be found, 0 otherwise.
###################################################################################################
CreateSymLinks()
{
    local config_file="$1"
    local file_prefix="$2"
    local org_locations_list="$3"
    local sym_link_dest="$4"

    # Check if configuration file exists.
    if [ ! -e $config_file ]
    then
        echo "Config file $config_file could not be found."
        exit 1
    fi

    # Generate temporary directory which stores a file thatincludes the list
    # of directories to generate.
    if [ ! -d Temp ]; then
        mkdir Temp
    fi

    # Get the list of paths in which files to be linked are.
    xmlstarlet el -a $config_file | grep $file_prefix | grep "@" > $org_locations_list

    echo -e "${MSG_CREATING_SYM_LINKS}"

    # Create symlinks of the header files in their target destination directory.
    while read -r line
    do
        local source=$(xmlstarlet sel -t -v "//${line}" $config_file)
        local full_path=$(readlink -f $source)
        echo "Making symbolic link from $full_path to $sym_link_dest."
        ln -sf $full_path $sym_link_dest
    done < $org_locations_list

    # Delete temporary files directory if it still exists.
    if [ -d Temp ]; then
        rm -rf Temp
    fi
}

########################################################################
# Main
########################################################################
if [ $# -eq 0 ]; then echo  ${MSG_NO_OPT}; fi
ParseOptions $@
if [ $? -eq 1 ];then exit 1; fi
CheckOptionValues OPT_VALUES
if [ $? -eq 1 ];then exit 1; fi
CreateSymLinks $CONFIG_FILE $HEADER_PREFIX $PATH_DEPS_LIST $HEADER_DEST
if [ $? -eq 1 ];then exit 1; fi
CreateSymLinks $CONFIG_FILE $SO_PREFIX $PATH_DEPS_LIST $SO_DEST
if [ $? -eq 1 ];then exit 1; fi
########################################################################
