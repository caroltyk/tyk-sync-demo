# Tyk Sync Example: GitOps API Management with Tyk

This project demonstrates how to set up a GitOps workflow for API management using Tyk, focusing on secure, efficient, and independent API deployments across multiple environments. The example repository illustrates how various tools (like Tyk Sync and Spectral) can be used to manage APIs in staging and production environments.

## Overview

This repository assumes users have two environments to manage - staging and production. The demo repository has been configured to manage these two environments on Tyk Cloud:

- **Staging**: [Staging Environment](https://rural-gander-adm.aws-euw2.cloud-ara.tyk.io/)
- **Production**: [Production Environment](https://relevant-oven-adm.aws-euw2.cloud-ara.tyk.io/)

You can follow [our guides](#getting-started) to reuse this project to manage your own environments.

API configurations are organizied in the Git repository in following structure.
```
├── infrastructure
    ├── production 
    │   └── tyk
    │       ├── apis
    │       ├── assets
    │       └── policies
    └── staging
        └── tyk
            ├── apis
            ├── assets
            └── policies
```

Some example API configurations are provided, which can be found in the `infrastructure/staging/tyk/apis` directory:
- `httpbin_jwt` (A protected classic HTTP API)
- `petstore_jwt` (A protected OAS HTTP API)
- `petstore_keyless` (A keyless OAS HTTP API)

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

1. **Development and Testing**: Developers [create or modify their API configurations](#create-or-modify-api-configurations) in a local or shared development environment and test them thoroughly.
2. **Push Changes to Git**: After testing, the developer commits the changes to a feature branch and creates a pull request (PR).
3. **Linting and Validation**: The [`tyk-lint.yml` workflow](#lint-api-configurations) runs automatically on the PR, validating API configurations against defined rulesets to ensure they meet security and governance standards.
4. **Deploy to Staging**: Once the PR is reviewed and merged into the main branch, the [`tyk-staging.yml` workflow](#sync-api-configurations-to-staging) triggers automatically, syncing validated API configurations to the staging environment.
5. **Promotion to Production**: After successful testing in the staging environment, the [`tyk-production.yml` workflow](#promote-api-configurations-to-production) can be manually triggered to promote the API configurations from staging to the production environment.

### Benefits

Adopting this example design offers several key benefits:

1. **Increased Security and Governance**: By validating API configurations against predefined rulesets before deployment, the workflow ensures that APIs meet security standards and governance policies, reducing the risk of vulnerabilities.
2. **Improved Developer Productivity**: Automating the validation, deployment, and promotion processes allows developers to focus on building and refining APIs rather than manually managing deployments.
3. **Consistent Environments**: Using Git as the source of truth ensures consistent API configurations across environments, minimizing discrepancies between staging and production.
4. **Enhanced Collaboration**: The use of GitHub pull requests, linting, and automated checks fosters collaboration between teams, enabling faster code reviews and feedback cycles.
5. **Audit and Compliance**: Automated workflows provide a clear audit trail of changes and deployments, making it easier to track modifications and comply with organizational or regulatory requirements.
6. **Flexibility and Adaptability**: The example design can be easily adapted to different environments, CI/CD tools, and organizational structures, offering a versatile foundation for API management.

## Create or modify API configurations

To create or modify API configurations,

1. Set up and test APIs on a shared development or local environment.
2. Export required configurations using [tyk-sync](http://tyk.io/docs/tyk-sync) CLI.

    ```sh
    docker run -v $PWD:/app/data tykio/tyk-sync:v1.5.1 dump -d [DASHBOARD_URL] -s [DASHBOARD_ACCESS_KEY] -t /app/data
    ```

    Tyk sync will dump the API configurations to your local file system. The required API configurations can then be modified and pushed to Git.

3. Optionally, you can modify your API configurations. For example, you may want to parametized a field in the API definition so that Gateway will resolve the field from supported [KV storage](https://tyk.io/docs/tyk-configuration-reference/kv-store/#from-api-definitions) or environment variables.

    Example: 
    1. `jwt_source` in httpbin_jwt and petstore_jwt is set to `env://TYK_SECRET_KEYCLOAK_SOURCE`, allowing different gateways to configure different Keycloak realms for authentication.

    2. In this demo, Upstream URL in API is modified by a [custom script](https://github.com/caroltyk/tyk-sync-example/blob/main/.github/scripts/replace_target_host.sh) that replaces "TARGET_HOST" in upstream URL to a variable defined in GitHub during deployment.

## Lint API configurations

The `tyk-lint.yml` workflow validates API configurations to ensure they comply with predefined rulesets before they are deployed to any environment.

- **Trigger**: Runs automatically on every pull request.
- **Process**:
    - Uses a classic API ruleset ([tykapi-ruleset.yaml](https://github.com/caroltyk/tyk-sync-example/blob/main/infrastructure/staging/tyk/tykapi-ruleset.yaml)) to validate Tyk Classic APIs (e.g., checks to ensure APIs are not keyless).
    - Uses an OAS ruleset ([tykoas-ruleset.yaml](https://github.com/caroltyk/tyk-sync-example/blob/main/infrastructure/staging/tyk/tykoas-ruleset.yaml)) to validate OAS APIs against industry-standard guidelines.
- **Outcome**: Reports any validation errors directly in the GitHub PR. If there are any validation errors, the workflow will fail, preventing the changes from being merged until they are resolved.

## Sync API configurations to staging

The [`tyk-staging.yml`](https://github.com/caroltyk/tyk-sync-example/blob/main/.github/workflows/tyk-staging.yml) workflow is responsible for syncing API configurations to the staging environment after successful linting.

- **Trigger**: Automatically triggered upon merging a pull request into the `/infrastructure/staging/tyk` directory on the main branch.
- **Process**:
    - Validates all API configurations and policies to ensure they are correct.
    - Executes a [custom script](https://github.com/caroltyk/tyk-sync-example/blob/main/.github/scripts/replace_target_host.sh) that replaces "TARGET_HOST" in upstream URL to a variable defined in GitHub for staging environment.
    - Syncs the validated API configurations (found in `apis`, `assets`, and `policies` folders) to the staging environment.
    - Reports linting and sync status through exit codes; any errors during sync will be flagged.
- **Outcome**: If successful, the API configurations are deployed to the staging environment for further testing. Any errors are reported, and the workflow fails, requiring attention.

## Promote API configurations to production

The [`tyk-production.yml`](https://github.com/caroltyk/tyk-sync-example/blob/main/.github/workflows/tyk-production.yml) workflow handles the promotion of API configurations from the staging environment to the production environment.

- **Trigger**: Manually triggered after confirming successful deployment and testing in the staging environment.
- **Process**:
    - Copies API configurations from the `staging` folder to the `production` folder.
    - Validates the copied API configurations to ensure they are correct.
    - Executes a [custom script](https://github.com/caroltyk/tyk-sync-example/blob/main/.github/scripts/replace_target_host.sh) that replaces "TARGET_HOST" in upstream URL to a variable defined in GitHub for production environment.
    - Syncs the validated API configurations to the Tyk Cloud production environment.
    - Reports the status of the sync process through exit codes; any errors will cause the workflow to fail.
- **Outcome**: Ensures that only thoroughly tested and validated APIs are promoted to production. If errors are found during the sync, they are reported, and the workflow is halted for correction.

## Contribution

We welcome contributions to enhance and improve this example repository! If you have suggestions, bug reports, or ideas for new features, please feel free to contribute by opening an issue or creating a PR.