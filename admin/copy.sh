#!/bin/bash

display_usage() { 
	echo "This script must requires you to specify an S3 bucket." 
	echo -e "\nUsage:\ncopy.sh [BUCKET_NAME] \n" 
	} 

# if less than one arguments supplied, display usage 
	if [  $# -eq 0 ] 
	then 
		display_usage
		exit 1
	fi 
 
# check whether user had supplied -h or --help . If yes display usage 
	if [[ ( $# == "--help") ||  $# == "-h" ]] 
	then 
		display_usage
		exit 0
	fi 

bucketName=$1

aws s3 cp ../templates/ s3://$bucketName/quickstart-citrix-xenappxendesktop/templates/ --recursive --acl public-read
aws s3 cp ../scripts/ s3://$bucketName/quickstart-citrix-xenappxendesktop/scripts/ --recursive --acl public-read
aws s3 cp ../submodules/ s3://$bucketName/quickstart-citrix-xenappxendesktop/submodules/ --recursive --acl public-read
aws s3 cp ../modules/ s3://$bucketName/quickstart-citrix-xenappxendesktop/modules/ --recursive --acl public-read

