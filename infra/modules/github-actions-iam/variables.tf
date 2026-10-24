
variable "project" {
  description = "Project name"
  type        = string
  default     = "pharma"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_account_id" {
  description = "AWS account ID where the IAM resources will be created"
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the ECR permissions"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub organization or username that owns the repository"
  type        = string
  default     = "MoinRazvi"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "zenpharma"
}

variable "ecr_repository_prefix" {
  description = "Prefix used to scope ECR permissions to project repositories"
  type        = string
  default     = "pharma-"
}
