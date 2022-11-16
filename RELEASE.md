# Release Process

At the moment, the release process is a manual process.

## Prepare PR

1. Update all links in `README.md` files from the previous version to the new version.
2. Update the [examples](./examples) `main.tf` files to use the new version.
3. Update the `mirror_image` in [docker-mirror](./modules/docker-mirror) to use the new version.
4. Update the `executor_image` in [executors](./modules/executors) to use the new version.
5. Open the PR
6. At the moment, Buildkite will fail because the new version does not actually exist yet. So, a force merge is required.

## Create Tag

1. Create a tag matching the new version (e.g. `v4.2.0`).
   - `git tag "vX.X.X"` (replace `X` with the versions)
2. Push the tag to remote.
  - `git push --tags`

## CI

1. Go to Buildkite and find the build for the tag.
2. Wait for build to complete.
   - If build failed, rerun (the Terraform Registry may lag behind causing build to fail)
