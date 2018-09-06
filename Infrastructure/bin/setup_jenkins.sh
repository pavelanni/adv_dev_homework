#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

# Build a slave image with Maven and Skopeo (slide 38 in 05_Building_Applications)
oc get is -n ${GUID}-jenkins | grep -q 'jenkins-slave-appdev'
if [[ "$?" == "1" ]] 
then
  oc new-build \
   -D $'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\n
        USER root\nRUN yum -y install skopeo && yum clean all\n
        USER 1001' \
   --name=jenkins-slave-appdev -n ${GUID}-jenkins
fi

# Wait for the image to become available
while : ; 
  do echo "Checking image"
  oc get is -n ${GUID}-jenkins | grep 'jenkins-slave-appdev'
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds"
  sleep 10
done

# Grant the correct permissions to the Jenkins service account
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:default -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-prod
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:default -n ${GUID}-parks-prod

# Create a Jenkins instance with persistent storage and sufficient resources
#oc new-app -f ../templates/${GUID}-jenkins.yaml --param=PROJECT_NAME=${GUID}-jenkins -n ${GUID}-jenkins

# Set up three build configurations with pointers to the pipelines in the source code project
oc new-build ${REPO} -e GUID=${GUID} \
             -e CLUSTER=${CLUSTER} \
             --strategy=pipeline \
             --context-dir="MLBParks" \
             -n ${GUID}-jenkins \
             --name=mlbparks-pipeline
oc set env bc/mlbparks-pipeline GUID=${GUID} CLUSTER=${CLUSTER} -n ${GUID}-jenkins


oc new-build ${REPO} -e GUID=${GUID} \
             -e CLUSTER=${CLUSTER} \
             --strategy=pipeline \
             --context-dir="Nationalparks" \
             -n ${GUID}-jenkins \
             --name=natparks-pipeline
oc set env bc/natparks-pipeline GUID=${GUID} CLUSTER=${CLUSTER} -n ${GUID}-jenkins

oc new-build ${REPO} -e GUID=${GUID} \
             -e CLUSTER=${CLUSTER} \
             --strategy=pipeline \
             --context-dir="ParksMap" \
             -n ${GUID}-jenkins \
             --name=parksmap-pipeline
oc set env bc/parksmap-pipeline GUID=${GUID} CLUSTER=${CLUSTER} -n ${GUID}-jenkins



