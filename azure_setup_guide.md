# Azure Portal Setup & Budget Guide

Follow these steps in the Azure Portal to ensure your account is ready and protected from unexpected costs.

## 1. Verify Azure for Students
1. Go to the [Azure Portal](https://portal.azure.com).
2. Search for "Subscriptions" in the top bar.
3. You should see a subscription called **Azure for Students**.
4. Check your balance at [Microsoft Azure Sponsorships](https://www.microsoftazuresponsorships.com/Balance).

## 2. Create a Budget (Safety Net)
It is **CRITICAL** to set a budget alert so you don't exceed your $100 credit.
1. In the Azure Portal, search for **Cost Management + Billing**.
2. Select your subscription (**Azure for Students**).
3. On the left menu, click **Budgets**.
4. Click **+ Add**:
   - **Name:** `RetailProjectBudget`
   - **Reset Period:** Monthly
   - **Creation Date:** Today
   - **Amount:** `1.00` (USD)
5. Click **Next** to set alerts:
   - **Alert 1:** `80%` of budget (Actual) -> Send Email.
   - **Alert 2:** `100%` of budget (Actual) -> Send Email.
6. Click **Create**.

## 3. Register Resource Providers
Terraform needs these providers registered to create resources.
1. In your Subscription page, click **Resource providers** on the left.
2. Search for and ensure the following are **Registered**:
   - `Microsoft.Network`
   - `Microsoft.Compute`
   - `Microsoft.Sql`
   - `Microsoft.ManagedIdentity`
