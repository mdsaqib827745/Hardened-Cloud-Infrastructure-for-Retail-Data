# RetailVault: Secure Cloud Storage Project Plan & Report

This document outlines the design, security protocols, and final implementation of the **RetailVault** system. It serves as the primary technical plan for the secure handoff.

---

## 1. Project Objective
The goal of RetailVault is to provide a "Zero-Knowledge" file storage solution on Azure. 
*   **Privacy**: Neither the cloud provider nor the system administrator can read the user's files.
*   **Integrity**: Files are protected against tampering using authenticated encryption.
*   **Ease of Use**: A clean, web-based interface for non-technical users to encrypt/decrypt sensitive data.

---

## 2. Technical Architecture Plan

### **A. Infrastructure (Azure Cloud)**
We implemented a multi-tier hardened architecture using **Terraform (Infrastructure-as-Code)**:
*   **Web Tier**: Ubuntu Linux VM running Gunicorn and Nginx.
*   **Database Tier**: Azure SQL Database (Basic tier) using Private Endpoints.
*   **Storage Tier**: Azure Blob Storage Container (`vault-items`) with Managed Identity access.
*   **Security Tier**: Azure Application Gateway with **WAF_v2** (Web Application Firewall).

### **B. Network Security Plan**
*   **Inbound Access**: Restricted to Port 80 (HTTP) through the Application Gateway.
*   **Private Backend**: The Web VM has no public IP; it sits in a private subnet and communicates only with the App Gateway.
*   **WAF Rule Set**: OWASP 3.2 managed ruleset enabled in "Detection" mode to allow custom headers (like `Content-Disposition`) while monitoring for attacks.

---

## 3. Data Security & Encryption Plan

### **A. Key Derivation (Argon2id)**
Passwords are never stored. We use the **Argon2id** algorithm to derive a 256-bit AES key directly from the user's input:
*   **Memory cost**: 64 MB
*   **Iterations**: 3
*   **Salt**: Unique per file, stored alongside the encrypted data.

### **B. Encryption (AES-256-GCM)**
*   **Authenticated Encryption**: We use GCM (Galois/Counter Mode) to ensure that any modification to the encrypted file (even 1 bit) will cause the decryption to fail.
*   **Format**: The encrypted file contains the `Salt + IV + Tag + Ciphertext`.

---

## 4. Implementation Milestones

| Milestone | Description | Status |
| :--- | :--- | :--- |
| **I. Foundation** | Automated Infrastructure Provisioning via Terraform. | **Completed** |
| **II. Core Logic** | Implementation of AES-256-GCM and Argon2id in Python. | **Completed** |
| **III. Web App** | Flask-based UI for Encrypt/Decrypt workflows. | **Completed** |
| **IV. Security Fix** | **Fix V5**: Resolved UUID filename issue using RFC 8187. | **Completed** |
| **V. Handoff** | Preparation of Guides, ZIP, and Verification Suite. | **Completed** |

---

## 5. Deployment & Execution Plan
To deploy this project from zero:
1.  **Requirement Check**: Execute `INSTALL_REQS.md`.
2.  **Provisioning**: Run `terraform apply` to build the Azure environment.
3.  **Application Configuration**: Execute `deploy_fix_v5.sh` using the Azure `run-command` utility.
4.  **Verification**: Test using the **Client_Run_and_Test_Guide.md**.

---

## 6. Final Status & Conclusion
The project is currently in the **"Ready-to-Deploy"** state. 
*   **Source Code**: Fully hardened and tested.
*   **Infrastructure**: Verified and currently destroyed to prevent credit usage.
*   **Documentation**: Three separate guides created for the client.

**This plan confirms that the RetailVault project is complete and meets all high-security requirements.**
