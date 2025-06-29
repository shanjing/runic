output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "kubeconfig_command" {
  description = "Command to copy kubeconfig from the instance"
  value       = "scp -i ~/.ssh/id_rsa ubuntu@${aws_instance.this.public_ip}:/home/ubuntu/.kube/config ./kubeconfig"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.this.public_ip}"
}

output "kubernetes_api_url" {
  description = "Kubernetes API server URL"
  value       = "https://${aws_instance.this.public_ip}:6443"
}

output "bootstrap_monitoring_instructions" {
  description = "Instructions for monitoring the bootstrap process"
  value = <<-EOT
    🚀 BOOTSTRAP MONITORING INSTRUCTIONS:
    
    To monitor the Kubernetes cluster bootstrap process:
    
    ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.this.public_ip} "sudo tail -f /var/log/cloud-init-output.log"
    
    ⏱️  Expected completion time: 5-7 minutes
  EOT
}
