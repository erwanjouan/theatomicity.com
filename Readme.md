# theatomicity.com

## AWS

### Preréquisite

- Public Hosted zone with registered domain
- 1 Tls Certificates in ACM
  - domain : theatomicity.com
  - alternate domain: www.theatomicity.com
- GitHub actions role
```
make prerequisites
```

### Architecture

```mermaid
    graph LR
        Route53(Route53\nRecordSet\nGroup\ntheatomicity.com\n--Global--) --> CloudFront(CloudFront\nDistribution\ntheatomicity.com\n--Global--)
        CloudFront --> ACM(ACM\nCertificate\ntheatomicity.com\n--us-east-1--)
        CloudFront --> OAC(Origin Access control\n--Global--)
        OAC --> S3(Private\nS3\nBucket\n--eu-west-1--)
        MkDocs(MkDocs\nStatic\npages) --> S3
```

