# Tyk Sync Example: GitOps API Management with Tyk

This project demonstrates how to set up a GitOps workflow for API management using Tyk, focusing on secure, efficient, and independent API deployments across multiple environments. The example repository illustrates how various tools (like Tyk Sync and Spectral) can be used to manage APIs in staging and production environments.

## Overview

This repository assumes users have two environments to manage - staging and production. The demo repository has been configured to manage these two environments on Tyk Cloud:

- **Staging**: [Staging Environment](https://rural-gander-adm.aws-euw2.cloud-ara.tyk.io/)
- **Production**: [Production Environment](https://relevant-oven-adm.aws-euw2.cloud-ara.tyk.io/)

Some example API configurations are provided, which can be found in the `infrastructure/staging/tyk/apis` directory:
- `httpbin_jwt` (A protected classic HTTP API)
- `petstore_jwt` (A protected OAS HTTP API)
- `petstore_keyless` (A keyless OAS HTTP API)
- `starwars` (UDG API)

3 example GitHub workflows are configured:
1. `tyk-lint.yml` - Validate API configurations against API configuration rulesets on pull requests
2. `tyk-staging.yml` - Validate and Sync API configurations to staging environment
3. `tyk-production.yml` - Promote API configurations from staging environment to production environment

## Getting Started

To set up your own API configurations repository:

### Prerequisites:

1. Two Tyk environments (Require Tyk v5.3+ for OAS API management) that can be accessed from GitHub Actions.

### Steps:

1. **Clone this repository** and set up your GitHub repositories with two environments named `staging` and `production`.
2. For each environment, configure the following secret and variables:
    - **Secret**: TYK_DASHBOARD_SECRET (API access key to the dashboard)
    - **Variables**:
        - API_TARGET_HOST (Target host for your APIs)
        - TYK_DASHBOARD_URL (Your dashboard URL)
        - TYK_SYNC_REPO (tykio/tyk-sync)
        - TYK_SYNC_VERSION (v1.5.1)

## How it Works

The GitOps workflow enables a seamless process for API deployment and management across different environments, allowing development teams to independently handle their APIs while ensuring security, governance, and consistency.

### Overview of the developer workflow

1. **Development and Testing**: Developers create or modify their API configurations in a local or shared development environment and test them thoroughly.
2. **Push Changes to Git**: After testing, the developer commits the changes to a feature branch and creates a pull request (PR).
3. **Linting and Validation**: The `tyk-lint.yml` workflow runs automatically on the PR, validating API configurations against defined rulesets to ensure they meet security and governance standards.
4. **Deploy to Staging**: Once the PR is reviewed and merged into the main branch, the `tyk-staging.yml` workflow triggers automatically, syncing validated API configurations to the staging environment.
5. **Promotion to Production**: After successful testing in the staging environment, the `tyk-production.yml` workflow can be manually triggered to promote the API configurations from staging to the production environment.

## Lint API configurations

The `tyk-lint.yml` workflow validates API configurations to ensure they comply with predefined rulesets before they are deployed to any environment.

- **Trigger**: Runs automatically on every pull request.
- **Process**:
    - Uses a classic API ruleset ([tykapi-ruleset.yaml](https://github.com/caroltyk/tyk-sync-example/blob/main/infrastructure/staging/tyk/tykapi-ruleset.yaml)) to validate Tyk Classic APIs (e.g., checks to ensure APIs are not keyless).
    - Uses an OAS ruleset ([tykoas-ruleset.yaml](https://github.com/caroltyk/tyk-sync-example/blob/main/infrastructure/staging/tyk/tykoas-ruleset.yaml)) to validate OAS APIs against industry-standard guidelines.
- **Outcome**: Reports any validation errors directly in the GitHub PR. If there are any validation errors, the workflow will fail, preventing the changes from being merged until they are resolved.

## Sync API configurations to staging

The `tyk-staging.yml` workflow is responsible for syncing API configurations to the staging environment after successful linting.

- **Trigger**: Automatically triggered upon merging a pull request into the main branch.
- **Process**:
    - Validates all API configurations and policies to ensure they are correct.
    - Syncs the validated API configurations (found in `apis`, `assets`, and `policies` folders) to the staging environment.
    - Reports linting and sync status through exit codes; any errors during sync will be flagged.
- **Outcome**: If successful, the API configurations are deployed to the staging environment for further testing. Any errors are reported, and the workflow fails, requiring attention.

## Promote API configurations to production

The `tyk-production.yml` workflow handles the promotion of API configurations from the staging environment to the production environment.

- **Trigger**: Manually triggered after confirming successful deployment and testing in the staging environment.
- **Process**:
    - Copies API configurations from the `staging` folder to the `production` folder.
    - Validates the copied API configurations to ensure they are correct.
    - Syncs the validated API configurations to the Tyk Cloud production environment.
    - Reports the status of the sync process through exit codes; any errors will cause the workflow to fail.
- **Outcome**: Ensures that only thoroughly tested and validated APIs are promoted to production. If errors are found during the sync, they are reported, and the workflow is halted for correction.

By following this workflow, organizations can efficiently manage API deployments across multiple environments with a focus on security, governance, and developer productivity, leveraging the capabilities of Tyk tools like Tyk Sync and API Linter.