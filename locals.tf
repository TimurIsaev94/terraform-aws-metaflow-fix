module "metaflow-common" {
  source = "./modules/common"
}

locals {
  resource_prefix = length(var.resource_prefix) > 0 ? "${var.resource_prefix}-" : ""
  resource_suffix = length(var.resource_suffix) > 0 ? "-${var.resource_suffix}" : ""

  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id

  batch_s3_task_role_name   = "${local.resource_prefix}BatchS3TaskRole${local.resource_suffix}"
  metaflow_batch_image_name = "${local.resource_prefix}batch${local.resource_suffix}"
  metadata_service_container_image = (
    var.metadata_service_container_image == "" ?
    module.metaflow-common.default_metadata_service_container_image :
    var.metadata_service_container_image
  )
  ui_static_container_image = (
    var.ui_static_container_image == "" ?
    module.metaflow-common.default_ui_static_container_image :
    var.ui_static_container_image
  )

  # RDS PostgreSQL >= 15 requires SSL by default
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html#PostgreSQL.Concepts.General.SSL.Requiring
  database_ssl_mode = tonumber(split(".", var.db_engine_version)[0]) >= 15 ? "prefer" : "disable"
}
