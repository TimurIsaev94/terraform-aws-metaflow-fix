data "aws_caller_identity" "current" {}

# Use variable if provided, otherwise construct default dynamically
locals {
  # Use variable if set, otherwise fallback to current root
  effective_kms_admin_arns = (
    length(var.kms_admin_arns) > 0 ?
    var.kms_admin_arns :
    ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  )
}

data "aws_iam_policy_document" "kms_key_policy" {
  # Allow admin full control
  statement {
    sid    = "AllowKeyAdmins"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.effective_kms_admin_arns
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow S3 access for specified principals
  statement {
    sid    = "AllowKeyUsage"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.kms_usage_arns
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "s3" {
  description         = "This key is used to encrypt and decrypt the S3 bucket used to store blobs."
  enable_key_rotation = var.enable_key_rotation
  policy              = data.aws_iam_policy_document.kms_key_policy.json
  
  tags = var.standard_tags
}

resource "aws_kms_key" "rds" {
  description         = "This key is used to encrypt and decrypt the RDS database used to store flow execution data."
  enable_key_rotation = var.enable_key_rotation

  tags = var.standard_tags
}
