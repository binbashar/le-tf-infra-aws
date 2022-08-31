# Security Firewall Layer
## AWS WAFv2

### Reference Table between AWS Managed Rules and OWASP Top 10 Vulnerabilities

| OWASP ID|AWS WAF Managed Rule Group | Rules Description | Terraform Code Related |
| - | :-: | - | - |
| [A01:2021 - Broken Access Control] | [AWSManagedRulesCommonRuleSet] | </pre>SizeRestrictions_QUERYSTRING<br>EC2MetaDataSSRF_QUERYARGUMENTS<br>GenericLFI_QUERYARGUMENTS<br>RestrictedExtensions_QUERYARGUMENTS<br>GenericRFI_QUERYARGUMENTS<br>CrossSiteScripting_QUERYARGUMENTS | <pre>{<br> name = "AWSManagedRulesCommonRuleSet" <br> priority = "4" <br>} |
| [A02:2021 - Cryptographic Failures]| N/A | N/A | N/A|
| [A03:2021 - Injection] | [AWSManagedRulesSQLiRuleSet] | SQLi_QUERYARGUMENTS<br>SQLiExtendedPatterns_QUERYARGUMENTS<br>SQLi_BODY<br>SQLiExtendedPatterns_BODY<br>SQLi_COOKIE | <pre>{<br> name = "AWSManagedRulesSQLiRuleSet" <br> priority = "6" <br>} |
| [A04:2021 - Insecure Design] | N/A | N/A | N/A |
| [A05:2021 - Security Misconfiguration] | N/A | N/A | N/A |
| [A06:2021 - Vulnerable and Outdated Components] | [AWSManagedRulesKnownBadInputsRuleSet] | ExploitablePaths_URIPATH<br>Log4JRCE_HEADER<br>Log4JRCE_QUERYSTRING<br>Log4JRCE_URI<br>Log4JRCE_BODY | <pre>{<br> name = "AWSManagedRulesKnownBadInputsRuleSet" <br> priority = "5" <br>} |
| [A07:2021 - Identification and Authentication Failures] | [AWSManagedRulesAmazonIpReputationList]<br>[AWSManagedRulesBotControlRuleSet]<br>[AWSManagedRulesATPRuleSet]<br>(**ATPRuleSet is not Terraform supported yet <br> See related [#Issue 23287])**| AttributePasswordTraversal<br>AttributeUsernameTraversal<br>AttributeCompromisedCredentials<br>MissingCredential<br>VolumetricSession TokenRejected<br>AWSManagedIPReputationList<br>AWSManagedReconnaissanceList<br>CategoryAdvertising<br>CategoryArchiver<br>CategoryContentFetcher<br>CategoryHttpLibrary<br>CategoryLinkChecker<br>CategoryMiscellaneous<br>CategoryMonitoring<br>CategoryScrapingFramework<br>CategorySecurity CategorySeo<br>CategorySocialMedia<br>CategorySearchEngine<br>SignalAutomatedBrowser<br>SignalKnownBotDataCenter<br>SignalNonBrowserUserAgent | <pre>{<br> name = "AWSManagedRulesAmazonIpReputationList" <br> priority = "1" <br>} <br> {<br> name = "AWSManagedRulesAnonymousIpList" <br> priority = "2" <br>} <br> {<br> name = "AWSManagedRulesBotControlRuleSet" <br> priority = "3" <br>}  |
| [A08:2021 - Software and Data Integrity Failures] | N/A | N/A | |
| [A09:2021 - Security Logging and Monitoring Failures] | N/A | N/A | |
| [A10:2021 - Server-Side Request Forgery (SSRF)] | [AWSManagedRulesCommonRuleSet] | EC2MetaDataSSRF_BODY<br>EC2MetaDataSSRF_COOKIE<br>EC2MetaDataSSRF_URIPATH<br>EC2MetaDataSSRF_QUERYARGUMENTS | <pre>{<br> name = "AWSManagedRulesCommonRuleSet" <br> priority = "4" <br>} |



## Custom Rate Limit Rule

This is a Custom Rule to WAFv2 to be able to set an IP Rate Limit. This is a basic example and can be customized as needed. See reference examples [terraform-aws-waf-webaclv2/examples/wafv2-ip-rules]

```text
    ###Custom IP Rate Based Rule
    {
      name     = "CustomRulesIpRateLimitBasedRuleSet"
      priority = "0"

      action = "block"

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "CustomRuleIpRateLimitBasedRuleSet-Metrics"
        sampled_requests_enabled   = true
      }

      rate_based_statement = {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    },
```

## ALB Demo Setup and `terraform.tfvars`

Through the terraform.tfvars, it is possible to configure the deployment of a sample ALB to connect to WAFv2 and run different tests. This allows you to have a quick reference for your implementation. In other cases, possibly the ALB will be managed by a Kubernetes cluster through a Controller. In case of using AWS Load Balancer Controller, you will have to indicate the Annotations mentioned in the documentation with the WAF ARN. See related documentation [aws-load-balancer-controller//ingress/waf-annotations]

```text
# #------------------------------------------------------------------------------
# # WAFv1 GLOBAL Config
# #------------------------------------------------------------------------------
enable_wafv1_global = false

# #------------------------------------------------------------------------------
# # WAFv1 REGIONAL Config
# #------------------------------------------------------------------------------
enable_wafv1_regional = false

# #------------------------------------------------------------------------------
# # WAFv2 REGIONAL Config
# #------------------------------------------------------------------------------
enable_wafv2_regional = true

# #------------------------------------------------------------------------------
# # ALB WAF Demo Config
# #------------------------------------------------------------------------------
alb_waf_example = {
  enabled = true
  # Load balancer internal (true) or internet-facing (false)
  internal = true
  # Load balancer type: application or network
  type = "application"
}

# #------------------------------------------------------------------------------
# # ALB WAF SG Config
# #------------------------------------------------------------------------------
#Add your Public IP to Allow Traffic Inbound ["XXX.XXX.XXX.XXX/32"]
ingress_cidr_blocks = []

```
**IMPORTANT:**
Depending on the configuration of your networking layer, you will have to select between an internet-facing or internal ALB. In case you arrive by VPN, it will not be necessary to indicate your IP in the list of allowed CIDRs. It is recommended that if you are going to expose your ALB to the internet for testing, you restrict access by setting the CIDR in the allowed list `ingress_cidr_blocks = []`

[AWSManagedRulesCommonRuleSet]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html
[AWSManagedRulesSQLiRuleSet]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-sql-db  
[AWSManagedRulesKnownBadInputsRuleSet]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html
[AWSManagedRulesATPRuleSet]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-atp.html
[AWSManagedRulesAmazonIpReputationList]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-ip-rep.html
[AWSManagedRulesBotControlRuleSet]: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-bot.html

[A01:2021 - Broken Access Control]: https://owasp.org/Top10/01_2021-Broken_Access_Control
[A02:2021 - Cryptographic Failures]: https://owasp.org/Top10/A02_2021-Cryptographic_Failures
[A03:2021 - Injection]: https://owasp.org/Top10/A03_2021-Injection
[A04:2021 - Insecure Design]: https://owasp.org/Top10/A04_2021-Insecure_Design
[A05:2021 - Security Misconfiguration]: https://owasp.org/Top10/A05_2021-Security_Misconfiguration
[A06:2021 - Vulnerable and Outdated Components]: https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components
[A07:2021 - Identification and Authentication Failures]: https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures
[A08:2021 - Software and Data Integrity Failures]: https://owasp.org/Top10/A08_2021-Software_and_Data_Integrity_Failures
[A09:2021 - Security Logging and Monitoring Failures]: https://owasp.org/Top10/A09_2021-Security_Logging_and_Monitoring_Failures
[A10:2021 - Server-Side Request Forgery (SSRF)]: https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29

[#Issue 23287]: https://github.com/hashicorp/terraform-provider-aws/issues/23287

[terraform-aws-waf-webaclv2/examples/wafv2-ip-rules]: https://github.com/binbashar/terraform-aws-waf-webaclv2/blob/main/examples/wafv2-ip-rules/main.tf
[aws-load-balancer-controller//ingress/waf-annotations]: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/#addons:~:text=4614%2Da86d%2Dadb1810b7fbe-,alb.ingress.kubernetes.io/wafv2%2Dacl%2Darn,-specifies%20ARN%20for
