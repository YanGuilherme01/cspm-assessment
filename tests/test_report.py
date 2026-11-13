import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("generate_report", ROOT / "scripts" / "generate_report.py")
gr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gr)


class ReportTests(unittest.TestCase):
    def test_lab_findings_summary(self):
        meta, findings = gr.load_findings(ROOT / "findings" / "findings.json")
        s = gr.summarize(findings)
        self.assertEqual(s["total"], 14)
        self.assertEqual(s["by_severity"], {"critical": 3, "high": 6, "medium": 4, "low": 1})
        self.assertEqual(s["risk_score"], 63.6)
        self.assertEqual(meta["data_origin"], "synthetic")

    def test_empty_and_bounds(self):
        self.assertEqual(gr.risk_score([]), 0.0)
        self.assertEqual(gr.risk_score([{"severity": "critical"}]), 100.0)
        self.assertEqual(gr.risk_score([{"severity": "low"}]), 10.0)

    def test_prowler_ocsf_only_failures(self):
        tmp = ROOT / "tests" / "_ocsf.json"
        tmp.write_text(json.dumps([
            {"status_code": "FAIL", "severity": "High", "finding_info": {"title": "x"}, "resources": [{"group": {"name": "s3"}}]},
            {"status_code": "PASS", "severity": "Low"},
        ]))
        try:
            meta, f = gr.load_findings(tmp)
            self.assertEqual(len(f), 1)
            self.assertEqual(f[0]["severity"], "high")
        finally:
            tmp.unlink()

    def test_html_escapes(self):
        html_out = gr.render_html({}, [{"id": "X", "severity": "low", "service": "<s>", "title": "t", "remediation": "r"}],
                                  gr.summarize([{"severity": "low", "service": "<s>"}]), "now")
        self.assertIn("&lt;s&gt;", html_out)
        self.assertNotIn("<s>", html_out.split("<tbody>")[1])


if __name__ == "__main__":
    unittest.main()
