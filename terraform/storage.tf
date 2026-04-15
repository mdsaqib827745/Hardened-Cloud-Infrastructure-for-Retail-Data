# Storage Account for Encrypted Retail Files
resource "azurerm_storage_account" "retail_storage" {
  name                     = "stretailvault${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security Hardening
  public_network_access_enabled = true # Allowed, but restricted by network_rules
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # Force use of Entra ID / Managed Identity
  
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.backend.id]
    bypass                     = ["AzureServices"]
  }

  tags = {
    Environment = "Production"
    Project     = "RetailVault"
  }
}

# Container for the encrypted files
resource "azurerm_storage_container" "files" {
  name                  = "vault-items"
  storage_account_name  = azurerm_storage_account.retail_storage.name
  container_access_type = "private"
}

# Role Assignment for VM Managed Identity (Storage Blob Data Contributor)
resource "azurerm_role_assignment" "vm_storage_access" {
  scope                = azurerm_storage_account.retail_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vm_identity.principal_id
}
