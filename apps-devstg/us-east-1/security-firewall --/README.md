 |                                              AWS WAF Managed Rule Group                                              | OWASP ID                                              |
 | :--------------------------------------------------------------------------------------------------------------: | ----------------------------------------------------- |
 |                                          [AWSManagedRulesCommonRuleSet]                                          | [A01:2021 - Broken Access Control]                      |
 |                                                       N/A                                                        | [A02:2021 - Cryptographic Failures]                     |
 |                                           [AWSManagedRulesSQLiRuleSet]                                           | [A03:2021 - Injection]                                  |
 |                                                       N/A                                                        | [A04:2021 - Insecure Design]                            |
 |                                                       N/A                                                        | [A05:2021 - Security Misconfiguration]                  |
 |                                      [AWSManagedRulesKnownBadInputsRuleSet]                                      | [A06:2021 - Vulnerable and Outdated Components]         |
 | [AWSManagedRulesATPRuleSet] <br> [AWSManagedRulesAmazonIpReputationList] <br> [AWSManagedRulesBotControlRuleSet] | [A07:2021 - Identification and Authentication Failures] |
 |                                                       N/A                                                        | [A08:2021 - Software and Data Integrity Failures]       |
 |                                                       N/A                                                        | [A09:2021 - Security Logging and Monitoring Failures]   |
 |                                                       N/A                                                        | [A10:2021 - Server-Side Request Forgery (SSRF)]         |



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