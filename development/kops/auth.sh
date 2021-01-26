export AWS_DEFAULT_PROFILE=default
export AWS_PROFILE=default
assume_test_role_output=`aws sts assume-role --role-arn $TEST_ROLE_ARN --role-session-name test-role-session`
export AWS_ACCESS_KEY_ID=`echo $assume_test_role_output|jq -r .Credentials.AccessKeyId`
export AWS_SECRET_ACCESS_KEY=`echo $assume_test_role_output|jq -r .Credentials.SecretAccessKey`
export AWS_SESSION_TOKEN=`echo $assume_test_role_output|jq -r .Credentials.SessionToken`
unset AWS_DEFAULT_PROFILE
unset AWS_PROFILE
unset AWS_SDK_LOAD_CONFIG
aws sts get-caller-identity
