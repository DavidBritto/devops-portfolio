# Ruta al módulo de Terraform (ajústala si cambiaste la estructura)
TF_DIR := voting-app/roxs-votingapp/terraform

# Ambiente por defecto (podés pasar ENV=staging/prod al invocar make)
ENV ?= dev
TFVARS := $(TF_DIR)/environments/$(ENV).tfvars
PLAN   := $(TF_DIR)/tfplan

.PHONY: help init fmt validate plan apply destroy outputs docker-ps clean

help:
	@echo "Targets disponibles:"
	@echo "  make init           - terraform init (con upgrade)"
	@echo "  make fmt            - terraform fmt -recursive"
	@echo "  make validate       - terraform validate"
	@echo "  make plan           - plan (usa ENV=$(ENV))"
	@echo "  make apply          - apply del plan"
	@echo "  make destroy        - destroy del ambiente (usa ENV=$(ENV))"
	@echo "  make outputs        - terraform output"
	@echo "  make docker-ps      - docker ps"
	@echo "  make clean          - borra plan y restos"
	@echo ""
	@echo "Ejemplos:"
	@echo "  make plan ENV=staging"
	@echo "  make apply"
	@echo "  make destroy ENV=prod"

init:
	terraform -chdir=$(TF_DIR) init -upgrade

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	@test -f "$(TFVARS)" || (echo "No existe $(TFVARS)"; exit 1)
	terraform -chdir=$(TF_DIR) plan -var-file="$(TFVARS)" -out="$(PLAN)"

apply:
	@test -f "$(PLAN)" || (echo "No existe plan: $(PLAN). Corré 'make plan' primero."; exit 1)
	terraform -chdir=$(TF_DIR) apply "$(PLAN)"

destroy:
	@test -f "$(TFVARS)" || (echo "No existe $(TFVARS)"; exit 1)
	terraform -chdir=$(TF_DIR) destroy -var-file="$(TFVARS)" -auto-approve

outputs:
	terraform -chdir=$(TF_DIR) output

docker-ps:
	docker ps

clean:
	rm -f "$(PLAN)"
