# Culinary Platform Infrastructure
Badges: [Terraform fmt/validate] [Build & Deploy] [License: MIT]

A containerized culinary platform deployed on Azure using Terraform for infrastructure-as-code, GitHub Actions for CI/CD, Azure Container Registry and Web Apps, Azure Key Vault for secrets, and PostgreSQL Flexible Server.

# Introduction
Culinary Platform provides a scalable microservices-based food delivery demo app. All infrastructure is defined in Terraform and deployed via GitHub Actions. Frontend and backend services run in Linux Web Apps with Docker images stored in ACR. PostgreSQL Flexible Server hosts the database in a private subnet. Secrets live in Key Vault and are read by Terraform. 

# Architecture
 * Frontend web app and backend API as Docker containers hosted in Azure App Service
 * Azure Container Registry (Standard SKU) stores images
 * PostgreSQL Flexible Server in private virtual network
 * Azure Key Vault holds database credentials
 * GitHub Actions pipelines for Terraform, frontend and backend CI/CD
 * Service Principal with RBAC to deploy infrastructure and read Key Vault secrets
 * Prerequisites
   
# Azure subscription with Owner or Contributor rights
 * Azure CLI (2.XX+) installed and logged in
 * Terraform v1.12.2+
 * GitHub repository with GitHub Actions enabled
 * Docker installed locally (for local testing)

# Azure Setup
Resource group, Key Vault, Key Vault secrets and access policies were created manually via the Azure Portal.
 1. Create a resource group in the portal.
 2. Create a Key Vault named `container-key-val`.
 3. Add two secrets in Key Vault: `DbUsername` and `DbPassword`.
 4. Create an Azure AD App Registration (Service Principal) named `github-sp-culinary`.
 5. In Key Vault’s **Access control (IAM)** assign the **Key Vault Secrets User** role to `github-sp-culinary`.
 6. (Optional) In Key Vault’s** Access policies** enable **Get** and **List** on secrets for `github-sp-culinary` if using Access Policies model.

# GitHub Secrets
In your repository settings add these secrets:
 * `AZURE_CREDENTIALS`: JSON output from `az ad sp create-for-rbac --name github-sp-culinary --role contributor --scopes /subscriptions/<SUB_ID> --sdk-auth`
 * `ACR_LOGIN_SERVER`: e.g. `myacr.azurecr.io`
 * `ACR_USERNAME`: ACR admin username (or service principal)
 * `ACR_PASSWORD`: ACR admin password (or service principal secret)
 * `AZURE_WEBAPP_PUBLISH_PROFILE_FRONTEND`: Publish profile XML for frontend Web App
 * `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`: Publish profile XML for backend Web App

# Terraform Workflow
File: `.github/workflows/terraform.yml`
Triggers on push to `main` when files under `terraform/**` change or via workflow_dispatch:. Uses OIDC or Service Principal to log in.

Steps:
 1. Checkout code
 2. Azure login via azure/login@v1 with AZURE_CREDENTIALS
 3. Setup Terraform v1.12.2
 4. `terraform init`
 5. `terraform fmt -check` and `terraform validate`
 6. `terraform plan `reading database credentials from Key Vault
 7. `terraform apply -auto-approve`
All variables without defaults are either in committed `*.tfvars` or loaded at runtime from Key Vault.

# Frontend Workflow
File: `.github/workflows/frontend.yml`
Triggers on push to `frontend/**` or via workflow_dispatch.
Steps:
1. Checkout code
2. Docker login to ACR
3. Build and push Docker image `front-container:${{ github.sha }}`
4. Deploy to Azure Web App using `azure/webapps-deploy@v2` with publish profile secret

# Backend Workflow
File: `.github/workflows/backend.yml`
Triggers on push to `backend/**` or via workflow_dispatch.
Steps mirror frontend workflow, building `django-docker:${{ github.sha }}` and deploying with publish profile secret for backend Web App.

# Terraform Configuration
Directory `terraform/` contains:
* **main.tf**
  * Data sources for resource group and Key Vault secrets
  * ACR (`azurerm_container_registry`)
  * App Service Plan (`azurerm_service_plan`)
  * Linux Web Apps for frontend and backend with system-assigned identities
  * PostgreSQL Flexible Server in private subnet
* **network.tf**
  * Virtual network and two subnets (App Service and PostgreSQL) with appropriate delegations
  * Private DNS zone for PostgreSQL and its virtual network link
* **variables.tf** and `*.tfvars` for non-secret configurations

# Usage
To test locally:
```
az login
export ARM_USE_AZURECLI_AUTH=true
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply 
```
CI/CD is covered by GitHub Actions. Simply push changes to `main` or to `frontend/` or `backend/` folders and workflows run automatically.

# Contributing
Pull requests are welcome. Please follow Terraform style conventions:
 * `terraform fmt`
 * `terraform validate`
* Update `README.md` if you add new features
