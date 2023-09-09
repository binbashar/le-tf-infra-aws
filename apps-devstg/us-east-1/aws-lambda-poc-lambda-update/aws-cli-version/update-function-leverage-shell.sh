#!/usr/bin/env bash

SESSION_NAME=UpdateLambdaSession
BUCKET_NAME=bb-lambda-test
FILE_PATH=../
FILE_NAME=updated-lambda.zip
LAMBDA_NAME=bb-lambda-test-test
REGION=us-east-1

if [[ -z $PROFILE ]] ;
then
   printf "Expecting PROFILE envvars!"
   exit 1
fi


printf "Copying new file...\n"

aws s3 cp ${FILE_PATH}${FILE_NAME} s3://${BUCKET_NAME}/${FILE_NAME} --region ${REGION} --profile ${PROFILE}

printf "Updating Lambda code...\n"

aws lambda update-function-code --function-name ${LAMBDA_NAME} --s3-bucket ${BUCKET_NAME} --s3-key ${FILE_NAME} --region ${REGION} --profile ${PROFILE}

printf "\nDONE\n"
