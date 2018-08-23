aws cloudformation create-stack \
  --stack-name citrixcloudstack-`echo $(date +%s)` \
  --template-body file://../templates/citrix-virtualapps-service-resourcelocation-master.yaml \
  --disable-rollback \
    --parameters \
    "[{ \"ParameterKey\": \"ADServer1PrivateIP\", \"ParameterValue\": \"10.0.1.5\" }, 
      { \"ParameterKey\": \"ADServer2PrivateIP\", \"ParameterValue\": \"10.0.0.64\" }, \
      { \"ParameterKey\": \"CitrixAPIClientID\", \"ParameterValue\": \"4d887280-a72d-4df0-b526-7dc44c579e6a\" }, \
      { \"ParameterKey\": \"CitrixAPIClientSecret\", \"ParameterValue\": \"7hwMPEQyLczMrpaKjVG8HQ==\" }, \
      { \"ParameterKey\": \"CitrixCloudConnectorsWindowsServerVersion\", \"ParameterValue\": \"WS2016FULLBASE\" }, \
      { \"ParameterKey\": \"CitrixCloudConnectorInstanceType\", \"ParameterValue\": \"t2.large\" }, \
      { \"ParameterKey\": \"CitrixCustomerId\", \"ParameterValue\": \"Amazon660216\" }, \
      { \"ParameterKey\": \"DomainNetBIOSName\", \"ParameterValue\": \"example\" }, \
      { \"ParameterKey\": \"DomainDNSName\", \"ParameterValue\": \"example.com\" }, \
      { \"ParameterKey\": \"DomainAdminPassword\", \"ParameterValue\": \"W/GdGax+1CebYQ74\" }, \
      { \"ParameterKey\": \"KeyPairName\", \"ParameterValue\": \"key-pair-tommcm-general\" }, \
      { \"ParameterKey\": \"PrivateInfraSubnet1ID\", \"ParameterValue\": \"subnet-05e25a7fe22f510c2\" }, \
      { \"ParameterKey\": \"PrivateInfraSubnet2ID\", \"ParameterValue\": \"subnet-042f366503a3dc8d8\" }, \
      { \"ParameterKey\": \"PrivateVDASubnet1ID\", \"ParameterValue\": \"subnet-033572d6f599d96b3\" }, \
      { \"ParameterKey\": \"PrivateVDASubnet2ID\", \"ParameterValue\": \"subnet-00bbb96a4e3d50ee0\" }, \
      { \"ParameterKey\": \"QSS3BucketName\", \"ParameterValue\": \"tommcm-citrix-us-west-1\" }, \
      { \"ParameterKey\": \"QSS3KeyPrefix\", \"ParameterValue\": \"quickstart-citrix-xenappxendesktop/\" }, \
      { \"ParameterKey\": \"CitrixResourceLocation\", \"ParameterValue\": \"tom-qs-`echo $(date +%s)`\" }, \
      { \"ParameterKey\": \"CitrixVDAWindowsServerVersion\", \"ParameterValue\": \"WS2016FULLBASE\" }, \
      { \"ParameterKey\": \"CitrixVDAInstanceType\", \"ParameterValue\": \"t2.large\" }, \
      { \"ParameterKey\": \"VPCID\", \"ParameterValue\": \"vpc-0110b1d7de01c1c53\" }, \
      { \"ParameterKey\": \"CitrixHostingConnectionName\", \"ParameterValue\": \"AWS-Quickstart-`echo $(date +%s)`\" }, \
      { \"ParameterKey\": \"CitrixCatalogName\", \"ParameterValue\": \"CAT-AWS-Quickstart-`echo $(date +%s)`\" }, \
      { \"ParameterKey\": \"CitrixDeliveryGroupName\", \"ParameterValue\": \"DG-AWS-Quickstart-`echo $(date +%s)`\" }]" \
        --capabilities CAPABILITY_NAMED_IAM