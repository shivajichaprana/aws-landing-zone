# aws-landing-zone

Terraform modules for building a production-ready AWS multi-account landing zone — Organizations, SCPs, SSO, centralized logging, and automated account vending.

## Architecture

```
Management Account
├── Security OU
│   ├── Log Archive Account
│   └── Audit Account
├── Infrastructure OU
│   ├── Network Hub Account
│   └── Shared Services Account
├── Workloads OU
│   ├── Production Account(s)
│   └── Staging Account(s)
└── Sandbox OU
    └── Developer Account(s)
```

## Modules

| Module | Description | Status |
|--------|-------------|--------|
| `modules/organizations` | AWS Organization + OU hierarchy | ✅ Complete |
| `modules/scp` | Service Control Policies (guardrails) | 🔜 Coming |
| `modules/sso` | IAM Identity Center (SSO) permission sets | 🔜 Coming |
| `modules/logging` | CloudTrail + S3 centralized logging | 🔜 Coming |
| `modules/account-vending` | Automated account creation | 🔜 Coming |

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with management account credentials
- An AWS account designated as the management (root) account

## Quick Start

```bash
# Clone the repo
git clone https://github.com/shivajichaprana/aws-landing-zone.git
cd aws-landing-zone

# Copy and configure environment
cp .env.example .env
# Edit .env with your AWS profile and region

# Initialize Terraform
cd examples/
terraform init
terraform plan
```

## Project Structure

```
aws-landing-zone/
├── modules/
│   ├── organizations/    # AWS Organization + OUs
│   ├── scp/              # Service Control Policies
│   ├── sso/              # IAM Identity Center
│   ├── logging/          # CloudTrail + centralized logs
│   └── account-vending/  # Automated account provisioning
├── examples/             # Usage examples
├── .github/workflows/    # CI/CD pipelines
├── .env.example
├── .gitignore
├── LICENSE
└── README.md
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
