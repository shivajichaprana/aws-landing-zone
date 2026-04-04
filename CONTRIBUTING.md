# Contributing to aws-landing-zone

Thank you for considering contributing to this project. This document outlines the development workflow, coding standards, and pull request process.

## Development Setup

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [TFLint](https://github.com/terraform-linters/tflint) >= 0.50
- [pre-commit](https://pre-commit.com/) >= 3.0
- GNU Make
- Git

### Getting Started

```bash
# Clone the repository
git clone https://github.com/shivajichaprana/aws-landing-zone.git
cd aws-landing-zone

# Install pre-commit hooks
pre-commit install

# Verify your setup
make all
```

## Coding Standards

### Terraform Style

- Run `terraform fmt -recursive` before every commit (enforced by pre-commit)
- Use meaningful variable descriptions — they appear in generated docs
- Add `validation` blocks on variables where input constraints exist (e.g., CIDR ranges, naming patterns)
- Use `lifecycle` rules to prevent accidental destruction of stateful resources
- Pin provider versions in `versions.tf` for every module
- Prefer `for_each` over `count` for resources that need stable addressing

### Module Structure

Every module must contain:

```
modules/<name>/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables with descriptions and defaults
├── outputs.tf       # Output values with descriptions
├── versions.tf      # Required providers and Terraform version constraint
└── README.md        # Module documentation with inputs/outputs tables
```

### Naming Conventions

- **Resources:** `snake_case` with descriptive names (e.g., `aws_s3_bucket.logging_bucket`)
- **Variables:** `snake_case`, prefixed with context where helpful (e.g., `logging_bucket_name`)
- **Outputs:** `snake_case`, describing what the value represents (e.g., `organization_id`)
- **Files:** lowercase `snake_case` (e.g., `design_decisions.md` for internal docs, `README.md` for standard files)

### Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `test`, `ci`, `refactor`, `chore`

Scopes match module or directory names: `organizations`, `scp`, `sso`, `logging`, `account-vending`, `readme`, `build`

Examples:
```
feat(scp): add SCP to deny public S3 bucket creation
fix(logging): correct KMS key policy for CloudWatch Logs
docs(readme): update architecture diagram with new OU structure
test(organizations): add validation test for OU name uniqueness
ci(terraform): add tflint caching to GitHub Actions workflow
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run a specific test file
cd tests
terraform test -filter=organizations_test.tftest.hcl
```

### Writing Tests

- Place test files in `tests/` with the naming pattern `<module>_test.tftest.hcl`
- Test both valid configurations (expect apply to succeed) and invalid inputs (expect validation errors)
- Use `mock_provider` blocks to avoid requiring real AWS credentials in CI

### Validation Before Submitting

```bash
# Run the full check suite
make all    # fmt + validate + lint + test

# Verify no formatting drift
make fmt
git diff --exit-code
```

## Pull Request Process

1. Create a feature branch from `main`: `git checkout -b feat/my-feature`
2. Make your changes, following the coding standards above
3. Run `make all` and fix any issues
4. Commit with a Conventional Commits message
5. Open a PR against `main` with a clear description of what changed and why
6. Ensure CI passes (format, validate, lint, test)
7. Request review

### PR Checklist

- [ ] `make all` passes locally
- [ ] New variables have descriptions and sensible defaults
- [ ] New outputs have descriptions
- [ ] Module README is updated with new inputs/outputs
- [ ] Commit messages follow Conventional Commits format
- [ ] No hardcoded values — use variables with defaults

## Security

- Never commit AWS credentials, account IDs, or secrets
- Use `sensitive = true` on outputs that expose secret material
- SCPs and IAM policies follow least-privilege principles
- Report security vulnerabilities privately — do not open public issues

## Questions?

Open an issue or reach out to the maintainer.
