# Client Setup & Deployment Guide

This guide will help you install the necessary tools and deploy the **Hardened Retail Cloud Infrastructure** on your own Azure account.

## 1. Fast Tool Installation (Windows)

We have provided a script to automate the installation of **Terraform** and the **Azure CLI**. 

1.  Open **PowerShell** as an **Administrator**.
2.  Run the following command:
    ```powershell
    # Install Azure CLI and Terraform via WinGet
    winget install --id Microsoft.AzureCLI -e
    winget install --id Hashicorp.Terraform -e
    ```
3.  **Restart your terminal** after the installation is complete.

## 2. Generate Your SSH Key (Required)

Terraform needs an SSH key to secure your Linux VM. Run this if you don't have one:
```powershell
ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N '""'
```

## 3. Deployment Steps

1.  **Login to Azure:**
    ```powershell
    az login
    ```
2.  **Initialize & Deploy:**
    ```powershell
    cd terraform
    terraform init
    terraform apply -auto-approve
    ```
3.  **Verify Hardening:**
    Run our custom testing script to confirm 100% security coverage:
    ```powershell
    .\final_validation_suite.ps1
    ```

## 4. Manual Testing
Once deployed, you can manually verify the **WAF (Web Application Firewall)**:
*   **Legitimate Access:** Visit the `application_gateway_public_ip`.
*   **SQLi Blocked:** Visit `http://<IP>/?id=1 OR 1=1` (Should see a 403 error).

---
**Prepared for Client Handover**
