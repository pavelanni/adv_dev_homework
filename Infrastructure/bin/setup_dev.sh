#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student


# Create MongoDB database
#oc new-app -f ../templates/mongodb-statefulset-replication.yaml

# Create ConfigMaps for configuration of the applications
#oc process -f ../templates/configmaps.yaml | oc create -f -

oc create -f ../templates/mlbparks-dev.yaml -n ${GUID}-parks-dev
sleep 10

oc create -f ../templates/natparks-dev.yaml -n ${GUID}-parks-dev
sleep 10

oc create -f ../templates/parksmap-dev.yaml -n ${GUID}-parks-dev
sleep 10

oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev
