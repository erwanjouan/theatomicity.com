import * as cdk from 'aws-cdk-lib/core';
import {CfnOutput, RemovalPolicy} from 'aws-cdk-lib/core';
import {Construct} from 'constructs';
import {Bucket, BucketEncryption, BucketPolicy} from "aws-cdk-lib/aws-s3";
import {PolicyDocument, PolicyStatement} from "aws-cdk-lib/aws-iam";
import {AllowedMethods, Distribution, OriginAccessIdentity, PriceClass} from "aws-cdk-lib/aws-cloudfront";
import {Certificate} from "aws-cdk-lib/aws-certificatemanager";
import {S3BucketOrigin} from "aws-cdk-lib/aws-cloudfront-origins";
import {CfnRecordSetGroup} from "aws-cdk-lib/aws-route53";

export class CdkStack extends cdk.Stack {

    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        const domain:string = this.node.tryGetContext('Domain');
        const accountId:number = this.node.tryGetContext('AccountId');
        const domainCertificateUuid:string = this.node.tryGetContext('TlsCertificateUuid');
        const subDomainCertificateUuid = this.node.tryGetContext('TlsCertificateUuidWWW');
        const hostedZoneID:string = this.node.tryGetContext('HostedZoneID');

        const bucket = new Bucket(this, domain, {
            bucketName: domain,
            encryption: BucketEncryption.S3_MANAGED,
            removalPolicy: RemovalPolicy.DESTROY,
            autoDeleteObjects: true,
        })

        const domainCertificateArn = `arn:aws:acm:us-east-1:${accountId}:certificate/${domainCertificateUuid}`

        const domainCert = Certificate.fromCertificateArn(this, 'domainCert', domainCertificateArn);

        const domainOai = new OriginAccessIdentity(this, 'domainOAI', {
            comment: 'Domain OAI'
        });

        const s3Origin = S3BucketOrigin.withOriginAccessIdentity(bucket, {
            originAccessIdentity: domainOai
        });

        const domainDistribution = new Distribution(this, 'domain-distribution', {
            enabled: true,
            priceClass: PriceClass.PRICE_CLASS_100,
            certificate: domainCert,
            domainNames: [domain],
            defaultRootObject: 'index.html',
            defaultBehavior: {
                origin: s3Origin,
                allowedMethods: AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
                compress: true,
            }
        })

        new CfnRecordSetGroup(this, "route53-recordset-group",{
            hostedZoneId: hostedZoneID,
            recordSets: [
                {
                    name: domain,
                    type: 'A',
                    aliasTarget: {
                        hostedZoneId: 'Z2FDTNDATAQYW2', // https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordsetgroup-aliastarget.html#cfn-route53-recordsetgroup-aliastarget-hostedzoneid
                        dnsName: domainDistribution.domainName
                    }
                },
                {
                    name: domain,
                    type: 'AAAA',
                    aliasTarget: {
                        hostedZoneId: 'Z2FDTNDATAQYW2', // https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordsetgroup-aliastarget.html#cfn-route53-recordsetgroup-aliastarget-hostedzoneid
                        dnsName: domainDistribution.domainName
                    }
                },
            ]
        })

        new CfnOutput(this, 'bucket', {
            value: bucket.bucketName,
            description: 'Bucket',
            exportName: 'Bucket',
        })

    }
}
