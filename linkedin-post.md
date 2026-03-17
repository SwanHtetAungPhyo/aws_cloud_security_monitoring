# LinkedIn Post

---

I'm transitioning into cloud engineering, and after a year working with AWS, I built something I wish existed at my last job -- a security monitoring platform that actually tells you when something goes wrong.

The whole thing is Terraform. IAM with enforced MFA (deny-all if your session doesn't have it), multi-region CloudTrail encrypted with a customer-managed KMS key, and a CloudWatch-to-SNS pipeline that emails me when it spots unauthorized API calls, root activity, failed logins, or IAM policy changes.

The part I'm most proud of: CloudTrail Lake. I wrote 10 SQL queries for threat hunting -- one of them groups failed API calls by source IP across regions. High failure count + many regions + many different actions = someone running a recon tool against your account.

To test all of this, I wrote attack simulation scripts. Unauthorized API calls, multi-region probes, secrets access attempts, S3 tampering. Ran them, waited a few minutes, queried Lake. Everything showed up. Alerts hit my inbox.

Hardest problem I ran into: one KMS key serving four AWS services (CloudTrail, CloudWatch Logs, SNS, CloudTrail Lake), each needing different permissions with different conditions. Four rounds of terraform apply to get the key policy right.

CI runs Trivy, Checkov, and TFLint on every push. Pre-commit hooks for the team.

30 Terraform files. 4 modules. ~$5-15/month on a dev account.

Repo in comments.

#AWS #CloudSecurity #Terraform #CloudEngineering #DevSecOps
