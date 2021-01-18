output "website_dns" {
  value       = module.web-server-alb.this_lb_dns_name
  description = "The endpoint of ALB that you need to connect to."
}
