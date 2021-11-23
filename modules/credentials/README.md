# Credentials module

This module can be optionally used to create the service account and IAM role resources required to configure auto-scaling and observability of [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors) in Google cloud.

Auto-scaling requires that the executor compute instances have permissions to emit metrics to Google Cloud. As outlined in [how to configure auto scaling](https://docs.sourcegraph.com/admin/deploy_executors#google), the Sourcegraph `worker` service must set the `EXECUTOR_METRIC_GOOGLE_APPLICATION_CREDENTIALS_FILE` environment variable to be the same as the `metric_writer_credentials_file` value provided by running this module.

Observability of executor compute resources require that the target Sourcegraph instance's Prometheus have permissions to scrape the executor compute resources. As outlined in [how to configure observability](https://docs.sourcegraph.com/admin/deploy_executors#google-1), the `instance_scraper_credentials_file` value provided by running this module must be supplied to the Sourcegraph Prometheus instance.
