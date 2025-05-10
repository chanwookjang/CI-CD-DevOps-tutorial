output "rendered_user_data" {
  value = data.cloudinit_config.eks_node_user_data.rendered
}

output "base64_user_data" {
  value = base64encode(data.cloudinit_config.eks_node_user_data.rendered)
}