# ECS Demo App

## ⚠️ GLIBC Compatibility Issue

The base image provided by `emijivoto` has a known dependency issue related to GLIBC versions. When deploying the microservices (MS) images to ECS, you might encounter errors such as:

```bash
emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.32' not found (required by emojivoto-vote-bot)

emojivoto-vote-bot: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.34' not found (required by emojivoto-vote-bot)
```

## Workaround

To gracefully avoid these errors, use the already built images:

```bash
docker pull docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12

docker pull docker.l5d.io/buoyantio/emojivoto-voting-svc:v12

docker pull docker.l5d.io/buoyantio/emojivoto-web:v12
```

### Tag the images to fit repository naming:

```bash
docker tag docker.l5d.io/buoyantio/emojivoto-emoji-svc:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ emoji-svc:latest

docker tag docker.l5d.io/buoyantio/emojivoto-voting-svc:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ voting-svc:latest

docker tag docker.l5d.io/buoyantio/emojivoto-web:v12 <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ web:latest
```

### Push to ECR repository:

```bash
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ emoji-svc:latest

docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ voting-svc:latest

docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/ web:latest
```

After pushing images to your ECR, proceed with your deployment pipeline to ECS.