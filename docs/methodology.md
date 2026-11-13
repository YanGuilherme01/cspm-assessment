# Methodology

1. **Build** the sandbox from `terraform/insecure-lab` in an isolated AWS account (AWS Organizations sandbox OU, no production data, budget alarm set).
2. **Scan** with Prowler and ScoutSuite:
   ```bash
   prowler aws --region us-east-1 --output-formats json-ocsf html --output-directory output/prowler
   scout aws --report-dir output/scoutsuite
   ```
3. **Normalize** results. `scripts/generate_report.py` reads either this repository's `findings/findings.json` or a Prowler JSON-OCSF export and keeps only failed checks.
4. **Prioritize** by weighted severity (critical 10, high 7, medium 4, low 1). The risk score is the weighted total as a percentage of the worst case, so it compares runs of different sizes.
5. **Remediate** as code with `terraform/remediation`. Every resource is annotated with the finding ID it closes. F07 (root MFA) stays a manual, documented step.
6. **Re-scan** and record the before/after delta in `docs/validation-status.md`.
7. **Destroy** the lab: `terraform destroy`.

## Finding-to-control mapping

| Finding | CIS AWS Foundations v3 | NIST CSF 2.0 |
| --- | --- | --- |
| F01, F09, F14 | 2.1.4, 2.1.3, 3.6 | PR.DS-01, PR.DS-11, DE.CM-01 |
| F02, F10, F12 | 2.1.1, 3.6, 2.2.1 | PR.DS-01 |
| F03, F04, F07, F13 | 1.14, 1.16, 1.5, 1.8 | PR.AA-01, PR.AA-05 |
| F05, F08 | 5.2, 3.9 | PR.IR-01, DE.CM-01 |
| F06, F11 | 3.1, (GuardDuty best practice) | DE.CM-01, DE.AE-02 |

Control numbers are for orientation; confirm them against the benchmark version you report on.
