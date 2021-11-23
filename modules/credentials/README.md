# Credentials module

This module can be optionally used to create the service account and IAM role resources required to configure auto-scaling and observability of [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors) in Google cloud.

TODO - finish
Auto-scaling requires that the executor compute instances have permissions to emit metrics to Google Cloud. The sibling [executors module](https://registry.terraform.io/modules/sourcegraph/executors/google/latest/submodules/executors)

TODO - finish
Observability of executor compute resources require that the target Sourcegraph instance's Prometheus have permissions to scrape the executor compute resources.

TODO - finish
This module produces a `instance_scraper_credentials_file` TODO and a `metric_writer_credentials_file` TODO
