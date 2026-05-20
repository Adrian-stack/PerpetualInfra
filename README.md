# Perpetual Share — Terraform + Terragrunt Infrastructure

Region: **eu-central-1** (Frankfurt). All environments target AWS Free Tier for months 1–12.

## Repository layout

```
infra/
├── .terraform-version          ← Terraform version pin (1.9.x)
├── modules/                    ← Pure Terraform modules (no Terragrunt)
│   ├── bootstrap/              ← Run once: creates S3 state bucket + DynamoDB lock
│   ├── networking/             ← VPC, public subnet, IGW, security group
│   ├── storage/                ← S3 uploads bucket, versioning, lifecycle, CORS
│   ├── storage-policy/         ← S3 OAC bucket policy (prod only, applied after CDN)
│   ├── compute/                ← EC2 t3.micro, EIP, EBS 8 GB gp3, IAM role
│   ├── cdn/                    ← CloudFront + ACM (us-east-1) + Route 53 alias records
│   ├── dns/                    ← Route 53 hosted zone only
│   └── observability/          ← CloudWatch log group, CPU alarm, monthly budget
└── live/
    ├── terragrunt.hcl          ← Root: generates backend.tf, providers.tf, versions.tf per component
    ├── _envcommon/             ← Shared component config (source + dependency wiring)
    │   ├── networking.hcl
    │   ├── storage.hcl
    │   ├── compute.hcl
    │   ├── dns.hcl
    │   ├── cdn.hcl
    │   └── observability.hcl
    ├── prod/
    │   ├── env.hcl             ← Prod env vars (region, domain, budget, email)
    │   ├── networking/
    │   ├── storage/
    │   ├── compute/
    │   ├── dns/
    │   ├── cdn/
    │   ├── storage-policy/     ← Prod-only: wires CDN ARN into S3 bucket policy
    │   └── observability/
    └── qa/
        ├── env.hcl             ← QA env vars (no domain_name — EC2 IP only)
        ├── networking/
        ├── storage/
        ├── compute/
        └── observability/
```

## Component dependency graph

```
(prod)                               (qa)
networking ──┐                       networking ──┐
             ├──► compute ──► observability       ├──► compute ──► observability
storage ─────┤                       storage ─────┘
             └──► cdn ──┐
dns ──────────────────┘ │
                        └──► storage-policy
```

State per component lives at:
`s3://perpetual-share-tfstate/{env}/{component}/terraform.tfstate`

---

## Prerequisites

- [Terraform >= 1.9](https://developer.hashicorp.com/terraform/install)
- [Terragrunt >= 0.55](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- AWS CLI configured with credentials that have AdministratorAccess
- A domain you control (for prod)

---

## Step 0 — Bootstrap the state backend (run once, Terraform only)

Creates the S3 state bucket and DynamoDB lock table with **local** state.
```bash
cd infra/modules/bootstrap
terraform init
terraform apply \
  -var="state_bucket_name=perpetual-share-tfstate" \
  -var="aws_region=eu-central-1"
```

---

## Step 1 — Apply QA

```bash
cd infra/live/qa

# Initialise all components
terragrunt run-all init

# Preview
terragrunt run-all plan

# Apply in dependency order automatically
terragrunt run-all apply
```

After apply, the QA app is reachable at the Elastic IP:
```bash
cd infra/live/qa/compute
terragrunt output public_ip
```

---

## Step 2 — Apply Prod (full stack with HTTPS)

```bash
cd infra/live/prod
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

`run-all apply` applies components in dependency order:
1. `networking`, `storage`, `dns` — parallel (no deps between them)
2. `compute`, `cdn` — parallel (both depend on step 1)
3. `observability`, `storage-policy` — parallel (both depend on step 2)

After apply:
- Copy the Route 53 name servers to your domain registrar:
  ```bash
  cd infra/live/prod/dns
  terragrunt output name_servers
  ```
- CloudFront deployment takes 10–20 min on first apply.

---

## Step 3 — First app deploy

```bash
# Authenticate to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com

# Build and push
docker build -t perpetual-share .
docker tag perpetual-share:latest <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/perpetual-share:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/perpetual-share:latest

# Deploy via SSM (no SSH needed)
INSTANCE_ID=$(cd infra/live/prod/compute && terragrunt output -raw instance_id)
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["cd /opt/perpetual-share && docker compose pull && docker compose up -d"]' \
  --region eu-central-1
```

---

## Day-to-day operations

### Single-component apply
```bash
# Only re-plan/apply one component
cd infra/live/prod/compute
terragrunt plan
terragrunt apply
```

### SSM shell access (no SSH key needed)
```bash
INSTANCE_ID=$(cd infra/live/prod/compute && terragrunt output -raw instance_id)
aws ssm start-session --target "$INSTANCE_ID" --region eu-central-1
```

### Tail application logs
```bash
aws logs tail /perpetual-share/prod/app --follow --region eu-central-1
```

### View dependency graph
```bash
cd infra/live/prod
terragrunt graph-dependencies
```

### Destroy QA (never destroy prod without explicit intent)
```bash
cd infra/live/qa
terragrunt run-all destroy
```

---

## Cost guardrails

| Environment | Free Tier year 1 monthly cost |
|-------------|-------------------------------|
| prod        | ~$0.50 (Route 53 zone only)   |
| qa          | $0 (EC2 + EBS within limits)  |

Budget alarms fire to `adimoldovan28@gmail.com` at 80% and 100% of cap ($10 prod / $5 qa).
After Free Tier (month 13+): ~$10/month prod steady-state. See `docs/aws-terraform-budget-plan.md`.

---

## Changing the domain name

Edit `infra/live/prod/env.hcl`:
```hcl
locals {
  domain_name = "your-new-domain.com"
}
```
Then `cd infra/live/prod && terragrunt run-all apply`.
