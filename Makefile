-include .env

START_LOG = @echo "======================= START OF LOG ======================="
END_LOG   = @echo "======================== END OF LOG ========================"

# Generic forge script runner
define FORGE_SCRIPT
	$(START_LOG)
	@mkdir -p ./deployments
	@forge clean
	@forge script $(1) \
		--rpc-url $(RPC_URL) \
		--private-key defaultKey \
		--broadcast \
		-vvv
	$(END_LOG)
endef

define deploy_erc20_rehypothecation_portal
	$(call FORGE_SCRIPT,./scripts/DeployERC20ReHypothecationPortal.s.sol:DeployERC20ReHypothecationPortal)
endef

define deploy_safe_yield_claim
	$(call FORGE_SCRIPT,./scripts/DeploySafeYieldClaim.s.sol:DeploySafeYieldClaim)
endef

define deploy_mock_application
	$(call FORGE_SCRIPT,./scripts/DeployMockApplication.s.sol:DeployMockApplication)
endef

# =============================================================================
# BUILD & TEST COMMANDS
# =============================================================================

.PHONY: env
env: ## Create .env file from .env.tmpl
	$(START_LOG)
	@if [ -f .env ]; then \
		echo ".env file already exists. Skipping..."; \
	else \
		cp .env.tmpl .env; \
		echo ".env file created from .env.tmpl"; \
	fi
	$(END_LOG)

.PHONY: build
build: ## Build the contracts
	$(START_LOG)
	@forge build
	$(END_LOG)

.PHONY: test-unit
test-unit: ## Run unit tests (excludes fork tests)
	$(START_LOG)
	@forge clean
	@forge test --no-match-test 'testFork_*' -vvvv
	$(END_LOG)

.PHONY: test-fork
test-fork: ## Run fork tests only
	$(START_LOG)
	@forge clean
	@forge test --match-test 'testFork_*' --fork-url $(RPC_URL) -vvvv
	$(END_LOG)

.PHONY: test
test: ## Run all tests (unit + fork)
	$(START_LOG)
	@forge clean
	@forge test --no-match-test 'testFork_*' -vvvv
	@forge test --match-test 'testFork_*' --fork-url $(RPC_URL) -vvv
	$(END_LOG)

.PHONY: fmt
fmt: ## Format contracts
	$(START_LOG)
	@forge fmt
	@echo "Formatting completed"
	$(END_LOG)

# =============================================================================
# DEPLOYMENT COMMANDS
# =============================================================================

.PHONY: deploy
deploy: deploy-erc20-rehypothecation-portal deploy-safe-yield-claim deploy-mock-application ## Deploy all contracts
	$(START_LOG)
	@echo "All contracts deployed! Check ./deployments/ for deployment files"
	$(END_LOG)

.PHONY: deploy-erc20-rehypothecation-portal
deploy-erc20-rehypothecation-portal: ## Deploy ERC20ReHypothecationPortal contract
	$(START_LOG)
	@$(deploy_erc20_rehypothecation_portal)
	@echo "ERC20ReHypothecationPortal deployment completed! Check ./deployments/ for addresses"
	$(END_LOG)

.PHONY: deploy-safe-yield-claim
deploy-safe-yield-claim: ## Deploy SafeYieldClaim contract
	$(START_LOG)
	@$(deploy_safe_yield_claim)
	@echo "SafeYieldClaim deployment completed! Check ./deployments/ for addresses"
	$(END_LOG)

.PHONY: deploy-mock-application
deploy-mock-application: ## Deploy MockApplication contract (for testing)
	$(START_LOG)
	@$(deploy_mock_application)
	@echo "MockApplication deployment completed! Check ./deployments/ for addresses"
	$(END_LOG)

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

.PHONY: size
size: ## Check contract sizes
	$(START_LOG)
	@forge build --sizes
	$(END_LOG)

.PHONY: gas
gas: ## Run gas reports
	$(START_LOG)
	@forge test --gas-report -vv
	$(END_LOG)

.PHONY: help
help: ## Show help for each of the Makefile recipes
	@echo "Available commands:"
	@awk '/^[a-zA-Z0-9_-]+:.*##/ { \
		split($$0, parts, "##"); \
		split(parts[1], target, ":"); \
		printf "  \033[36m%-30s\033[0m %s\n", target[1], parts[2] \
	}' $(MAKEFILE_LIST)
