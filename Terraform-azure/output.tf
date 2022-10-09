output "public_ip_postgres" {
  value = azurerm_public_ip.public_ip_postgres.ip_address
}


output "postgres_ssh" {
  value     = tls_private_key.postgres_ssh.private_key_pem
  sensitive = true
}