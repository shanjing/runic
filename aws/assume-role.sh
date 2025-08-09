#!/bin/bash
ROLE_ARN="arn:aws:iam::403692606562:role/admin-role"
MFA_ARN="arn:aws:iam::403692606562:mfa/shaniac"

echo "Enter your MFA code:"
read TOKEN

CREDS=$(aws sts assume-role \
  --profile shaniac \
  --role-arn $ROLE_ARN \
  --role-session-name shaniacSession \
  --serial-number $MFA_ARN \
  --token-code $TOKEN \
  --duration-seconds 14400)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

echo "✅ AssumeRole complete — you're now using $AWS_ACCESS_KEY_ID"
aws sts get-caller-identity
