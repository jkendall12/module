module "eks" {
  source  = "https://github.com/jkendall12/module.git"
  version = "~> 18.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.22"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = "arn:aws:kms:us-east-1:737222778115:key/276c7768-711a-4284-8e00-6fac04c32542"
    resources        = ["secrets"]
  }]

  vpc_id     = "vpc-082e84a88dbab28d7"                                  #default VPC
  subnet_ids = ["subnet-069e93c6409967e4a", "subnet-07a53a2a0f1370883"] #default subnet

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t2.micro"
    update_launch_template_default_version = true
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "t2.micro"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t2.large"
            weighted_capacity = "2"
          },
        ]
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["t2.micro", "t2.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name       = "default"
      subnet_ids = aws_subnet.subnet-069e93c6409967e4a.id
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::737222778115:user/jermaine"
      username = "jermaine"
      groups   = ["admin"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::737222778115:user/kendall"
      username = "kendall"
      groups   = ["eks-admin"]
    },
    {
      userarn  = "arn:aws:iam::737222778115:user/woods-eks-readonly"
      username = "woods-eks-readonly"
      groups   = ["eks-read-only"]
    },
  ]

  aws_auth_accounts = [
    "737222778115",
    "888888888888",
  ]






  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}