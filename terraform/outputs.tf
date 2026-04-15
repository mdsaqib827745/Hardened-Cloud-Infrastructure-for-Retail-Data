output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_ip.ip_address
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm_nic.private_ip_address
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}
