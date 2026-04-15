# Step 1: Install Requirements

Follow these commands to prepare your local machine for the RetailVault deployment.

## 1. Install Azure CLI
Download and install the Azure CLI for your operating system:
*   **Windows**: [Download MSI](https://aka.ms/installazurecliwindows)
*   **macOS**: `brew install azure-cli`
*   **Linux**: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`

**Verify Installation:**
```powershell
az --version
```

---

## 2. Install Terraform
Download the Terraform binary (v1.0 or later):
*   **Download**: [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads)
*   Extract the `terraform.exe` to a folder and add that folder to your System PATH.

**Verify Installation:**
```powershell
terraform -version
```

---

## 3. Azure Account Login
Authenticating with your Azure subscription:
```powershell
az login

# List subscriptions to ensure you are in the right one
az account list --output table

# Set your active subscription (if you have multiple)
# az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

---

## 4. SSH Key Generation (For VM Access)
If you don't have an SSH key, generate one for the Linux VM:
```powershell
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa"
```
