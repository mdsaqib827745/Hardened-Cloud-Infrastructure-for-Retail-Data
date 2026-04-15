# SSH Key Generation Guide

The Terraform code for your Virtual Machine requires an SSH public key. Follow these steps to generate one on your Windows machine.

## 1. Check for Existing Keys
1. Open PowerShell.
2. Type: `ls ~/.ssh`
3. If you see `id_rsa` and `id_rsa.pub`, you already have a key! You can skip Step 2.

## 2. Generate a New Key
1. In PowerShell, type:
   ```powershell
   ssh-keygen -t rsa -b 4096
   ```
2. Press **Enter** to accept the default file location (`C:\Users\YourName\.ssh\id_rsa`).
3. (Optional) Enter a passphrase or just press **Enter** twice for no passphrase.

## 3. Verify the Key
1. Verify the files exist:
   ```powershell
   ls ~/.ssh/id_rsa.pub
   ```
2. The Terraform code is pre-configured to look for the key at `~/.ssh/id_rsa.pub`.
