provider "aws" {
  region = var.aws_region
}

resource "aws_eks_cluster" "my_cluster" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

resource "aws_security_group_rule" "allow_all_inbound_on_8083" {
  type              = "ingress"
  from_port         = 8083
  to_port           = 8083
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.my_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "allow_all_inbound_on_30000" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.my_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = var.role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [aws_eks_cluster.my_cluster]
}
