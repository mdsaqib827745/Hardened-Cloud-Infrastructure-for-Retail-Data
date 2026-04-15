# RetailVault: Secure File Storage Deployment Guide

This guide provides step-by-step instructions for deploying the **RetailVault** secure file storage system on Azure. RetailVault provides hardened, client-side-password-derived encryption (AES-256-GCM) for sensitive files.

---

## 1. Prerequisites
Before starting, ensure the following are installed and configured:
*   **Azure CLI**: [Install link](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
*   **Terraform (v1.0+)**: [Install link](https://developer.hashicorp.com/terraform/downloads)
*   **Azure Account**: Active subscription with permissions to create Resource Groups and VMs.

### **Initial Login**
```powershell
az login
# Confirm the correct subscription is active
az account show
```

---

## 2. Infrastructure Setup (Terraform)
Navigate to the `terraform/` directory and initialize the environment.

### **Step 1: Initialization**
```powershell
cd terraform
terraform init
```

### **Step 2: Provision Resources**
The following command will create the Virtual Network, Backend Subnet, Hardened VM, Application Gateway (WAF), and Secure Storage Account.

```powershell
terraform apply -auto-approve `
  -var="sql_admin_password=HardenedRetail2026!" `
  -var="sql_admin_login=sqladmin" `
  -var="location=centralindia" `
  -var="resource_group_name=rg-retail-hardened-prod"
```

> [!NOTE]
> This process takes approximately 5-10 minutes. Once complete, Terraform will output the **Application Gateway Public IP**.

---

## 3. Application Deployment (Fix V5 Architecture)
The application uses a "Fix V5" architecture, which ensures that filenames are preserved correctly through the Azure Application Gateway and Nginx proxy using RFC 8187 headers.

### **Run the Deployment Script**
Execute the following Azure CLI command to push the code and configure the VM:

```powershell
az vm run-command invoke `
  -g rg-retail-hardened-prod `
  -n vm-retail-web `
  --command-id RunShellScript `
  --scripts @deploy_fix_v5.sh
```

### **What the deploy script does:**
1.  **Code Transfer**: Writes `app.py` and `crypto_utils.py` to the VM.
2.  **Nginx Hardening**: Configures Nginx to forward `Content-Disposition` and `Access-Control-Expose-Headers`.
3.  **Transparent Proxy**: Disables proxy buffering to ensure headers are processed in real-time.
4.  **Service Restart**: Restarts the Gunicorn server and Nginx.

---

## 4. Operational Testing
Once deployed, the application is accessible via the Public IP: `http://<YOUR_PUBLIC_IP>/`

### **A. Encryption (Upload)**
1.  Navigate to the homepage.
2.  Select a file (e.g., `invoice.pdf`).
3.  Enter a strong password. This password is **not stored anywhere**; it is used to derive the AES key in-memory.
4.  Click **"Encrypt & Download .enc"**.
5.  The browser will download `invoice.pdf.enc`.

### **B. Decryption (Download)**
1.  Navigate to the `/decrypt` page.
2.  Upload the `.enc` file you just downloaded.
3.  Enter the same password.
4.  Click **"Decrypt & Download"**.
5.  The browser will restore the original `invoice.pdf`.

---

## 5. Security & Maintenance

> [!IMPORTANT]
> **Encryption Standard**: RetailVault uses AES-256-GCM with Argon2id key derivation. Encryption is "authenticated," meaning if even a single bit of the file is tampered with, decryption will fail immediately to protect data integrity.

### **Logs & Troubleshooting**
If there are issues with the application logic, you can view the live logs on the VM:
```bash
# Connect to VM or use run-command:
tail -f /home/azureuser/retailvault/app.log
```

### **WAF Management**
The system is currently in **Detection Mode** for the WAF to ensure Maximum compatibility with complex file headers. To switch to full **Prevention Mode** (Blocking):
1.  Edit `main.tf`: Change `mode = "Prevention"` in the `policy_settings`.
2.  Run `terraform apply` again.

---

## 6. Cleanup (Destroying)
To stop all charges and remove all Azure resources:
```powershell
terraform destroy -auto-approve
```
