# Client Handoff: Live Transfer Checklist

Follow these steps to successfully move the **RetailVault** project from your machine to the client's machine.

---

## Phase 1: File Transfer
1.  **Locate the ZIP**: Find **[RetailVault_Secure_Handoff.zip](file:///e:/saqib/RetailVault_Secure_Handoff.zip)** in your `e:\saqib` folder.
2.  **Move the File**: Use a USB drive, a secure cloud link (OneDrive/Google Drive), or a direct transfer to put this ZIP on the client's desktop.
3.  **Extract**: Right-click the ZIP on the client's PC and select "Extract All...".

---

## Phase 2: Client Environment Setup
On the **Client's PC**, open PowerShell and run these checks:

### **1. Azure CLI Check**
Run: `az --version`
*   *If not installed*: Use the link in `INSTALL_REQS.md`.
*   *If installed*: Run **`az login`** to connect to the **Client's Azure Account**.

### **2. Terraform Check**
Run: `terraform -version`
*   *If not installed*: Download the `.exe` as per `INSTALL_REQS.md` and add it to their System PATH.

### **3. SSH Key Check**
Run: `ls $env:USERPROFILE\.ssh\id_rsa.pub`
*   *If it doesn't exist*: Run **`ssh-keygen -t rsa -b 4096`** to create their deployment identity.

---

## Phase 3: The First Deployment
Once the environment is ready, open the extracted folder in PowerShell:

### **1. Initialize**
```powershell
cd terraform
terraform init
```

### **2. Launch Infrastructure**
```powershell
terraform apply -auto-approve `
  -var="sql_admin_password=YourClientPassword2026!" `
  -var="sql_admin_login=clientadmin"
```
*Note: This will create the Resource Group and all 16+ resources in their account.*

### **3. Final Application Handoff**
```powershell
az vm run-command invoke `
  -g rg-retail-hardened-prod `
  -n vm-retail-web `
  --command-id RunShellScript `
  --scripts @deploy_fix_v5.sh
```

---

## Phase 4: Verification
1.  Get the **Public IP** from the Terraform output.
2.  Open the browser on the client's machine.
3.  **Test Upload & Download** to confirm the `Fix V5` headers are working in their browser.

> [!TIP]
> If they get a "Resource Group already exists" error, it means they might have another project with the same name. You can change the `resource_group_name` variable in the `apply` command.
