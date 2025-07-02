# iac-task (emilian)

> **Multi‑Environment Infrastructure‑as‑Code & CI/CD Demo**\
> Terraform · AWS CDK‑Free · GitHub Actions · Docker / ECR · ECS Fargate

---

## 1  Architecture Overview

```
 ┌─────────────────────────────────────────────────────────┐
 │ GitHub Actions (build ‑‑> dev  /  manual ‑‑> prod)      │
 └────────────┬────────────────────────────────────────────┘
              │  (terraform apply)
              ▼
┌──────────────────────────────────────────────────────────┐
│   AWS Account – eu‑central‑1                             │
│                                                          │
│   VPC (per env)             ┌──────────┐                 │
│  10.0.X.0/24                │  ALB     │◄─ public SG     │
│     ├─ 1 Public Subnet ───► │  :80     │                 │
│     └─ 1 Private Subnet     └──────────┘                 │
│            ▲                        ▲                    │
│            │                        │ target grp         │
│   NAT GW + Elastic IP         ┌──────────────────────┐   │
│                               │  ECS Service         │   │
│  (outbound internet)          │ Fargate tasks (app)  │   │
│                               └──────────────────────┘   │
│                                  ▲ env vars via TF       │
│                                  │ cloudwatch logs       │
│ CloudWatch Logs  ────────────────┘                       │
│  /emilian‑applogs/<env>                                  │
│                                                          │
│ Amazon ECR  (iac-task‑<env>)                             │
│   └─ images tagged :sha , :latest                        │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

- **Terraform modules** – `vpc`, `ecr`, `alb`, `ecs_service` keep code DRY.
- **dev** and **prod** have isolated state (`infra/envs/*`), separate VPCs, CPU/memory/task‑count, and independent ECR repos.
- **GitHub Actions** builds the image, pushes to ECR, then runs `terraform apply`
    - auto‑deploy on **dev** branch
    - manual approval gate for **prod** branch.
- All resources carry mandatory tags **Creator=emilian** / **Project=iac‑task** at *create* time (IAM requirement).

---

## 2  Setup & Deployment

### 2.1 Prerequisites (local)

| Tool           | Version | Windows 11 install hint                                              |
| -------------- | ------- | -------------------------------------------------------------------- |
| Docker Desktop | 26+     | [https://docs.docker.com/desktop/](https://docs.docker.com/desktop/) |
| Node LTS       | ≥20     | `winget install OpenJS.NodeJS.LTS`                                   |
| Terraform      | ≥1.8    | `choco install terraform`                                            |
| AWS CLI v2     | latest  | `winget install Amazon.AWSCLI`                                       |
| Git            | latest  | Git for Windows / WSL                                                |

```bash
# configure credentials once (scoped IAM user)
aws configure  # region: eu-central-1
```

### 2.2 Clone & bootstrap

```bash
git clone <repo> && cd iac-task

# Initialise remote‑state & providers for dev
cd infra/envs/dev
terraform init -backend-config=backend.hcl

# Create the ECR repo only (needs placeholder image_tag)
terraform apply -target=module.ecr -auto-approve -var="image_tag=bootstrap"

# Capture the repo URI:
export REPO=$(terraform output -raw repository_url)

# Build & push first image
docker build -t $REPO:initial ./app
docker push $REPO:initial

# Deploy full stack
terraform apply -auto-approve -var="image_tag=initial"
```

Visit `` → `{ "ok": true }`.

### 2.3 CI/CD

1. Add secrets in GitHub → *Settings → Secrets → Actions*
    - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
2. Protect *prod* environment with required reviewers.
3. Push to **dev** → auto‑deploy.  
4. Merge to **prod** → approve UI → rolling update. Repository → Settings → Environments → prod → Protection rules

---

## 3  Cleanup

```bash
# Destroy stacks
cd infra/envs/dev   && terraform destroy -auto-approve
dcd ../prod         && terraform destroy -auto-approve

# Remove remote state & lock table
aws s3 rm s3://emilian-terraform-state --recursive
aws s3 rb s3://emilian-terraform-state
aws dynamodb delete-table --table-name emilian-terraform-locks

# (Optional) delete ECR repos & CloudWatch log groups manually if IAM denies TF
```

---

## 4  Assumptions & Limitations

| Area           | Note                                                                                                                                                                                                                            |
| -------------- |---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **IAM policy** | Restricted test user must allow: • `ecr:ListTagsForResource` & `logs:ListTagsForResource` *(or log‑group managed manually as shown)* • `iam:CreateRole`, `ec2:CreateVpc/Subnet/*`, `ecs:*` on resources carrying required tags. |
| **Log groups** | If `logs:ListTagsForResource` is denied, create `/emilian‑applogs/iac-task/<env>` manually with the required tags and run `terraform state rm` for the TF resource.                                                             |
| **NAT costs**  | Two NAT Gateways (one per AZ). For cheaper lab usage set `az_count = 1` in `modules/vpc`.                                                                                                                                       |
| **Rollback**   | ECS rolling update strategy (min healthy = 100%) provides zero-downtime but not automatic rollback; rely on `terraform apply` with previous `image_tag` to roll back.                                                           |
| **Secrets**    | Demo stores env vars in Github Secrets. Alternatively use SSM Parameter Store or Secrets Manager and extend the task role.                                                                                          |
