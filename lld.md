# Low-Level Design (LLD): Technical Specifications

## 1. Network Configuration
| Resource | Attribute | Value |
| :--- | :--- | :--- |
| VNet | Address Space | `10.0.0.0/16` |
| Frontend Subnet | Address Range | `10.0.1.0/24` |
| Backend Subnet | Address Range | `10.0.2.0/24` |
| Network Security Group | Applied To | Backend Subnet |

## 2. Compute - Ubuntu VM
- **VM Size:** `Standard_B2s_v2` (2 vCPU, 4 GiB RAM).
- **OS Image:** `Ubuntu Server 22.04 LTS`.
- **Identity:** User-Assigned Managed Identity (`id-retail-web`).
- **Software:** Python 3, `cryptography` library, `argon2-cffi` library.

## 3. Application Gateway & WAF
- **Tier:** `WAF_v2`.
- **Frontend Port:** `443` (HTTPS).
- **WAF Mode:** `Prevention`.
- **Policy Rule Sets:** `OWASP 3.2`.

## 4. Secure Storage Utility (Specifications)
| Param | Requirement | Value / Specification |
| :--- | :--- | :--- |
| **Logic** | Language | Python 3 |
| **KDF** | Algorithm | **Argon2id** |
| **KDF** | Memory | 64 MiB (65536 KB) |
| **KDF** | Iterations | 3 |
| **KDF** | Parallelism | 1 |
| **Cipher** | Algorithm | **AES-256-GCM** |
| **Nonce** | Length | 12 Bytes (Random) |
| **Output** | Binary Format | `[salt(16)][nonce(12)][tag(16)][ciphertext]` |

## 5. Security Group (NSG) Rules
### Inbound Rules (Backend Subnet)
| Priority | Name | Port | Protocol | Source | Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 100 | AllowAppGWInbound | 80, 443 | TCP | `10.0.1.0/24` | Allow |
| 65000 | DenyAllInbound | Any | Any | Any | Deny |
