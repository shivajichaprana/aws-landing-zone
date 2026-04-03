###############################################################################
# Makefile — AWS Landing Zone
# Provides consistent developer workflow for formatting, validation, linting,
# testing, and planning Terraform configurations.
###############################################################################

.PHONY: help fmt validate lint test plan clean all

# Default target
.DEFAULT_GOAL := help

# Module directories
MODULES := $(wildcard modules/*)
EXAMPLE := examples/complete

# Colors for terminal output
BLUE  := \033[0;34m
GREEN := \033[0;32m
RED   := \033[0;31m
RESET := \033[0m

## help: Show this help message
help:
	@echo ""
	@echo "$(BLUE)AWS Landing Zone — Development Targets$(RESET)"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /' | column -t -s ':'
	@echo ""

## fmt: Format all Terraform files recursively
fmt:
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive .
	@echo "$(GREEN)Done.$(RESET)"

## validate: Initialize and validate each module
validate:
	@echo "$(BLUE)Validating modules...$(RESET)"
	@for dir in $(MODULES) $(EXAMPLE); do \
		echo "  Validating $$dir..."; \
		cd $$dir && terraform init -backend=false -input=false > /dev/null 2>&1 && \
		terraform validate && cd $(CURDIR) || \
		(echo "$(RED)  FAILED: $$dir$(RESET)" && cd $(CURDIR) && exit 1); \
	done
	@echo "$(GREEN)All modules valid.$(RESET)"

## lint: Run TFLint on all modules
lint:
	@echo "$(BLUE)Linting modules with TFLint...$(RESET)"
	@tflint --init > /dev/null 2>&1
	@for dir in $(MODULES); do \
		echo "  Linting $$dir..."; \
		cd $$dir && terraform init -backend=false -input=false > /dev/null 2>&1 && \
		tflint --config "$(CURDIR)/.tflint.hcl" --format compact && \
		cd $(CURDIR) || \
		(echo "$(RED)  FAILED: $$dir$(RESET)" && cd $(CURDIR) && exit 1); \
	done
	@echo "$(GREEN)Linting passed.$(RESET)"

## test: Run Terraform native tests
test:
	@echo "$(BLUE)Running Terraform tests...$(RESET)"
	@terraform test -test-directory=tests
	@echo "$(GREEN)Tests passed.$(RESET)"

## plan: Run terraform plan on the complete example (requires AWS credentials)
plan:
	@echo "$(BLUE)Planning complete example...$(RESET)"
	@cd $(EXAMPLE) && terraform init -backend=false -input=false > /dev/null 2>&1 && \
		terraform plan -input=false
	@echo "$(GREEN)Plan complete.$(RESET)"

## clean: Remove .terraform directories and lock files
clean:
	@echo "$(BLUE)Cleaning up...$(RESET)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleaned.$(RESET)"

## all: Run fmt, validate, lint, and test in sequence
all: fmt validate lint test
	@echo "$(GREEN)All checks passed.$(RESET)"
