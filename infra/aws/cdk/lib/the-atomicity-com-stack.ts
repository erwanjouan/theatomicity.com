import * as cdk from 'aws-cdk-lib/core';
import {CfnOutput, RemovalPolicy} from 'aws-cdk-lib/core';
import {Construct} from 'constructs';
import {BlockPublicAccess, Bucket, BucketEncryption} from "aws-cdk-lib/aws-s3";
import {
    AllowedMethods,
    Distribution,
    PriceClass,
    ViewerProtocolPolicy
} from "aws-cdk-lib/aws-cloudfront";
import {Certificate} from "aws-cdk-lib/aws-certificatemanager";
import {S3BucketOrigin} from "aws-cdk-lib/aws-cloudfront-origins";
import {CfnRecordSetGroup} from "aws-cdk-lib/aws-route53";

// https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordsetgroup-aliastarget.html#cfn-route53-recordsetgroup-aliastarget-hostedzoneid
const CF_HOSTED_ZONE_ID: string = 'Z2FDTNDATAQYW2';

export class TheAtomicityComStack extends cdk.Stack {

    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        const domain: string = this.node.tryGetContext('Domain');
        const subDomain: string = `www.${domain}`;
        const accountId: string = this.node.tryGetContext('AccountId');
        const domainCertificateUuid: string = this.node.tryGetContext('TlsCertificateUuid');
        const hostedZoneID: string = this.node.tryGetContext('HostedZoneID');

        // check context presence
        for (const [key, val] of Object.entries({
            Domain: domain,
            AccountId: accountId,
            TlsCertificateUuid: domainCertificateUuid,
            HostedZoneID: hostedZoneID
        })) {
            if (!val) throw new Error(`Missing required CDK context value: ${key}`);
        }

        const bucket = new Bucket(this, domain, {
            bucketName: domain,
            encryption: BucketEncryption.S3_MANAGED,
            removalPolicy: RemovalPolicy.DESTROY,
            autoDeleteObjects: true,
            blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
        })

        const domainCertificateArn = `arn:aws:acm:us-east-1:${accountId}:certificate/${domainCertificateUuid}`
        const domainCert = Certificate.fromCertificateArn(this, 'domainCert', domainCertificateArn);
        const s3Origin = S3BucketOrigin.withOriginAccessControl(bucket);

        const distribution = new Distribution(this, 'website-distribution', {
            priceClass: PriceClass.PRICE_CLASS_100,
            certificate: domainCert,
            domainNames: [domain, subDomain],
            defaultRootObject: 'index.html',
            defaultBehavior: {
                origin: s3Origin,
                allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
                viewerProtocolPolicy: ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                compress: true,
            },
            errorResponses: [
                {
                    httpStatus: 403,
                    responseHttpStatus: 404,
                    responsePagePath: '/404/index.html',
                    ttl: cdk.Duration.seconds(10),
                },
            ],
        })

        new CfnRecordSetGroup(this, "route53-recordset-group", {
            hostedZoneId: hostedZoneID,
            recordSets: [domain, subDomain].flatMap(name => {
                return [
                    {
                        name,
                        type: 'A',
                        aliasTarget: {
                            hostedZoneId: CF_HOSTED_ZONE_ID,
                            dnsName: distribution.domainName
                        }
                    },
                    {
                        name,
                        type: 'AAAA',
                        aliasTarget: {
                            hostedZoneId: CF_HOSTED_ZONE_ID,
                            dnsName: distribution.domainName
                        }
                    },
                ];
            })
        })

        new CfnOutput(this, 'bucket', {
            value: bucket.bucketName,
            description: 'Bucket',
            exportName: 'Bucket',
        })

        new CfnOutput(this, 'distributionId', {
            value: distribution.distributionId,
            description: 'CloudFront distribution ID',
            exportName: 'DistributionId',
        })

        cdk.Tags.of(this).add('Project', 'the-atomicity-com');
        cdk.Tags.of(this).add('ManagedBy', 'CDK');

    }
}
