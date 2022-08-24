| OWASP ID|AWS WAF Managed Rule Group | Rules Description|
| - | :-: | - |
| [A01:2021 - Broken Access Control] | [AWSManagedRulesCommonRuleSet] | SizeRestrictions_QUERYSTRING<br>EC2MetaDataSSRF_QUERYARGUMENTS<br>GenericLFI_QUERYARGUMENTS<br>RestrictedExtensions_QUERYARGUMENTS<br>GenericRFI_QUERYARGUMENTS<br>CrossSiteScripting_QUERYARGUMENTS |
| [A02:2021 - Cryptographic Failures]| N/A | N/A |
| [A03:2021 - Injection] | [AWSManagedRulesSQLiRuleSet] | SQLi_QUERYARGUMENTS<br>SQLiExtendedPatterns_QUERYARGUMENTS<br>SQLi_BODY<br>SQLiExtendedPatterns_BODY<br>SQLi_COOKIE                                                                                  |
| [A04:2021 - Insecure Design] | N/A | N/A |
| [A05:2021 - Security Misconfiguration] | N/A | N/A |
| [A06:2021 - Vulnerable and Outdated Components] | [AWSManagedRulesKnownBadInputsRuleSet] | ExploitablePaths_URIPATH<br>Log4JRCE_HEADER<br>Log4JRCE_QUERYSTRING<br>Log4JRCE_URI<br>Log4JRCE_BODY |
| [A07:2021 - Identification and Authentication Failures] | [AWSManagedRulesATPRuleSet]<br>[AWSManagedRulesAmazonIpReputationList]<br>[AWSManagedRulesBotControlRuleSet] | AttributePasswordTraversal<br>AttributeUsernameTraversal<br>AttributeCompromisedCredentials<br>MissingCredential<br>VolumetricSession TokenRejected<br>AWSManagedIPReputationList<br>AWSManagedReconnaissanceList<br>CategoryAdvertising<br>CategoryArchiver<br>CategoryContentFetcher<br>CategoryHttpLibrary<br>CategoryLinkChecker<br>CategoryMiscellaneous<br>CategoryMonitoring<br>CategoryScrapingFramework<br>CategorySecurity CategorySeo<br>CategorySocialMedia<br>CategorySearchEngine<br>SignalAutomatedBrowser<br>SignalKnownBotDataCenter<br>SignalNonBrowserUserAgent |
| [A08:2021 - Software and Data Integrity Failures] | N/A | N/A |
| [A09:2021 - Security Logging and Monitoring Failures] | N/A | N/A |
| [A10:2021 - Server-Side Request Forgery (SSRF)] | N/A | EC2MetaDataSSRF_BODY<br>EC2MetaDataSSRF_COOKIE<br>EC2MetaDataSSRF_URIPATH<br>EC2MetaDataSSRF_QUERYARGUMENTS |

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