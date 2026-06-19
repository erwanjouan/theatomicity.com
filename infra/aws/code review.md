# CDK Code Review — `infra/aws/cdk`

**Date:** 2026-05-09  
**Scope:** `cdk/lib/cdk-stack.ts`, `cdk/bin/cdk.ts`

The stack deploys a static website for `theatomicity.com`: S3 bucket, two CloudFront distributions, ACM certificates, and Route53 record sets.

---

## 1. CRITICAL — HTTP traffic allowed (no HTTPS redirect)

**File:** `cdk/lib/cdk-stack.ts` lines 49–53, 62–66

Neither distribution specifies a `viewerProtocolPolicy`, so CDK defaults to `allow-all`, meaning visitors can access the site over unencrypted HTTP despite having valid certificates.

**Current code:**
```typescript
defaultBehavior: {
    origin: s3Origin,
    allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
    compress: true,
    // viewerProtocolPolicy not set → defaults to allow-all
}
```

**Fix:**
```typescript
import { AllowedMethods, Distribution, OriginAccessIdentity, PriceClass, ViewerProtocolPolicy } from "aws-cdk-lib/aws-cloudfront";

// Apply to BOTH distributions:
defaultBehavior: {
    origin: s3Origin,
    allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
    compress: true,
    viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
}
```

---

## 2. HIGH — No context value validation

**File:** `cdk/lib/cdk-stack.ts` lines 15–20

`tryGetContext()` returns `undefined` silently when a key is missing. This produces an ARN like `arn:aws:acm:us-east-1:undefined:certificate/undefined` (lines 29–30), which only fails at CloudFront deployment time with a cryptic error.

**Current code:**
```typescript
const domain:string = this.node.tryGetContext('Domain');
const accountId = this.node.tryGetContext('AccountId');
const domainCertificateUuid:string = this.node.tryGetContext('TlsCertificateUuid');
const subDomainCertificateUuid = this.node.tryGetContext('TlsCertificateUuidWWW');
const hostedZoneID:string = this.node.tryGetContext('HostedZoneID');
```

**Fix — add guards immediately after context reads:**
```typescript
const domain: string = this.node.tryGetContext('Domain');
const accountId: string = this.node.tryGetContext('AccountId');
const domainCertificateUuid: string = this.node.tryGetContext('TlsCertificateUuid');
const subDomainCertificateUuid: string = this.node.tryGetContext('TlsCertificateUuidWWW');
const hostedZoneID: string = this.node.tryGetContext('HostedZoneID');

for (const [key, val] of Object.entries({ Domain: domain, AccountId: accountId, TlsCertificateUuid: domainCertificateUuid, TlsCertificateUuidWWW: subDomainCertificateUuid, HostedZoneID: hostedZoneID })) {
    if (!val) throw new Error(`Missing required CDK context value: ${key}`);
}
```

---

## 3. HIGH — Missing BlockPublicAccess on S3 bucket

**File:** `cdk/lib/cdk-stack.ts` lines 22–27

The OAI restricts access correctly, but without explicit `BlockPublicAccess`, a misconfigured bucket policy could accidentally expose objects.

**Current code:**
```typescript
const bucket = new Bucket(this, domain, {
    bucketName: domain,
    encryption: BucketEncryption.S3_MANAGED,
    removalPolicy: RemovalPolicy.DESTROY,
    autoDeleteObjects: true,
})
```

**Fix:**
```typescript
import { Bucket, BucketAccessControl, BucketEncryption, BlockPublicAccess } from "aws-cdk-lib/aws-s3";

const bucket = new Bucket(this, domain, {
    bucketName: domain,
    encryption: BucketEncryption.S3_MANAGED,
    removalPolicy: RemovalPolicy.DESTROY,
    autoDeleteObjects: true,
    blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
    publicReadAccess: false,
})
```

Note: `cdk.json` already has `"@aws-cdk/aws-s3:publicAccessBlockedByDefault": true` (line 98), which applies the CDK-level default, but an explicit declaration is clearer and more resilient.

---

## 4. MEDIUM — Two CloudFront distributions for apex + www

**File:** `cdk/lib/cdk-stack.ts` lines 43–67

A separate distribution is created for `www.theatomicity.com` despite sharing the same S3 origin. This doubles CloudFront cost, doubles cache invalidation scope, and uses two certificates unnecessarily.

**Current code:**
```typescript
const domainDistribution = new Distribution(this, 'domain-distribution', {
    certificate: domainCert,
    domainNames: [domain],
    // ...
})

const subDomainDistribution = new Distribution(this, 'subdomain-distribution', {
    certificate: subDomainCert,
    domainNames: [subDomain],
    // ...
})
```

**Fix — one distribution, one certificate covering both names:**

The single ACM certificate must cover both `theatomicity.com` and `www.theatomicity.com` (use a wildcard or a SAN cert). Then:

```typescript
// Only one certificate needed — import once
const cert = Certificate.fromCertificateArn(this, 'cert', domainCertificateArn);

const distribution = new Distribution(this, 'distribution', {
    enabled: true,
    priceClass: PriceClass.PRICE_CLASS_100,
    certificate: cert,
    domainNames: [domain, subDomain],
    defaultRootObject: 'index.html',
    defaultBehavior: {
        origin: s3Origin,
        allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
        compress: true,
        viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    }
})
```

And collapse the four Route53 records to two (A + AAAA both pointing to the single distribution):

```typescript
const CF_HOSTED_ZONE_ID = 'Z2FDTNDATAQYW2';

new CfnRecordSetGroup(this, 'route53-recordset-group', {
    hostedZoneId: hostedZoneID,
    recordSets: [domain, subDomain].flatMap(name => [
        {
            name,
            type: 'A',
            aliasTarget: { hostedZoneId: CF_HOSTED_ZONE_ID, dnsName: distribution.domainName }
        },
        {
            name,
            type: 'AAAA',
            aliasTarget: { hostedZoneId: CF_HOSTED_ZONE_ID, dnsName: distribution.domainName }
        },
    ])
})
```

---

## 5. MEDIUM — Magic string `Z2FDTNDATAQYW2` repeated four times

**File:** `cdk/lib/cdk-stack.ts` lines 76, 84, 92, 100

The CloudFront alias hosted zone ID is hardcoded inline on every record set entry.

**Fix — extract to a named constant (shown in the fix above):**
```typescript
const CF_HOSTED_ZONE_ID = 'Z2FDTNDATAQYW2'; // CloudFront global hosted zone ID
```

---

## 6. LOW — Stack is environment-agnostic

**File:** `cdk/bin/cdk.ts` lines 12–17

The `env` property is commented out, making the stack environment-agnostic. This is intentional per the CDK comments, but means context lookups and cross-account guard rails are disabled.

**Current code:**
```typescript
new CdkStack(app, 'the-atomicity-com', {
  // env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION },
});
```

**Fix (recommended for production):**
```typescript
new CdkStack(app, 'the-atomicity-com', {
    env: {
        account: process.env.CDK_DEFAULT_ACCOUNT,
        region: process.env.CDK_DEFAULT_REGION,
    },
});
```

---

## 7. LOW — No resource tags

**File:** `cdk/lib/cdk-stack.ts`

No tags are applied to any resource, making cost allocation and filtering in the AWS console harder.

**Fix — add at the end of the constructor:**
```typescript
cdk.Tags.of(this).add('Project', 'theatomicity-com');
cdk.Tags.of(this).add('ManagedBy', 'CDK');
```

---

## 8. LOW — Missing CloudFront distribution ID outputs

**File:** `cdk/lib/cdk-stack.ts` lines 107–111

Only the bucket name is exported. Cache invalidation scripts (`aws cloudfront create-invalidation`) need the distribution ID.

**Fix:**
```typescript
new CfnOutput(this, 'distributionId', {
    value: distribution.distributionId,
    description: 'CloudFront distribution ID',
    exportName: 'DistributionId',
})
```

---

## 9. LOW — Tests commented out

**File:** `cdk/test/cdk.test.ts`

The test file has no active assertions.

**Fix — minimum snapshot test:**
```typescript
import * as cdk from 'aws-cdk-lib';
import { Template } from 'aws-cdk-lib/assertions';
import { CdkStack } from '../lib/cdk-stack';

test('stack synthesizes expected resources', () => {
    const app = new cdk.App({
        context: {
            Domain: 'theatomicity.com',
            AccountId: '123456789012',
            TlsCertificateUuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
            TlsCertificateUuidWWW: 'ffffffff-0000-1111-2222-333333333333',
            HostedZoneID: 'ZXXXXXXXXXXXXX',
        }
    });
    const stack = new CdkStack(app, 'TestStack');
    const template = Template.fromStack(stack);

    template.resourceCountIs('AWS::S3::Bucket', 1);
    template.resourceCountIs('AWS::CloudFront::Distribution', 1);
    template.resourceCountIs('AWS::Route53::RecordSetGroup', 1);
});
```

---

## Summary

| # | Severity | Issue |
|---|----------|-------|
| 1 | Critical | No HTTPS redirect — `viewerProtocolPolicy` unset |
| 2 | High | No context value guards — silent `undefined` in ARNs |
| 3 | High | Missing `BlockPublicAccess` on S3 bucket |
| 4 | Medium | Two redundant CloudFront distributions |
| 5 | Medium | `Z2FDTNDATAQYW2` magic string repeated 4× |
| 6 | Low | Stack environment-agnostic (env commented out) |
| 7 | Low | No resource tags |
| 8 | Low | Missing distribution ID stack output |
| 9 | Low | Tests commented out / no coverage |
