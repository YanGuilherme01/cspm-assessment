# Validation status

| Item | Status |
| --- | --- |
| `findings/findings.json` | Synthetic: expected findings for the declared lab, not captured from AWS |
| `scripts/generate_report.py` | Unit-tested (`python3 -m unittest discover tests`) |
| `terraform/insecure-lab` | `terraform validate` passes (Terraform 1.9.8, AWS provider 5.x); not yet applied |
| `terraform/remediation` | `terraform validate` passes; not yet applied or re-scanned |
| Prowler / ScoutSuite run | Not yet performed |
| Before/after risk score | Pending a real run |

Do not quote these numbers as measured results until the scan and re-scan rows are completed.
