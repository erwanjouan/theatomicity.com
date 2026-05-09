import * as cdk from 'aws-cdk-lib/core';
import { Template, Match } from 'aws-cdk-lib/assertions';
import {TheAtomicityComStack} from "../lib/the-atomicity-com-stack";

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
        RecordSets: Match.arrayWith([
            Match.objectLike({ Type: 'A',    Name: 'theatomicity.com' }),
            Match.objectLike({ Type: 'AAAA', Name: 'theatomicity.com' }),
            Match.objectLike({ Type: 'A',    Name: 'www.theatomicity.com' }),
            Match.objectLike({ Type: 'AAAA', Name: 'www.theatomicity.com' }),
        ]),
    });
});

test('throws when required context is missing', () => {
    const app = new cdk.App();
    expect(() => new TheAtomicityComStack(app, 'TestStack')).toThrow('Missing required CDK context value');
});