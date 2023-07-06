#!/usr/bin/env bash

SESSION_NAME=UpdateLambdaSession
BUCKET_NAME=bb-lambda-test
FILE_PATH=../
FILE_NAME=updated-lambda.zip
LAMBDA_NAME=bb-lambda-test-test
REGION=us-east-1

if [[ -z $AWS_SECRET_ACCESS_KEY ]] || [[ -z $AWS_ACCESS_KEY_ID ]] || [[ -z $ROLE ]];
then
   printf "Expecting AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and ROLE envvars!"
   exit 1
fi

printf "Assuming role...\n"

export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
$(aws sts assume-role \
--role-arn ${ROLE} \
--role-session-name ${SESSION_NAME} \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
--output text))

printf "Copying new file...\n"

aws s3 cp ${FILE_PATH}${FILE_NAME} s3://${BUCKET_NAME}/${FILE_NAME}

printf "Updating Lambda code...\n"

aws lambda update-function-code --function-name ${LAMBDA_NAME} --s3-bucket ${BUCKET_NAME} --s3-key ${FILE_NAME} --region ${REGION}

printf "\nDONE\n"
