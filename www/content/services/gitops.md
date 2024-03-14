---
title: 'GitOps'
date: 2018-11-18T12:33:46+10:00
icon: 'services/service-icon-1.png'
draft: false
featured: true
weight: 1
heroHeading: 'GitOps'
heroSubHeading: 'Enhance deployment history by using Git as the single source of truth'
heroBackground: 'services/service1.jpg'
---

Development best practices such as code review and version control has traditionally been performed on source code in software industry. GitOps framework aims to extend these concepts to the code dedicated to provisioning of infrastructure resources.

## GitOps = IaC + MRs + CI/CD

GitOps is a methodology firstly introduced by WeaveWork that combines the benefit of Infrastructure as Code (Iac), Merge Requests from Git (or MRs as labeled in most Git providers) and Continuous Integration / Continuous Deployment pipelines.

In this methodology, the Git repository is the unique source of truth for configuration changes tracking. When a code change is approved by a peer, the Merge Request gets validated and then deployment pipeline is triggered to the appropriate environment.
