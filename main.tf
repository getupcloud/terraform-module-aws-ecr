locals {
  name               = "ecr"
  name_prefix        = substr("${var.customer_name}-${var.cluster_name}-${local.name}", 0, 32)
  use_oidc           = var.cluster_oidc_issuer_url != ""
  use_iam            = var.cluster_oidc_issuer_url == ""
  ecr_managed_policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

### AUTH BY IRSA

module "this" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.2"

  count                         = local.use_oidc ? 1 : 0
  create_role                   = true
  role_name_prefix              = local.name_prefix
  provider_url                  = var.cluster_oidc_issuer_url
  role_policy_arns              = [local.ecr_managed_policy]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
  tags                          = var.tags
}

### AUTH BY SECRET

resource "aws_iam_user" "this" {
  count = local.use_iam ? 1 : 0
  name  = local.name_prefix
}

resource "aws_iam_access_key" "this" {
  count = local.use_iam ? 1 : 0
  user  = aws_iam_user.this[0].name
}

resource "aws_iam_user_policy_attachment" "this" {
  count = local.use_iam ? 1 : 0
  user  = aws_iam_user.this[0].name

  policy_arn = local.ecr_managed_policy
}
