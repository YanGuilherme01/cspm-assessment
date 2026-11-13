# Cloud security posture assessment (AWS)

An end-to-end CSPM exercise: declare an intentionally misconfigured AWS sandbox, scan it, prioritize findings for executives, and fix every finding as code.

**Author:** [Yan Aragão](https://github.com/YanGuilherme01) · Solutions architect focused on cybersecurity architecture and business outcomes.

> **Status: lab design.** The Terraform, report generator and tests are complete. The findings are the *expected* results for the declared lab (synthetic). The lab has not yet been applied and scanned in a real account, so no measured before/after numbers are claimed. See [validation status](docs/validation-status.md).

## What this project demonstrates

- Thinking like an attacker and an auditor at once: each misconfiguration maps to a concrete finding ID, a benchmark control and a fix.
- Translating scanner output into an executive view: severity tiles, a weighted risk score and a remediation order.
- Remediation as code, reviewable in a pull request, instead of console clicks.
- Being explicit about what was and was not verified.

## Findings (expected for the lab)

| ID | Severity | Service | Finding | Fix |
| --- | --- | --- | --- | --- |
| F01 | Critical | S3 | Bucket with public-read ACL | [s3.tf](terraform/remediation/s3.tf) |
| F04 | Critical | IAM | Inline policy allows `*` on `*` | [iam.tf](terraform/remediation/iam.tf) |
| F05 | Critical | EC2 | SSH open to 0.0.0.0/0 | [network.tf](terraform/remediation/network.tf) |
| F02 | High | S3 | No default encryption | s3.tf |
| F03 | High | IAM | Access key older than 90 days | iam.tf (OIDC role) |
| F06 | High | CloudTrail | No multi-region trail | [logging.tf](terraform/remediation/logging.tf) |
| F07 | High | IAM | Root MFA disabled | Manual |
| F08 | High | VPC | Flow logs disabled | network.tf |
| F11 | High | GuardDuty | Detector disabled | logging.tf |
| F09 | Medium | S3 | Versioning disabled | s3.tf |
| F10 | Medium | KMS | Key rotation disabled | s3.tf |
| F12 | Medium | EC2 | EBS encryption by default off | network.tf |
| F13 | Medium | IAM | Weak password policy | iam.tf |
| F14 | Low | S3 | Access logging disabled | s3.tf |

14 findings · weighted risk score **63.6 / 100** (critical 10, high 7, medium 4, low 1). Sample output: [reports/assessment-report.html](reports/assessment-report.html).

## Run it

```bash
# Report from the bundled findings (or a Prowler JSON-OCSF export)
python3 scripts/generate_report.py findings/findings.json --out reports

# Tests
python3 -m unittest discover tests

# Lab (isolated sandbox account only, destroy afterwards)
cd terraform/insecure-lab && terraform init && terraform apply
```

Full procedure and control mapping: [methodology](docs/methodology.md).

## Repository layout

```text
cspm-assessment/
├── findings/findings.json        # expected findings for the lab
├── scripts/generate_report.py    # HTML + JSON summary, stdlib only
├── terraform/insecure-lab/       # intentionally misconfigured sandbox
├── terraform/remediation/        # one fix per finding, annotated with IDs
├── reports/                      # generated report
├── docs/                         # methodology, validation status
└── tests/
```

## Safety

The insecure lab creates a public bucket, an admin access key and SSH open to the internet. Use a dedicated sandbox account with no data, set a budget alarm, and run `terraform destroy` right after the scan. Never apply it to an account you care about.
