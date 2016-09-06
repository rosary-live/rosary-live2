#!/bin/bash

# Check if the AWS CLI is in the PATH
found=$(which aws)
if [ -z "$found" ]; then
  echo "Please install the AWS CLI under your PATH: http://aws.amazon.com/cli/"
  exit 1
fi

# Check if jq is in the PATH
found=$(which jq)
if [ -z "$found" ]; then
  echo "Please install jq under your PATH: http://stedolan.github.io/jq/"
  exit 1
fi

FUNCTION=StartBroadcasting

# Read other configuration from config.json
REGION=$(jq -r '.REGION' config.json)
BUCKET=$(jq -r '.BUCKET' config.json)
MAX_AGE=$(jq -r '.MAX_AGE' config.json)
IDENTITY_POOL_ID=$(jq -r '.IDENTITY_POOL_ID' config.json)
DEVELOPER_PROVIDER_NAME=$(jq -r '.DEVELOPER_PROVIDER_NAME' config.json)
PROFILE=$(jq -r '.AWS_PROFILE' config.json)

echo "Updating ${PROFILE} function $FUNCTION begin..."
zip -r $FUNCTION.zip index.js config.json node_modules
aws lambda update-function-code --profile ${PROFILE} --function-name ${FUNCTION} --zip-file fileb://${FUNCTION}.zip --region $REGION
rm $FUNCTION.zip
echo "Updating function $FUNCTION end"
