#!/opt/homebrew/opt/node/bin/node
import * as cdk from 'aws-cdk-lib/core';
import {TheAtomicityComStack} from '../lib/the-atomicity-com-stack';

const app = new cdk.App();
new TheAtomicityComStack(app, 'the-atomicity-com', {
    env: {account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION},
});
