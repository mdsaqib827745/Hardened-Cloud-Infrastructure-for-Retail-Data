# Step 2: Run & Deploy the Project

Follow these commands in sequence to deploy and manage the **RetailVault** environment.

## 1. Initial Identity Preparation
Ensure you are in the `terraform/` directory.

```powershell
cd terraform
terraform init
```

---

## 2. Infrastructure Deployment (Azure Resources)
Run the following command to create the full environment. This will take **5-10 minutes**.

```powershell
terraform apply -auto-approve `
  -var="sql_admin_password=HardenedRetail2026!" `
  -var="sql_admin_login=sqladmin" `
  -var="location=centralindia" `
  -var="resource_group_name=rg-retail-hardened-prod"
```

**Output**: Terraform will output the **Application Gateway Public IP** (e.g., `20.207.197.147`).

---

## 3. Application Handoff (Final logic & Headers Fix)
Once the resources are ready, push the application code and configure the Nginx/WAF environment using the final deployment script:

```powershell
az vm run-command invoke `
  -g rg-retail-hardened-prod `
  -n vm-retail-web `
  --command-id RunShellScript `
  --scripts @deploy_fix_v5.sh
```

**Confirmation**: You should see `"FIX V5 APPLIED"` in the command output.

---

## 4. Test the Application
Visit the public IP in your browser:
*   **Encrypt**: `http://<YOUR_PUBLIC_IP>/`
*   **Decrypt**: `http://<YOUR_PUBLIC_IP>/decrypt`

> [!TIP]
> Use **Incognito/Private Mode** for the initial test to bypass any previous browser caching of filenames.

---

## 5. View Logs (Optional)
To monitor the live application behavior:
```powershell
az vm run-command invoke `
  -g rg-retail-hardened-prod `
  -n vm-retail-web `
  --command-id RunShellScript `
  --scripts "tail -f /home/azureuser/retailvault/app.log"
```

---

## 6. Project Cleanup (Destroy Everything)
To remove all Azure resources and stop billing:
```powershell
terraform destroy -auto-approve
```
