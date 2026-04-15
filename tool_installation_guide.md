# Local Tool Installation Guide

To run the Terraform code I've written, you need to install **Terraform** and the **Azure CLI** on your Windows machine.

## 1. Install Azure CLI
1. Download the MSI installer: [Azure CLI for Windows](https://aka.ms/installazurecliwindows).
2. Run the installer and follow the prompts.
3. Open a **NEW** terminal (PowerShell or CMD) and type `az login`.
4. A browser window will open; sign in with your student account.

## 2. Install Terraform
1. Download the Windows 64-bit ZIP: [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads).
2. Extract the `terraform.exe` file to a folder (e.g., `C:\terraform`).
3. Add this folder to your system **PATH**:
   - Search for "Edit the system environment variables".
   - Click **Environment Variables**.
   - Under "System variables", find **Path** and click **Edit**.
   - Click **New** and paste the path to your folder (e.g., `C:\terraform`).
   - Click **OK** on all windows.
4. Open a **NEW** terminal and type `terraform -v` to verify.

## 3. Running the Code (Once Tools are Ready)
1. In your terminal, go to the project directory:
   ```powershell
   cd e:\saqib\terraform
   ```
2. Initialize Terraform:
   ```powershell
   terraform init
   ```
3. Preview the changes:
   ```powershell
   terraform plan
   ```
4. Deploy the network:
   ```powershell
   terraform apply
   ```
