#!/bin/bash
USERNAME=root
PASSWORD="XXXXXXXXXXXXXXXXXXX"
HOSTS="n99.ds"
SCRIPT="apt install python -y"

sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no -l ${USERNAME} ${HOSTNAME} "${SCRIPT}"

