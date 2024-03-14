# Host a static website on a S3 bucket

ideas from:

https://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html

https://github.com/rust-embedded/rust-embedded-provisioning/blob/master/route53.tf
https://github.com/lebinh/tracemap/blob/master/site.tf

HTTPS

https://medium.com/devopslinks/how-to-host-your-static-website-with-s3-cloudfront-and-set-up-an-ssl-certificate-9ee48cd701f9

## Lambda@Edge

Lamba@Edge log groups are in the closest region next to the Edge location (here London).

https://medium.com/@mnylen/lambda-edge-gotchas-and-tips-93083f8b4152

The Lambda has the following roles:
- Translates uri ending with "(...)/" to "(...)/index.html", because CloudFront can only fallback to index.html for the root directory. A fallback solution would be to enable static web hosting on S3, disabling Origin Access Identity, and create a custom origin on CloudFront.
- Intercepts any request to private/ subfolder and checks if the Authorization header contains a base64 signature of (user + password).
 
## Origin access identity

OAI cannot only be associated with a pure S3 origin (no static web hosting needs to be enabled)

To handle the non-www domain (www), which is a custom origin, a solution based on dynamic block is proposed by CloudPosse:
 https://github.com/cloudposse/terraform-aws-cloudfront-s3-cdn

## Authentication

Use Google Sign-in to generate a JWT instead of hardcoding user/password in the lambda@edge code.
See:
https://github.com/widen/cloudfront-auth

https://console.developers.google.com/apis/credentials

Adding Google authentication to S3 static web site with Lambda@Edge

### OAuth 2.0, OpenID Connect
https://blog.octo.com/en/authorisation-for-aws-s3-static-website/

https://developers.google.com/identity/protocols/oauth2