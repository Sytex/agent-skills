#!/usr/bin/env python3
"""Regression tests for the Oompa static validator."""

import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from create_oompa import create, render
from validate_oompa import validate


SKILL_DIR = Path(__file__).resolve().parent
TEMPLATE_PATH = SKILL_DIR / "TEMPLATE.py"


def validate_source(source, *, allow_template_placeholders=True):
    return validate(
        Path("fixture.py"),
        source=source,
        allow_template_placeholders=allow_template_placeholders,
    )


class ValidateOompaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.template = TEMPLATE_PATH.read_text(encoding="utf-8")

    def test_canonical_template_contract_is_valid(self):
        self.assertEqual(validate_source(self.template), [])

    def test_rejects_unsafe_default(self):
        source = self.template.replace("dry_run=True", "dry_run=False", 1)
        self.assertIn("run() must default to dry_run=True", validate_source(source))

    def test_rejects_unimplemented_domain_hooks_in_real_script(self):
        source = (
            self.template.replace('SCRIPT_NAME = "REPLACE_script_name"', 'SCRIPT_NAME = "repair"')
            .replace('SCRIPT_SLUG = "REPLACE-script-slug"', 'SCRIPT_SLUG = "repair"')
            .replace('CUSTOMER_SLUG = "REPLACE-customer"', 'CUSTOMER_SLUG = "customer"')
            .replace("ORGANIZATION_ID = 0", "ORGANIZATION_ID = 154")
        )
        errors = validate_source(source, allow_template_placeholders=False)
        self.assertTrue(any(error.startswith("unimplemented domain hooks:") for error in errors))

    def test_rejects_unfinished_todo_in_real_script(self):
        errors = validate_source(
            self.template + "\n# TODO: implement another condition\n",
            allow_template_placeholders=False,
        )
        self.assertIn("unfinished TODO placeholder", errors)

    def test_rejects_s3_publication_before_local_validation(self):
        source = self.template.replace(
            "        self.validate_configuration()\n"
            "        source_manifest = self.publish_and_verify_source()",
            "        source_manifest = self.publish_and_verify_source()\n"
            "        self.validate_configuration()",
            1,
        )
        self.assertIn(
            "run() must validate local configuration before publishing to S3",
            validate_source(source),
        )

    def test_rejects_apply_without_gates(self):
        source = self.template + "\noompa.run(dry_run=False)\n"
        errors = validate_source(source)
        self.assertTrue(any(error.startswith("unsafe run(dry_run=False)") for error in errors))

    def test_rejects_hardcoded_webhook(self):
        source = self.template + (
            '\nWEBHOOK = "https://discord.com/api/webhooks/123456789/secret-value"\n'
        )
        self.assertTrue(
            any("possible hardcoded secret" in error for error in validate_source(source))
        )

    def test_generator_configures_identity_and_refuses_overwrite(self):
        identity = {
            "script_name": "repair_documents",
            "script_slug": "repair-documents",
            "version": "v2",
            "customer": "winity",
            "organization_id": 154,
        }
        source = render(**identity)
        self.assertIn('SCRIPT_VERSION = "v2"', source)
        self.assertIn("ORGANIZATION_ID = 154", source)
        self.assertNotIn("TODO", source)

        with TemporaryDirectory() as directory:
            target = create(output_root=Path(directory), **identity)
            self.assertEqual(target.read_text(encoding="utf-8"), source)
            with self.assertRaises(FileExistsError):
                create(output_root=Path(directory), **identity)

    def test_generator_rejects_invalid_slug(self):
        with self.assertRaisesRegex(ValueError, "invalid script_slug"):
            render(
                script_name="repair_documents",
                script_slug="Repair Documents",
                version="v1",
                customer="winity",
                organization_id=154,
            )


if __name__ == "__main__":
    unittest.main()
