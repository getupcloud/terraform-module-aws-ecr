locals {
  name_prefix = substr("eks-ecr-${var.cluster_name}", 0, 32)
}

data "aws_iam_policy_document" "ecr" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetRegistryPolicy",
      "ecr:DescribeImageScanFindings",
      "sts:GetFederationToken",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRegistry",
      "ecr:GetAuthorizationToken",
      "sts:GetAccessKeyInfo",
      "ecr:ListTagsForResource",
      "ecr:ListImages",
      "sts:GetSessionToken",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "sts:GetCallerIdentity",
      "sts:AssumeRoleWithWebIdentity",
      "sts:GetServiceBearerToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr" {
  name_prefix = local.name_prefix
  description = "ECR policy for EKS cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.ecr.json
}

module "irsa_ecr" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.2"

  create_role                   = true
  role_name_prefix              = local.name_prefix
  provider_url                  = var.cluster_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.ecr.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
}
