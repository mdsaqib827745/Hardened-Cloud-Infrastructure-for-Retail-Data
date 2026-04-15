# RetailVault: The Master Project Manual
### *Secure Cloud-Native File Storage & Encryption Suite*

This master document provides the complete, end-to-end technical plan, architecture, and operational guide for the **RetailVault** project. It is designed to be the single source of truth for the project handoff.

---

## 1. Executive Summary
**RetailVault** is a hardened, cloud-native file storage solution built on Microsoft Azure. It provides "Zero-Knowledge" security, ensuring that sensitive files are encrypted using keys derived directly from user passwords. No passwords or keys are ever stored on the server, making the system immune to data breaches at the database level.

---

## 2. Technical Architecture Plan

### **A. Core Infrastructure (Azure)**
*   **Virtual Network (VNet)**: Segregated network with public frontend and private backend subnets.
*   **Web Server**: Ubuntu Linux VM running **Gunicorn** (WSGI) behind an **Nginx** reverse proxy.
*   **Database**: **Azure SQL Database** (Basic Tier) for metadata management (stored using Managed Identity).
*   **Storage**: **Azure Blob Storage** for persistent storage of encrypted binary data.
*   **Ingress Security**: **Azure Application Gateway (WAF_v2)** with OWASP 3.2 protection.

### **B. Security Framework (Zero-Knowledge)**
*   **Key Derivation**: Uses **Argon2id** (the winner of the Password Hashing Competition) to derive 256-bit AES keys from user input.
*   **Encryption Scheme**: **AES-256-GCM** (Galois/Counter Mode). This provides both **Confidentiality** and **Authenticity** (tamper-proofing).
*   **Managed Identities**: The application uses **Azure User-Assigned Managed Identity** to access Storage and SQL, eliminating the need for hardcoded credentials or connection strings in the code.

---

## 3. Implementation Milestones (Complete Log)

| Phase | Milestone | Key Deliverable |
| :--- | :--- | :--- |
| **1** | **Infrastructure-as-Code** | Terraform scripts for 1-click cloud provisioning. |
| **2** | **Cryptographic Core** | `crypto_utils.py` implementing AES-GCM and Argon2id. |
| **3** | **Flask Web Interface** | Modern, responsive UI for encryption/decryption workflows. |
| **4** | **Reverse Proxy Setup** | Nginx configuration for secure header passthrough. |
| **5** | **Download Fix (V5)** | Implementation of RFC 8187 (`filename*`) for reliable downloads. |

---

## 4. Master Operational Guide (From Beginning)

### **Step 1: Installation & Setup**
1.  **Azure CLI**: [Download & Install](https://aka.ms/installazurecliwindows). Run `az login`.
2.  **Terraform**: [Download Binary](https://developer.hashicorp.com/terraform/downloads). Add to System PATH.
3.  **SSH Key**: Generate a key if you don't have one: `ssh-keygen -t rsa -b 4096`.

### **Step 2: Provisioning (Terraform)**
Navigate to the `terraform/` directory:
```powershell
cd terraform
terraform init
terraform apply -auto-approve `
  -var="sql_admin_password=HardenedRetail2026!" `
  -var="sql_admin_login=sqladmin" `
  -var="location=centralindia" `
  -var="resource_group_name=rg-retail-hardened-prod"
```

### **Step 3: Application Handoff**
Deploy the application and the final security headers:
```powershell
az vm run-command invoke `
  -g rg-retail-hardened-prod `
  -n vm-retail-web `
  --command-id RunShellScript `
  --scripts @deploy_fix_v5.sh
```

### **Step 4: Verification**
Visit the Public IP provided by Terraform.
*   **Encrypt Mode**: Upload a file, set password, download `.enc`.
*   **Decrypt Mode**: Upload `.enc`, use same password, restore original file.

---

## 5. Maintenance & Troubleshooting

### **Common Troubleshooting**
*   **"Filename is a UUID"**: Clear browser cache or use Incognito Mode. Fix V5 headers are active but browsers may cache old behavior.
*   **"502 Bad Gateway"**: Check VM status. Run the `deploy_fix_v5.sh` command again to restart services.
*   **"Permission Denied"**: Ensure your Azure account has "Owner" or "Contributor" access to the subscription.

### **Logs Viewing**
To see live application errors:
```bash
az vm run-command invoke -g rg-retail-hardened-prod -n vm-retail-web --command-id RunShellScript --scripts "tail -n 50 /home/azureuser/retailvault/app.log"
```

---

## 6. Project Conclusion
The RetailVault system is now in a **Production-Ready** state. We have successfully addressed the complex proxy header stripping issues and verified the end-to-end security of the encryption pipeline. The project is bundled as a portable ZIP file for final handover.

**Project Status: DELIVERED**
