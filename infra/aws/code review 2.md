# CDK Code Review 2 — `infra/aws/cdk`

**Date:** 2026-05-09  
**Scope:** `cdk/lib/cdk-stack.ts`, `cdk/bin/cdk.ts`  
**Based on:** changes applied after code review 1

## What was fixed

| # | Item | Status |
|---|------|--------|
| 1 | `ViewerProtocolPolicy.REDIRECT_TO_HTTPS` | ✅ Fixed |
| 2 | Context value validation guards | ✅ Fixed |
| 3 | `BlockPublicAccess.BLOCK_ALL` on bucket | ✅ Fixed |
| 4 | Two distributions → one | ✅ Fixed (caused issue below) |
| 5 | `CF_HOSTED_ZONE_ID` constant | ✅ Fixed |
| 6 | Environment specified in `bin/cdk.ts` | ✅ Fixed |
| 7 | Resource tags | ✅ Fixed |
| 8 | Distribution ID output | ✅ Fixed |

---

## 1. CRITICAL — Certificate must cover both domain names (deployment blocker)

**File:** `cdk/lib/cdk-stack.ts` line 61

The distribution now declares `domainNames: [domain, subDomain]` (both `theatomicity.com` and `www.theatomicity.com`), but the certificate referenced by `TlsCertificateUuid` was originally provisioned for the apex domain only. CloudFront rejects any certificate that does not explicitly list every alternate domain name.

**Fix — provision a new ACM certificate with both SANs:**

```bash
# Step 1: request a new certificate covering both names
aws acm request-certificate \
  --domain-name theatomicity.com \
  --subject-alternative-names www.theatomicity.com \
  --validation-method DNS \
  --region us-east-1

# Step 2: ACM returns a new certificate ARN — complete DNS validation in Route53
# then wait until status is ISSUED:
aws acm describe-certificate \
  --certificate-arn <new-arn> \
  --region us-east-1 \
  --query 'Certificate.Status'

# Step 3: update your context source to point TlsCertificateUuid at the new UUID
# (extract the UUID from the ARN: arn:aws:acm:us-east-1:<account>:certificate/<UUID>)
```

Once the certificate is `ISSUED`, redeploy. The old two separate certificates (`TlsCertificateUuid` / `TlsCertificateUuidWWW`) can be deleted from ACM.

---

## 2. HIGH — `OriginAccessIdentity` is deprecated, use `OriginAccessControl`

**File:** `cdk/lib/cdk-stack.ts` lines 8, 49–55

`OriginAccessIdentity` (OAI) was superseded by `OriginAccessControl` (OAC) in 2022. OAC uses AWS SigV4 request signing, supports SSE-KMS encrypted buckets, and is the current AWS recommendation.

**Current code:**
```typescript
import { ..., OriginAccessIdentity, ... } from "aws-cdk-lib/aws-cloudfront";

const domainOai = new OriginAccessIdentity(this, 'domainOAI', {
    comment: 'Domain OAI'
});
const s3Origin = S3BucketOrigin.withOriginAccessIdentity(bucket, {
    originAccessIdentity: domainOai
});
```

**Fix:**
```typescript
// Remove OriginAccessIdentity from import — no longer needed
import { AllowedMethods, Distribution, PriceClass, ViewerProtocolPolicy } from "aws-cdk-lib/aws-cloudfront";

// S3BucketOrigin.withOriginAccessControl() is the default — no extra construct needed
const s3Origin = S3BucketOrigin.withOriginAccessControl(bucket);
```

CDK automatically creates an OAC and updates the bucket policy. The explicit `OriginAccessIdentity` construct and its `comment` property are removed entirely.

---

## 3. MEDIUM — Misleading comment on `viewerProtocolPolicy`

**File:** `cdk/lib/cdk-stack.ts` line 66

```typescript
viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS, // unless visitors can access the site over unencrypted HTTP despite having valid certificates
```

The comment reads as a conditional ("unless X") but the setting is unconditional. It is also double-negative in meaning.

**Fix:**
```typescript
viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
```

No comment needed — the enum value is self-documenting.

---

## 4. LOW — Unused import: `BucketPolicy`

**File:** `cdk/lib/cdk-stack.ts` line 4

`BucketPolicy` is imported but never referenced.

**Current:**
```typescript
import {BlockPublicAccess, Bucket, BucketEncryption, BucketPolicy} from "aws-cdk-lib/aws-s3";
```

**Fix:**
```typescript
import {BlockPublicAccess, Bucket, BucketEncryption} from "aws-cdk-lib/aws-s3";
```

---

## 5. LOW — Distribution logical ID is misleading

**File:** `cdk/lib/cdk-stack.ts` line 57

```typescript
const distribution = new Distribution(this, 'domain-distribution', { ... })
```

The distribution now serves both the apex domain and the www subdomain, but its CloudFormation logical ID (`domain-distribution`) still implies it only covers the apex domain.

**Fix:**
```typescript
const distribution = new Distribution(this, 'website-distribution', { ... })
```

Note: changing a logical ID replaces the CloudFront resource in CloudFormation (delete + create), so apply during a planned deployment, not a hotfix.

---

## 6. LOW — No custom error response for missing S3 objects

**File:** `cdk/lib/cdk-stack.ts`, `Distribution` config

When a visitor requests a path that does not exist in S3, CloudFront receives a 403 (S3 returns 403 for missing objects under OAI/OAC, not 404). Without a custom error response, CloudFront serves its own generic XML error page.

**Fix — return a proper 404 page:**
```typescript
const distribution = new Distribution(this, 'website-distribution', {
    // ... existing config
    errorResponses: [
        {
            httpStatus: 403,
            responseHttpStatus: 404,
            responsePagePath: '/404.html',
            ttl: cdk.Duration.seconds(10),
        },
    ],
})
```

Replace `/404.html` with whatever mkdocs generates for missing pages.

---

## 7. LOW — Boilerplate comments in `bin/cdk.ts`

**File:** `cdk/bin/cdk.ts` lines 7–11, 17–20

Now that `env` is set, the surrounding CDK boilerplate comments serve no purpose.

**Current:**
```typescript
new CdkStack(app, 'the-atomicity-com', {

    /* If you don't specify 'env', this stack will be environment-agnostic.
     * Account/Region-dependent features and context lookups will not work,
     * but a single synthesized template can be deployed anywhere. */

    /* Uncomment the next line to specialize this stack for the AWS Account
     * and Region that are implied by the current CLI configuration. */
    env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },

    /* Uncomment the next line if you know exactly what Account and Region you
     * want to deploy the stack to. */
    // env: { account: '123456789012', region: 'us-east-1' },

    /* For more information, see https://docs.aws.amazon.com/cdk/latest/guide/environments.html */
});
```

**Fix:**
```typescript
new CdkStack(app, 'the-atomicity-com', {
    env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },
});
```

---

## Summary

| # | Severity | Issue |
|---|----------|-------|
| 1 | Critical | Certificate SAN must cover both `theatomicity.com` and `www.theatomicity.com` |
| 2 | High | OAI deprecated — migrate to OAC (`S3BucketOrigin.withOriginAccessControl`) |
| 3 | Medium | Misleading double-negative comment on `viewerProtocolPolicy` |
| 4 | Low | Unused `BucketPolicy` import |
| 5 | Low | Distribution logical ID `domain-distribution` still implies apex-only |
| 6 | Low | No custom error response — S3 403s surface as CloudFront XML errors |
| 7 | Low | Stale boilerplate comments in `bin/cdk.ts` |
