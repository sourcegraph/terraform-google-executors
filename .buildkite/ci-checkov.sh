#!/usr/bin/env bash

asdf install python 3.10.0

# In case it reports already installed
asdf shell python 3.10.0

# Install and run the plugin for checkov
# Use the full path to run pip3.10
/root/.asdf/installs/python/3.10.0/bin/pip3.10 install checkov

# List of checks we do not want to run here
# This is a living list and will see additions and mostly removals over time.
SKIP_CHECKS="CKV_GCP_22,CKV_GCP_66,CKV_GCP_13,CKV_GCP_71,CKV_GCP_61,CKV_GCP_21,CKV_GCP_65,CKV_GCP_67,CKV_GCP_20,CKV_GCP_69,CKV_GCP_12,CKV_GCP_24,CKV_GCP_25,CKV_GCP_64,CKV_GCP_68,CKV2_AWS_5,CKV2_GCP_3,CKV2_GCP_5,CKV_AWS_23,CKV_GCP_70,CKV_GCP_62,CKV_GCP_62,CKV_GCP_62,CKV_GCP_62,CKV_GCP_29,CKV_GCP_39"

# Run checkov
/root/.asdf/installs/python/3.10.0/bin/checkov --skip-check $SKIP_CHECKS --quiet --framework terraform --compact -d .

# Options
# --quiet: Only show failing tests
# --compact: Do not show code snippets
# --framework: Only scan terraform code

# Capture the error code
CHECKOV_EXIT_CODE="$?"

# We check the exit code and display a warning if anything was found
if [[ "$CHECKOV_EXIT_CODE" != 0 ]]; then
  buildkite-agent annotate 'Possible Terraform security issues found.  Please refer to the Sourcegraph handbook for guidance <a target="_blank" href="https://handbook.sourcegraph.com/product-engineering/engineering/cloud/security/checkov">here</a>.' --style 'warning' --context 'ctx-warn'
fi
