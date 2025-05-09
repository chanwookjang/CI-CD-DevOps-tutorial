variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-northeast-2"
}

variable "access_key" {
  type        = string
  description = "AWS Access Key"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "AWS Secret Key"
  sensitive   = true
}

variable "company_name" {
  type        = string
  description = "Company name"
  default     = "prodxcloud"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "custom_domain_4" {
  type        = string
  description = "Custom domain for environment 4"
  default     = "dev.prodxcloud.io"
}

variable "api_domain_name" {
  type        = string
  description = "API domain name"
  default     = "api.prodxcloud.io"
}

variable "backend_organization" {
  type        = string
  description = "Backend organization name"
  default     = "prodxcloud"
}

variable "tenant_state_bucket" {
  type        = string
  description = "S3 bucket for tenant state"
  default     = "prodxcloud-tenant-state-bucket"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "prodxcloud-tenant-cluster-prod"
}

variable "eks-cluster-autoscaler" {
  type        = string
  description = "EKS cluster autoscaler name"
  default     = "eks-cluster-autoscaler"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.31"
}

variable "tenant_vpc" {
  type        = string
  description = "Tenant VPC name"
  default     = "prodxcloud_tenant_vpc_eks"
}