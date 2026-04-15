# Screenshot Evidence Collection Guide

To complete your **Final Report (Deliverable 4)**, you need to capture screenshots from the Azure Portal to prove your security claims. Follow this guide to get exactly what your professors or clients need to see.

## 1. Security Functionality Evidence

### 1.1 WAF Blocking (SQL Injection/XSS)
*   **Action:** In your browser, go to `http://<Public-IP>/?id=1 OR 1=1`. 
*   **Screenshot:** The **403 Forbidden** error page on your screen.
*   **Caption:** "Figure 1: Application Gateway WAF successfully intercepting a SQL injection attack."

### 1.2 Network Security Group (NSG) Rules
*   **Portal Path:** Resource Group -> `nsg-backend-prod` -> Inbound security rules.
*   **Screenshot:** The table showing the `AllowHTTPFromAppGateway` rule and the `DenyAllInbound` rule.
*   **Caption:** "Figure 2: NSG ruleset ensuring only the Application Gateway can reach the backend server."

### 1.3 Network Isolation (Ping/SSH)
*   **Action:** Open a terminal and run `ping 10.0.2.4` and `ssh azureuser@10.0.2.4`.
*   **Screenshot:** The terminal showing the **Timeouts** or **Request Timed Out** messages.
*   **Caption:** "Figure 3: Proof of backend isolation from the public internet."

---

## 2. Encryption Evidence

### 2.1 SQL Database Encryption (TDE)
*   **Portal Path:** your SQL Database -> Transparent Data Encryption (left menu).
*   **Screenshot:** The page showing "Data encryption" is **Enabled**.
*   **Caption:** "Figure 4: SQL Transparent Data Encryption (TDE) status."

### 2.2 VM Disk Encryption
*   **Portal Path:** your VM (`vm-retail-web`) -> Disks -> click the OS Disk.
*   **Screenshot:** The "Encryption" field showing "Encryption at-rest with a platform-managed key".
*   **Caption:** "Figure 5: Web Server OS disk encryption verified."

---

## 3. Infrastructure Overview

### 3.1 Resource Group Cleanliness
*   **Portal Path:** your Resource Group (`rg-retail-hardened-prod`).
*   **Screenshot:** The list of all 15 resources (App Gateway, SQL, VM, NSG, etc.).
*   **Caption:** "Figure 6: Complete inventory of the Hardened Retail Infrastructure."

### 3.2 Application Gateway Health
*   **Portal Path:** your Application Gateway -> Backend health (left menu).
*   **Screenshot:** The status showing **Healthy** for your backend pool.
*   **Caption:** "Figure 7: Gateway health probe confirming connectivity to the backend web server."
