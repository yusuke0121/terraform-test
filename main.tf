module "web_server" {
  source = "./apache_server"
  instance_type = "t2.micro"
}

output "public_dns" {
  value = module.web_server.public_dns
}