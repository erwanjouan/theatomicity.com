# Scaleway 

- Deployment can be triggered from Makefile
- Needs a ```scw.env``` file to work, that contains Scaleway api keys
```
SCW_ACCESS_KEY=SCWXYYYYYYYYYYY
SCW_SECRET_KEY=AAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEE
```

## Resources

### Terraform

https://www.scaleway.com/en/blog/terraform-how-to-init-your-infrastructure/
https://oneuptime.com/blog/post/2026-02-23-how-to-run-terraform-in-a-docker-container/view
https://datatask.io/blog/scaleway-terraform

### S3 Backend

https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/guides/backend_guide/
https://stackoverflow.com/questions/68680341/using-variables-in-terraform-backend-s3