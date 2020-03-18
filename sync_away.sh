#!/usr/bin/env bash

YEL='\033[0;33m'
RED='\033[0;31m'
LRED='\033[0;91m'
LGRE='\033[0;92m'
NC='\033[0m' # No Color

IP=$(cat $HOME/fast5_upload.config)
FAST5_DIR_CUSTOM=$1
FAST5_DIR_DEFAULT="$HOME/nanopore_fast5_data"
SYNOLOGY_FAST5_LOCATION="/volume1/Database_FAST5_raw_data"
mkdir -p /tmp/ont_upload_prep/

############################
# MODULES                  #
############################

foldercreate()
{
    if [ ! -z "${FAST5_DIR_CUSTOM}" ]; then
        UPLOADFOLDER=$(date +"%Y.%m.%d.${FAST5_DIR_CUSTOM}")
    else
        UPLOADFOLDER=$(date +'%Y.%m.%d.iimk_run')
    fi
    echo "The data will be uploaded to:"
    echo -e "${RED}${SYNOLOGY_FAST5_LOCATION}/${UPLOADFOLDER} ${NC}"
    echo " "
}

run_info_input()
{
    echo "                                                         ___________________"
    echo "________________________________________________________/      RUN INFO     \___"
    echo " "
    # stage runinfo file
    SCRIPT=$(readlink -f "$0")
    SCRIPTPATH=$(dirname "$SCRIPT")

    if test -f "/tmp/ont_upload_prep/run_info.txt"; then
        echo "run_info.txt exist, opening it"
    else
        echo "creating new run_info.txt, opening it"
        cp ${SCRIPTPATH}/data/run_info.txt /tmp/ont_upload_prep/  # its not absolute path?
    fi

    nano /tmp/ont_upload_prep/run_info.txt

    yes_no_input
}


yes_no_input()
{
    echo " "
    #clear
    echo "                                                         ___________________"
    echo "________________________________________________________/      RUN INFO     \___"
    echo " "
    cat /tmp/ont_upload_prep/run_info.txt | grep -v "%" | grep -v -e '^$'
    echo " "
    read -p "Are these information correct [yes/no] = " yn
    case $yn in
        [Yy]* ) upload_prep; transfer; return;;
        [Nn]* ) run_info_input ; return;;
        * ) echo "Please answer yes or no.";;
    esac
}

check_uniq_ID()
{
    ssh $IP ls -l ${SYNOLOGY_FAST5_LOCATION} > /tmp/ont_upload_prep/SEQ_ID_list.txt

 
    if grep -q "${UPLOADFOLDER}" /tmp/ont_upload_prep/SEQ_ID_list.txt
    then 
        echo -e "${LRED} ${UPLOADFOLDER} exists on synology, exiting.. ${NC}"
        exit 1
    fi
}

upload_prep()
{
clear
echo "                                                           _________________"
echo "__________________________________________________________/    Summary      \___"
echo " "
while true; do
    echo " "
    echo -e "Uploading this:"
    echo -e "${RED}${FAST5_DIR} ${NC}"
    echo -e "To the synology server under:"
    echo -e "${RED}${SYNOLOGY_FAST5_LOCATION}/${UPLOADFOLDER} ${NC}"
    echo "Using this runinfo:"
    cat /tmp/ont_upload_prep/run_info.txt | grep -v "%" | grep -v -e '^$'
    echo " "
    read -p "Start the file transfer? [yes/no]: " yn
    case $yn in
        [Yy]* ) check_uniq_ID; transfer; break;;
        [Nn]* ) echo "Exiting script, bye bye"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
}

transfer()
{
mkdir -p "/tmp/ont_upload_prep/${UPLOADFOLDER}/FAST5"
mkdir -p "/tmp/ont_upload_prep/${UPLOADFOLDER}/log_info" 
scp -r "/tmp/ont_upload_prep/${UPLOADFOLDER}" ${IP}:${SYNOLOGY_FAST5_LOCATION}
cat /tmp/ont_upload_prep/run_info.txt | grep -v "%" > /tmp/ont_upload_prep/run_info_upload.txt
scp  "/tmp/ont_upload_prep/run_info_upload.txt" "${IP}:${SYNOLOGY_FAST5_LOCATION}/$UPLOADFOLDER/run_info.txt"

while true;
do
  rsync --rsync-path=/bin/rsync -vcr --remove-source-files --include "*.fast5" --include "*/" --exclude "*" ${FAST5_DIR} "${IP}:${SYNOLOGY_FAST5_LOCATION}/$UPLOADFOLDER/FAST5"
  rsync --rsync-path=/bin/rsync -vcr --remove-source-files --include "*.txt" --include "*.md" --include "*.csv" --include "*/" --exclude "*" ${FAST5_DIR} "${IP}:${SYNOLOGY_FAST5_LOCATION}/$UPLOADFOLDER/log_info"
  sleep 10 ;
done
}


############################
# Start of script OUTERLOOP#
############################
while true; do
    echo "                                               _____________________________"
    echo "______________________________________________/ Created by Christian Brandt \___"
    echo " "
    echo "Welcome to the automated MinION fileupload, please read carefully."
    # Testing if username and ip adress is present
    if [ ! -f "${HOME}/fast5_upload.config" ]; then
        echo -e "${YEL}Login information in ${HOME}/fast5_upload.config not found.${NC}"
        echo "do 'nano fast5_upload.config' under ${HOME} and add:"
        echo "USERNAME@IPADDRESS"
        exit 1
        else
        echo -e "${YEL}Using the following Login and IP: $IP ${NC}"
    fi
    # testing which user input was given
    if [ ! -z "$FAST5_DIR_CUSTOM" ]
    then
        FAST5_DIR=${FAST5_DIR_CUSTOM}
    else
        echo " "
        echo "Identified the following MinION runs:"
        folders=$(ls ${FAST5_DIR_DEFAULT})
        echo -e "${RED}${folders}${NC}"
        read -p "Which directory should i upload: " RUN_NAME
        # test user input
        if test -f "${FAST5_DIR_DEFAULT}/${RUN_NAME}"; then
            FAST5_DIR=${FAST5_DIR_DEFAULT}/${RUN_NAME}
        else
            echo "typo? cant find the directory"
            exit 1
        fi
    fi

    # Ask to start
    read -p "Using ${FAST5_DIR} for upload, Want to proceed? [yes] or [no] " yn
    case $yn in
        [Yy]* ) foldercreate; run_info_input; break;;
        [Nn]* ) echo "Exiting script, bye bye"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
