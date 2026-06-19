# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal website for theatomicity.com. A MkDocs static site deployed to AWS via CloudFront + S3, with infrastructure defined in AWS CDK (TypeScript).

## Architecture

```
Route53 → CloudFront → OAC → Private S3 Bucket (eu-west-3)
                  ↑
            ACM Certificate (us-east-1, required for CloudFront)
                  ↑
            MkDocs build → S3 sync
```

- **Content**: `mkdocs-landing/` — MkDocs site using the `mkdocs-landing` theme. Edit `docs/` for content, `mkdocs.yml` for layout/theme config.
- **Infrastructure**: `infra/aws/cdk/` — single CDK stack (`TheAtomicityComStack`) deploying S3 + CloudFront + Route53. All values (domain, cert UUID, hosted zone ID, account ID) are passed as CDK context at deploy time, never hardcoded.
- **Pre-requisites**: `infra/aws/pre-requisites/iam.yml` — CloudFormation template for the GitHub Actions IAM role. Run once with `make prerequisites`.
- **Scaleway (partial)**: `infra/scaleway/terraform/` — alternative hosting via OpenTofu, not used in production.

## Commands

### Content (MkDocs)

```bash
# Build the static site locally (Docker)
make build_content

# Serve locally at http://localhost:8000 (Docker)
make run_content

# Or directly with Python (from mkdocs-landing/)
pip install -r requirements.txt
python -m mkdocs build
python -m mkdocs serve
```

### Infrastructure (CDK)

```bash
cd infra/aws/cdk
npm install
npm run build        # compile TypeScript
npm test             # run CDK snapshot/assertion tests (jest)
# Deploy (requires AWS credentials + context values)
cdk deploy --all --context Domain=theatomicity.com \
  --context AccountId=<id> \
  --context TlsCertificateUuid=<uuid> \
  --context HostedZoneID=<id>
```

### Pre-requisites (run once)

```bash
make prerequisites   # deploys IAM role for GitHub Actions via CloudFormation
```

## CI/CD

`.github/workflows/aws.yml` — manually triggered (`workflow_dispatch`). It:
1. Assumes the GitHub Actions IAM role via OIDC.
2. Runs `cdk deploy --all` with context from GitHub secrets.
3. Builds MkDocs and syncs `site/` to the S3 bucket.

Required GitHub secrets: `AWS_PROD_ACCOUNT_ID`, `AWS_HOSTED_ZONE_ID`, `TLS_CERTIFICATE_UUID`.

## CDK context values

The CDK stack requires four context keys at synth/deploy time and throws immediately if any is missing:

| Key | Description |
|---|---|
| `Domain` | Root domain (`theatomicity.com`) |
| `AccountId` | AWS account ID |
| `TlsCertificateUuid` | UUID portion of the ACM cert ARN (cert must be in `us-east-1`) |
| `HostedZoneID` | Route53 hosted zone ID |