# Project Proposal: Layered Security for Retail Data (VNet Hardening + Secure Storage)

## 1. Problem Statement
Retail organizations handle sensitive customer data, including Personal Identifiable Information (PII) and Transactional Data. A single layer of security is no longer sufficient; if an infrastructure breach occurs, the underlying data remains vulnerable. There is a critical need for a **Layered Security (Defense-in-Depth)** model that combines a hardened cloud perimeter with mathematically strong data-at-rest encryption.

## 2. Objective
The objective of this project is to implement two integrated security layers on Microsoft Azure:
1. **Infrastructure Layer:** A "fortress" environment using Terraform, featuring an Azure WAF-protected Application Gateway, isolated private subnets, and zero-trust NSG policies.
2. **Data Layer:** A high-performance Python encryption utility using the **AES-256-GCM** cipher and **Argon2id** (memory-hard) key derivation to protect sensitive retail files even if the server is compromised.

## 3. Technical Stack
- **Cloud Infrastructure:** Microsoft Azure (VNet, App Gateway / WAF, NSGs, Managed Identities).
- **Automation:** Terraform (IaC).
- **Cryptography:** Python 3 with the `cryptography` and `argon2-cffi` libraries.
- **Algorithms:** AES-256-GCM, Argon2id (64MB memory, 3 iterations).

## 4. Key Security Controls
- **WAF Prevention Mode:** Pre-configured OWASP 3.2 rules to block SQLi and XSS at the edge.
- **Network Segmentation:** Strict air-gapping of the backend compute subnet from the public internet.
- **Authenticated Encryption:** Using GCM mode to ensure both data confidentiality and integrity (tamper detection).
- **Memory-Hard KDF:** Argon2id prevents brute-force and GPU-based password cracking.
- **Compliance:** Aligns with PCI DSS 3.4 and GDPR Article 32.
