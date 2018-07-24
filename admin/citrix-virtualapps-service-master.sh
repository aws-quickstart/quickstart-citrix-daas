aws cloudformation create-stack \
  --stack-name citrixcloud-`echo $(date +%s)` \
  --template-body file://../templates/citrix-virtualapps-service-master.yaml \
  --disable-rollback \
    --parameters \
    "[{ \"ParameterKey\": \"KeyPairName\", \"ParameterValue\": \"key-pair-tommcm-general\" }, 
      { \"ParameterKey\": \"AvailabilityZones\", \"ParameterValue\": \"ap-southeast-2a,ap-southeast-2b\" }, \
      { \"ParameterKey\": \"CitrixAPIClientID\", \"ParameterValue\": \"4d887280-a72d-4df0-b526-7dc44c579e6a\" }, \
      { \"ParameterKey\": \"CitrixAPIClientSecret\", \"ParameterValue\": \"7hwMPEQyLczMrpaKjVG8HQ==\" }, \
      { \"ParameterKey\": \"CitrixCustomerId\", \"ParameterValue\": \"Amazon660216\" }, \
      { \"ParameterKey\": \"CitrixInstallS3BucketName\", \"ParameterValue\": \"tommcm-citrix\" }, \
      { \"ParameterKey\": \"CitrixResourceLocation\", \"ParameterValue\": \"tom-quickstart\" }, \
      { \"ParameterKey\": \"RDGWCIDR\", \"ParameterValue\": \"0.0.0.0/0\" }, \
      { \"ParameterKey\": \"RestoreModePassword\", \"ParameterValue\": \"W/GdGax+1CebYQ74\" }, \
      { \"ParameterKey\": \"QSS3BucketName\", \"ParameterValue\": \"tommcm-citrix-us-west-1\" }, \
      { \"ParameterKey\": \"DomainAdminPassword\", \"ParameterValue\": \"W/GdGax+1CebYQ74\" } ]" \
        --capabilities CAPABILITY_NAMED_IAM