#!/bin/bash

MSG_ASK_USER="xmlstarlet has not been installed. Install it now? Type \"n\" to refuse, any other key to accept."
MSG_USER_REFUSED="Refused to install xmlstarlet."
MSG_USER_ACCEPTED="Accepted to install xmlstarlet."
MSG_WRONG_VERSION_NAME="Version mode should be RELEASE or DEBUG, no other."
MSG_RELEASE_MODE_EXISTS="RELEASE version could not be created, as it already exists."

script_dir_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
lib_root="${script_dir_location}/../"
config_file="${lib_root}config.xml"
echo $script_dir_location
needs_permission=0

if ! command -v xmlstarlet > /dev/null 2>&1; then
    echo ${MSG_ASK_USER}

    read user_input

    if [[ ${user_input} == "n" ]]
    then
        echo ${MSG_USER_REFUSED}
        exit 1
    else
        echo ${MSG_USER_ACCEPTED}
        sudo apt install xmlstarlet
    fi
fi

prj_data_node="config/Project_data/"
version_major=$(xmlstarlet sel -t -v "${prj_data_node}@version_major" ${config_file})
version_minor=$(xmlstarlet sel -t -v "${prj_data_node}@version_minor" ${config_file})
version="v${version_major}_${version_minor}"
mode="$(xmlstarlet sel -t -v "${prj_data_node}@version_mode" ${config_file})"
URL="$(xmlstarlet sel -t -v "${prj_data_node}@URL" ${config_file})"

if [ ${mode} != "RELEASE" ] && [ ${mode} != "DEBUG" ]
then
    echo "${MSG_WRONG_VERSION_NAME}"
    exit 1
fi

echo -e "VERSION:\t${version}"
echo -e "MODE:\t\t${mode}"
echo -e "URL:\t\t${URL}"

API_dir="${lib_root}API"

# If RELEASE version already exists, it cannot be overwritten.
if [ ${mode} == "RELEASE" ] && [ -d "${API_dir}/${version}" ]
then
    echo "${MSG_RELEASE_MODE_EXISTS}"
    exit 1
else
    version_suffix=""

    if [ ${mode} == "DEBUG" ]
    then
        rm -rf "${API_dir}/${version}_DEBUG"
        version_suffix="_DEBUG"
    fi

    new_api_dir="${API_dir}/${version}${version_suffix}/"

    mkdir -p ${new_api_dir}

    cp ${script_dir_location}/* ${new_api_dir}

    chmod a-w ${new_api_dir}/*
fi
