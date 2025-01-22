#!/usr/bin/env bash

set -euo pipefail

USAGE="Usage: $0 aws-profile-name"

if [ $# -eq 0 ]; then
  echo "Error exiting... missing AWS profile name"
  echo $USAGE
  exit 1
fi

if [ ! $(which aws) ]; then
  echo "Error: aws cli must be installed"
  echo "exited"
  exit 1
fi

AWS_PROFILE=${1:-}
USER_NAME="${USER_NAME:-terraform}"

export AWS_PROFILE="${AWS_PROFILE}"
ACCNT=$(aws sts get-caller-identity --query Account --output text)

echo "Using AWS_PROFILE=${AWS_PROFILE} with ${ACCNT}"
export AWS_PROFILE="${AWS_PROFILE}"

echo "Checking for group..."
if aws iam get-group --group-name ${USER_NAME}; then
  echo "Found terraform group ${USER_NAME}"
else
  echo "Group not found.  Creating group ${USER_NAME}..."
  group_cmd="aws iam create-group --group-name ${USER_NAME}"
  ${group_cmd}
fi

echo "Attaching admin policy..."
admin_policy_cmd="aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --group-name ${USER_NAME}"
${admin_policy_cmd}

echo "Attaching s3 policy..."
s3_policy_cmd="aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name ${USER_NAME}"
${s3_policy_cmd}

echo "Checking for user..."
if aws iam get-user --user-name ${USER_NAME}; then
  echo "Found terraform user ${USER_NAME}"
else
  echo "User not found.  Creating user ${USER_NAME}..."
  create_user_cmd="aws iam create-user --user-name ${USER_NAME}"
  ${create_user_cmd}
fi

echo "Add terraform user to group"
add_group_cmd="aws iam add-user-to-group --user-name ${USER_NAME} --group-name ${USER_NAME}"
${add_group_cmd}

echo "Creating s3 bucket"
bucket_create_cmd="aws s3 mb s3://terraform-${ACCNT}"
${bucket_create_cmd}

echo "Create access key for terraform user"
access_key_cmd="aws iam create-access-key --user-name ${USER_NAME}"
access_key_results=$( ${access_key_cmd} )
echo "${access_key_results}"
