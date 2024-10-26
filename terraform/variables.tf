variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"  # Région mise à jour
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "mykubernetes"  # Nom du cluster mis à jour
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default     = ["subnet-0946253780c6f471e", "subnet-061b8dfa84c05026a"]  # Valeurs par défaut
}

variable "role_arn" {
  description = "IAM Role ARN for EKS"
  type        = string
  default     = "arn:aws:iam::985365036259:role/LabRole"  # Valeur par défaut
}