provider "aws" {
  # Single‑region assignment – no multi‑region complexity.
  region = "eu-central-1"

  # Enforce the required tags project‑wide.  Anything created in Terraform will
  # automatically pick these up **unless** the resource type does not inherit
  # default_tags (rare – CloudFront, Route 53, etc.).  Modules *also* merge
  # an `Environment` tag so CloudWatch/Cost Explorer reports are easy to read.
  default_tags {
    tags = {
      Creator = "emilian"
      Project = "iac-task"
    }
  }
}
