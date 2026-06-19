# CDK Code Review 3 — `infra/aws/cdk`

**Date:** 2026-05-09  
**Scope:** `cdk/lib/cdk-stack.ts`, `cdk/bin/cdk.ts`, `cdk/test/cdk.test.ts`  
**Based on:** changes applied after code review 2

## What was fixed

| # | Item | Status |
|---|------|--------|
| 1 | Certificate SAN must cover both domains | ✅ Resolved (operational) |
| 2 | OAI → OAC (`S3BucketOrigin.withOriginAccessControl`) | ✅ Fixed |
| 3 | Misleading comment on `viewerProtocolPolicy` | ✅ Fixed |
| 4 | Unused `BucketPolicy` import | ✅ Fixed |
| 5 | Distribution logical ID → `website-distribution` | ✅ Fixed |
| 6 | Custom 403 → 404 error response | ✅ Fixed |
| 7 | Boilerplate comments in `bin/cdk.ts` | ✅ Fixed |

The stack is in good shape. Three minor items remain.

---

## 1. LOW — Generic class name `CdkStack`

**File:** `cdk/lib/cdk-stack.ts` line 18 / `cdk/bin/cdk.ts` line 3

`CdkStack` is the default scaffold name and carries no meaning. It makes `bin/cdk.ts` and any future stacks harder to read at a glance.

**Fix:**

`cdk/lib/cdk-stack.ts`:
```typescript
export class TheAtomicityComStack extends cdk.Stack {
```

`cdk/bin/cdk.ts`:
```typescript
import { TheAtomicityComStack } from '../lib/cdk-stack';

new TheAtomicityComStack(app, 'the-atomicity-com', {
    env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },
});
```

---

## 2. LOW — Redundant `enabled: true` on distribution

**File:** `cdk/lib/cdk-stack.ts` line 52

`enabled` defaults to `true` in CDK. Stating it explicitly adds noise without adding clarity.

**Current:**
```typescript
const distribution = new Distribution(this, 'website-distribution', {
    enabled: true,
    priceClass: PriceClass.PRICE_CLASS_100,
    ...
```

**Fix:**
```typescript
const distribution = new Distribution(this, 'website-distribution', {
    priceClass: PriceClass.PRICE_CLASS_100,
    ...
```

---

## 3. LOW — Test file has no coverage

**File:** `cdk/test/cdk.test.ts`

The only test is an empty placeholder (`test('SQS Queue Created', () => {})`) — it passes trivially and tests nothing. A synthesis test would catch broken context guards, missing resources, and misconfigured properties before deployment.

**Fix:**
```typescript
import * as cdk from 'aws-cdk-lib/core';
import { Template } from 'aws-cdk-lib/assertions';
import { TheAtomicityComStack } from '../lib/cdk-stack';

const testContext = {
    Domain: 'theatomicity.com',
    AccountId: '123456789012',
    TlsCertificateUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    HostedZoneID: 'ZXXXXXXXXXXXXX',
};

function buildTemplate() {
    const app = new cdk.App({ context: testContext });
    const stack = new TheAtomicityComStack(app, 'TestStack');
    return Template.fromStack(stack);
}

test('synthesizes one S3 bucket with public access blocked', () => {
    const template = buildTemplate();
    template.resourceCountIs('AWS::S3::Bucket', 1);
    template.hasResourceProperties('AWS::S3::Bucket', {
        PublicAccessBlockConfiguration: {
            BlockPublicAcls: true,
            BlockPublicPolicy: true,
            IgnorePublicAcls: true,
            RestrictPublicBuckets: true,
        },
    });
});

test('synthesizes one CloudFront distribution with HTTPS redirect', () => {
    const template = buildTemplate();
    template.resourceCountIs('AWS::CloudFront::Distribution', 1);
    template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
            DefaultCacheBehavior: {
                ViewerProtocolPolicy: 'redirect-to-https',
                Compress: true,
            },
        },
    });
});

test('synthesizes Route53 record set group with 4 records', () => {
    const template = buildTemplate();
    template.resourceCountIs('AWS::Route53::RecordSetGroup', 1);
    template.hasResourceProperties('AWS::Route53::RecordSetGroup', {
        RecordSets: cdk.assertions.Match.arrayWith([
            cdk.assertions.Match.objectLike({ Type: 'A',    Name: 'theatomicity.com' }),
            cdk.assertions.Match.objectLike({ Type: 'AAAA', Name: 'theatomicity.com' }),
            cdk.assertions.Match.objectLike({ Type: 'A',    Name: 'www.theatomicity.com' }),
            cdk.assertions.Match.objectLike({ Type: 'AAAA', Name: 'www.theatomicity.com' }),
        ]),
    });
});

test('throws when required context is missing', () => {
    const app = new cdk.App();
    expect(() => new TheAtomicityComStack(app, 'TestStack')).toThrow('Missing required CDK context value');
});
```

---

## Summary

| # | Severity | Issue |
|---|----------|-------|
| 1 | Low | Generic class name `CdkStack` |
| 2 | Low | Redundant `enabled: true` on distribution |
| 3 | Low | Test file has no real assertions |

The stack is otherwise clean and production-ready.
