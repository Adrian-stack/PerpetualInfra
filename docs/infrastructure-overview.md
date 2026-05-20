# Perpetual Share — Infrastructure Overview

## Philosophy

The infrastructure is designed around a single principle: **keep every dollar intentional**. The app is a photo-sharing platform for events, not a globally distributed SaaS — so the architecture matches that reality.

- One small EC2 instance runs the full Express app inside Docker.
- S3 stores all photos; CloudFront serves them. The EC2 instance never touches photo bytes on the way out.
- SQLite on an attached EBS volume handles the database — no managed database needed at this scale.
- No NAT Gateway ($32/month), no Application Load Balancer ($16/month), no RDS, no Fargate.

---

## Architecture Diagram

```
                          Route 53
                    perpetualshare.com
                           │
                           ▼
                    CloudFront CDN
                  (Price Class 100 — EU/US)
                           │
          ┌────────────────┴─────────────────┐
          │ /uploads/* /assets/*             │ everything else
          ▼                                  ▼
   S3 Bucket                          EC2 t3.micro
   perpetual-share-prod-uploads       (public subnet, no NAT)
   ├── lifecycle: IA after 30d        ├── Docker → Express app
   ├── lifecycle: Glacier after 180d  ├── SQLite on EBS 8 GB gp3
   └── OAC policy (CDN-only access)   └── Elastic IP (free while attached)
                                            │
                                     SSM Parameter Store
                                     /perpetual-share/{env}/admin-password
```

---

## AWS Services Used

| Service | Purpose | Free Tier |
|---|---|---|
| **EC2 t3.micro** | Runs the Express app in Docker | 750 h/month free × 12 months |
| **EBS gp3 8 GB** | SQLite database storage on the instance | 30 GB free × 12 months |
| **Elastic IP** | Static public IP for the EC2 instance | Free while attached to a running instance |
| **S3 Standard** | Photo and asset storage | 5 GB + 20k GET + 2k PUT free × 12 months |
| **CloudFront** | CDN — serves photos and static assets | 1 TB egress + 10M requests always free |
| **ACM** | TLS certificate for the CloudFront domain | Always free (only valid on CloudFront/ALB) |
| **Route 53** | DNS hosted zone + domain registration | $0.50/month per zone; domain ~$12–15/year |
| **SSM Parameter Store** | Stores `ADMIN_PASSWORD` and secrets | Always free (Standard tier) |
| **ECR** | Docker image registry | 500 MB free × 12 months (~250 MB per image) |
| **CloudWatch Logs** | Application log ingestion and storage | 5 GB ingest + 5 GB stored free |
| **CloudWatch Alarms** | CPU > 80% alert | 10 alarms free |
| **AWS Budgets** | Monthly cost alerts at 80% and 100% | 2 budgets free |

---

## Environments

| Environment | Components | Access |
|---|---|---|
| **prod** | networking + storage + compute + dns + cdn + storage-policy + observability | `https://perpetualshare.com` via CloudFront |
| **qa** | networking + storage + compute + observability | `http://<elastic-ip>` directly |

QA has no CloudFront or domain — it is for testing the app before shipping to prod. HTTP only, accessed via the EC2 Elastic IP.

---

## Cost

### Free Tier year — months 1–12

| Line item | Usage assumption | Monthly cost |
|---|---|---|
| EC2 t3.micro | 730 h | **$0** (750 h free) |
| EBS gp3 8 GB | 8 GB | **$0** (30 GB free) |
| S3 Standard | < 5 GB photos | **$0** (5 GB free) |
| CloudFront | < 1 TB egress | **$0** (1 TB always free) |
| Data transfer EC2 → CloudFront | any amount | **$0** (free since Aug 2024) |
| Route 53 hosted zone | 1 zone | **$0.50** |
| ACM, SSM, ECR (< 500 MB), CloudWatch basics | — | **$0** |
| Domain registration | one-time ~$13/year (.com) | **~$1.08/month amortised** |
| **Total** | | **~$1.58/month** |

### Steady state — months 13+ (post Free Tier)

Assumes 50 events/month, ~3 GB of optimised photos retained per event. Originals move to Glacier IR after 30 days.

| Line item | Usage | Monthly cost |
|---|---|---|
| EC2 t3.micro on-demand | 730 h × $0.0116 | **$8.47** |
| *(switch to t4g.micro for ~30% saving)* | 730 h × $0.0084 | *$6.13* |
| EBS gp3 8 GB | 8 GB × $0.08 | **$0.64** |
| S3 Standard (optimised + thumbs) | 50 GB × $0.023 | **$1.15** |
| S3 Glacier IR (originals) | 100 GB × $0.004 | **$0.40** |
| CloudFront egress | < 1 TB (always-free tier) | **$0** |
| Route 53 zone | 1 zone | **$0.50** |
| CloudWatch logs/metrics | basic | **~$0.50** |
| Domain renewal | $13/year | **~$1.08/month** |
| **Total (t3.micro)** | | **~$12.74/month** |
| **Total (t4g.micro)** | | **~$10.40/month** |

> **Tip**: Switch `instance_type` from `t3.micro` to `t4g.micro` in `infra/live/prod/env.hcl` after Free Tier ends. It is ~30% cheaper at the same performance level.

### Cost cliffs — when this stops being cheap

| Trigger | Impact | Mitigation |
|---|---|---|
| CloudFront egress > 1 TB/month | +$85/TB | Long `Cache-Control` on `/uploads/*` (already set to 1 year) |
| S3 storage > 5 GB during Free Tier | $0.023/GB | Lifecycle rules move originals to IA/Glacier after 30 days |
| EBS > 30 GB during Free Tier | $0.08/GB above 30 | SQLite + WAL growth is slow; 8 GB handles thousands of events |
| Adding a second AZ | Doubles per-AZ costs | Single-AZ is acceptable for this app's SLA |

---

## Scaling Path

When the app outgrows this setup, each step is a targeted change with no architecture rewrite:

| Signal | Action | Cost delta |
|---|---|---|
| CPU consistently > 70% | Change `instance_type = "t4g.small"` | +~$6/month |
| > 200 concurrent SSE connections | `t4g.small` (double RAM) | +~$6/month |
| SQLite write contention | Add RDS `db.t4g.micro` | +~$13/month |
| Photo resize CPU high | Move Sharp to Lambda + S3 event trigger | +~$1/month at current volume |
| Uptime SLA requirement | Add ALB + second AZ | +~$25/month |

---

## Security Baseline

- **No SSH access** — instances are accessed exclusively via SSM Session Manager (IAM-controlled).
- **EBS encrypted** — all volumes use AWS-managed KMS keys at no cost.
- **S3 fully private** — `BlockPublicAccess` on; photos are served only via CloudFront OAC.
- **IAM least-privilege** — the EC2 role can only `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the uploads bucket prefix. No wildcard `*` resources.
- **WHOIS privacy** — domain registration has privacy protection enabled; contact details are hidden from public WHOIS lookups.
- **Secrets in SSM** — `ADMIN_PASSWORD` is stored as a `SecureString` parameter, not in environment files or Docker Compose directly.

---

## State Management

Terraform state is stored per-component in S3 with **native S3 locking** (`use_lockfile = true`, Terraform 1.10+). When a plan or apply runs, Terraform writes a `.tflock` file alongside the state in the same bucket. No DynamoDB table is needed.

```
s3://perpetual-share-tfstate/
├── prod/
│   ├── networking/terraform.tfstate
│   ├── storage/terraform.tfstate
│   ├── compute/terraform.tfstate
│   ├── dns/terraform.tfstate
│   ├── cdn/terraform.tfstate
│   ├── storage-policy/terraform.tfstate
│   └── observability/terraform.tfstate
└── qa/
    ├── networking/terraform.tfstate
    ├── storage/terraform.tfstate
    ├── compute/terraform.tfstate
    └── observability/terraform.tfstate
```

Each component can be planned and applied independently without touching other components' state.

---

## Disaster Recovery

| Scenario | RTO | RPO | Recovery |
|---|---|---|---|
| EC2 instance lost | ~10 min | 24 h | `terragrunt apply` rebuilds; restore latest SQLite backup from S3; EBS re-attaches |
| Accidental S3 delete | minutes | 0 | S3 versioning is enabled on the uploads bucket |
| DB corruption | ~30 min | 24 h | Restore from daily SQLite backup in S3 |
| Region outage | manual | 24 h | Restore from S3 backups in another region; update Route 53 |

SQLite is backed up daily via an SSM-triggered cron command that copies the database file to `s3://perpetual-share-prod-uploads/backups/db/`.
