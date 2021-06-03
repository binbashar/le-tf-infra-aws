metrics = [

  {
    metric_name       = "AuthorizationFailureCount"
    alarm_description = "Alarms when an unauthorized API call is made."
    filter_pattern    = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    alarm_period      = "600"
    alarm_threshold   = "10"
  },
  {
    metric_name       = "S3BucketActivityEventCount"
    alarm_description = "Alarms when an API call is made to S3 to put or delete a Bucket, Bucket Policy or Bucket ACL."
    filter_pattern    = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
  },
  {
    metric_name       = "SecurityGroupEventCount"
    alarm_description = "Alarms when an API call is made to create, update or delete a Security Group."
    filter_pattern    = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  },
  {
    metric_name       = "NetworkAclEventCount",
    alarm_description = "Alarms when an API call is made to create, update or delete a Network ACL."
    filter_pattern    = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  },
  {
    metric_name       = "GatewayEventCount"
    alarm_description = "Alarms when an API call is made to create, update or delete a Customer or Internet Gateway."
    filter_pattern    = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  },
  {
    metric_name       = "VpcEventCount"
    alarm_description = "Alarms when an API call is made to create, update or delete a VPC, VPC peering connection or VPC connection to classic."
    filter_pattern    = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  },
  {
    metric_name       = "EC2InstanceEventCount"
    alarm_description = "Alarms when an API call is made to create, terminate, start, stop or reboot an EC2 instance."
    filter_pattern    = "{ ($.eventName = RunInstances) || ($.eventName = RebootInstances) || ($.eventName = StartInstances) || ($.eventName = StopInstances) || ($.eventName = TerminateInstances) }"
  },
  {
    metric_name       = "EC2LargeInstanceEventCount"
    alarm_description = "Alarms when an API call is made to create, terminate, start, stop or reboot a 4x-large or greater EC2 instance."
    filter_pattern    = "{ ($.eventName = RunInstances) && (($.requestParameters.instanceType = *.8xlarge) || ($.requestParameters.instanceType = *.4xlarge) || ($.requestParameters.instanceType = *.16xlarge) || ($.requestParameters.instanceType = *.10xlarge) || ($.requestParameters.instanceType = *.12xlarge) || ($.requestParameters.instanceType = *.24xlarge)) }"
  },
  {
    metric_name       = "CloudTrailEventCount"
    alarm_description = "Alarms when an API call is made to create, update or delete a .cloudtrail. trail, or to start or stop logging to a trail."
    filter_pattern    = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  },
  {
    metric_name       = "ConsoleSignInFailureCount"
    alarm_description = "Alarms when an unauthenticated API call is made to sign into the console."
    filter_pattern    = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  },
  {
    metric_name       = "IAMPolicyEventCount"
    alarm_description = "Alarms when an API call is made to change an IAM policy."
    filter_pattern    = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) ||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
  },
  {
    metric_name       = "ConsoleSignInWithoutMfaCount"
    alarm_description = "Alarms when a user logs into the console without MFA."
    filter_pattern    = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
  },
  {
    metric_name       = "RootAccountUsageCount"
    alarm_description = "Alarms when a root account usage is detected."
    filter_pattern    = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  },
  {
    metric_name       = "KMSKeyPendingDeletionErrorCount"
    alarm_description = "Alarms when a customer created KMS key is pending deletion."
    filter_pattern    = "{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion))}"
  },
  {
    metric_name       = "AWSConfigChangeCount"
    alarm_description = "Alarms when AWS Config changes."
    filter_pattern    = "{($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder))}"
  },
  {
    metric_name       = "RouteTableChangesCount"
    alarm_description = "Alarms when route table changes are detected."
    filter_pattern    = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
  },

]

