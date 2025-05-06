#fsdfsd
/* resource "aws_s3_bucket" "this" {
  bucket        = local.s3_bucket_name
  acl           = "private"
  force_destroy = var.force_destroy_s3_bucket
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    var.standard_tags,
    {
      Metaflow = "true"
    }
  )
} */

resource "aws_s3_bucket" "metaflow_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = var.force_destroy_s3_bucket

  tags = merge(
    var.standard_tags,
    {
      Metaflow = "true"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "metaflow_bucket_ownership" {
  bucket = aws_s3_bucket.metaflow_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "metaflow_bucket_encryption" {
  bucket = aws_s3_bucket.metaflow_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "metaflow_bucket_public_access_block" {
  bucket = aws_s3_bucket.metaflow_bucket.id

  block_public_policy     = true
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
