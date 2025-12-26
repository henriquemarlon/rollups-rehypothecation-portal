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

# Generic forge script runner (simulation only)
define FORGE_SCRIPT_SIMULATE
	$(START_LOG)
	@mkdir -p ./deployments
	@forge clean
	@forge script $(1) \
		-vvv
	$(END_LOG)
endef

define deploy_erc20_rehypothecation_portal
	$(call FORGE_SCRIPT,./scripts/DeployERC20ReHypothecationPortal.s.sol:DeployERC20ReHypothecationPortal)
endef

define simulate_erc20_rehypothecation_portal
	$(call FORGE_SCRIPT_SIMULATE,./scripts/DeployERC20ReHypothecationPortal.s.sol:DeployERC20ReHypothecationPortal)
endef

# =============================================================================
# BUILD & TEST COMMANDS
# =============================================================================

.PHONY: build
build: ## Build the contracts
	$(START_LOG)
	@forge build
	$(END_LOG)

.PHONY: test
test: ## Run the contracts tests
	$(START_LOG)
	@forge clean
	@forge test -vvv
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
deploy: deploy-erc20-rehypothecation-portal ## Deploy all contracts
	$(START_LOG)
	@echo "All contracts deployed! Check ./deployments/ for deployment files"
	$(END_LOG)

.PHONY: deploy-simulate
deploy-simulate: ## Simulate deployment without broadcasting
	$(START_LOG)
	@echo "Simulating ERC20ReHypothecationPortal deployment..."
	@$(call FORGE_SCRIPT_SIMULATE,./scripts/DeployERC20ReHypothecationPortal.s.sol:DeployERC20ReHypothecationPortal)
	@echo "All contract simulations completed!"
	$(END_LOG)

.PHONY: deploy-erc20-rehypothecation-portal
deploy-erc20-rehypothecation-portal: ## Deploy ERC20ReHypothecationPortal contract
	$(START_LOG)
	@$(deploy_erc20_rehypothecation_portal)
	@echo "ERC20ReHypothecationPortal deployment completed! Check ./deployments/ for addresses"
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
