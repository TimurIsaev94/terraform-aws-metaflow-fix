module "metaflow-datastore" {
  source = "./modules/datastore"

  force_destroy_s3_bucket = var.force_destroy_s3_bucket
  enable_key_rotation     = var.enable_key_rotation

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  metadata_service_security_group_id = module.metaflow-metadata-service.metadata_service_security_group_id
  metaflow_vpc_id                    = var.vpc_id
  subnet1_id                         = var.subnet1_id
  subnet2_id                         = var.subnet2_id

  db_instance_type  = var.db_instance_type
  db_engine_version = var.db_engine_version

  standard_tags = var.tags
  kms_usage_arns = var.kms_usage_arns
  ecs_s3_access_iam_role = aws_iam_role.batch_s3_task_role.arn
}

module "metaflow-metadata-service" {
  source = "./modules/metadata-service"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  access_list_cidr_blocks          = var.access_list_cidr_blocks
  database_name                    = module.metaflow-datastore.database_name
  database_password                = module.metaflow-datastore.database_password
  database_username                = module.metaflow-datastore.database_username
  database_ssl_mode                = local.database_ssl_mode
  db_migrate_lambda_zip_file       = var.db_migrate_lambda_zip_file
  datastore_s3_bucket_kms_key_arn  = module.metaflow-datastore.datastore_s3_bucket_kms_key_arn
  enable_api_basic_auth            = var.metadata_service_enable_api_basic_auth
  enable_api_gateway               = var.metadata_service_enable_api_gateway
  fargate_execution_role_arn       = module.metaflow-computation.ecs_execution_role_arn
  iam_partition                    = var.iam_partition
  metadata_service_container_image = local.metadata_service_container_image
  metaflow_vpc_id                  = var.vpc_id
  rds_master_instance_endpoint     = module.metaflow-datastore.rds_master_instance_endpoint
  s3_bucket_arn                    = module.metaflow-datastore.s3_bucket_arn
  subnet1_id                       = var.subnet1_id
  subnet2_id                       = var.subnet2_id
  vpc_cidr_blocks                  = var.vpc_cidr_blocks
  with_public_ip                   = var.with_public_ip

  standard_tags = var.tags
}

module "metaflow-ui" {
  source = "./modules/ui"
  count  = var.ui_certificate_arn == "" ? 0 : 1

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  database_name                   = module.metaflow-datastore.database_name
  database_password               = module.metaflow-datastore.database_password
  database_username               = module.metaflow-datastore.database_username
  datastore_s3_bucket_kms_key_arn = module.metaflow-datastore.datastore_s3_bucket_kms_key_arn
  fargate_execution_role_arn      = module.metaflow-computation.ecs_execution_role_arn
  iam_partition                   = var.iam_partition
  metaflow_vpc_id                 = var.vpc_id
  rds_master_instance_endpoint    = module.metaflow-datastore.rds_master_instance_endpoint
  s3_bucket_arn                   = module.metaflow-datastore.s3_bucket_arn
  subnet1_id                      = var.subnet1_id
  subnet2_id                      = var.subnet2_id
  ui_backend_container_image      = local.metadata_service_container_image
  ui_static_container_image       = local.ui_static_container_image
  alb_internal                    = var.ui_alb_internal
  ui_allow_list                   = var.ui_allow_list

  METAFLOW_DATASTORE_SYSROOT_S3      = module.metaflow-datastore.METAFLOW_DATASTORE_SYSROOT_S3
  certificate_arn                    = var.ui_certificate_arn
  metadata_service_security_group_id = module.metaflow-metadata-service.metadata_service_security_group_id

  extra_ui_static_env_vars  = var.extra_ui_static_env_vars
  extra_ui_backend_env_vars = var.extra_ui_backend_env_vars
  standard_tags             = var.tags
}

module "metaflow-computation" {
  source = "./modules/computation"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  batch_type                                  = var.batch_type
  compute_environment_desired_vcpus           = var.compute_environment_desired_vcpus
  compute_environment_instance_types          = var.compute_environment_instance_types
  compute_environment_max_vcpus               = var.compute_environment_max_vcpus
  compute_environment_min_vcpus               = var.compute_environment_min_vcpus
  compute_environment_egress_cidr_blocks      = var.compute_environment_egress_cidr_blocks
  iam_partition                               = var.iam_partition
  metaflow_vpc_id                             = var.vpc_id
  subnet1_id                                  = var.subnet1_id
  subnet2_id                                  = var.subnet2_id
  launch_template_http_endpoint               = var.launch_template_http_endpoint
  launch_template_http_tokens                 = var.launch_template_http_tokens
  launch_template_http_put_response_hop_limit = var.launch_template_http_put_response_hop_limit

  standard_tags = var.tags
}

module "metaflow-step-functions" {
  source = "./modules/step-functions"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  active              = var.enable_step_functions
  batch_job_queue_arn = module.metaflow-computation.METAFLOW_BATCH_JOB_QUEUE
  iam_partition       = var.iam_partition
  s3_bucket_arn       = module.metaflow-datastore.s3_bucket_arn
  s3_bucket_kms_arn   = module.metaflow-datastore.datastore_s3_bucket_kms_key_arn

  standard_tags = var.tags
}

####
#
####

locals {
  metaflow_profile_json = jsonencode(
    merge(
      var.enable_custom_batch_container_registry ? {
        "METAFLOW_BATCH_CONTAINER_REGISTRY" = element(split("/", aws_ecr_repository.metaflow_batch_image[0].repository_url), 0),
        "METAFLOW_BATCH_CONTAINER_IMAGE"    = element(split("/", aws_ecr_repository.metaflow_batch_image[0].repository_url), 1)
      } : {},
      var.metadata_service_enable_api_basic_auth ? {
        "METAFLOW_SERVICE_AUTH_KEY" = "${module.metaflow-metadata-service.api_key_value}"
      } : {},
      var.batch_type == "fargate" ? {
        "METAFLOW_ECS_FARGATE_EXECUTION_ROLE" = module.metaflow-computation.ecs_execution_role_arn
      } : {},
      {
        "METAFLOW_DATASTORE_SYSROOT_S3"       = module.metaflow-datastore.METAFLOW_DATASTORE_SYSROOT_S3,
        "METAFLOW_DATATOOLS_S3ROOT"           = module.metaflow-datastore.METAFLOW_DATATOOLS_S3ROOT,
        "METAFLOW_BATCH_JOB_QUEUE"            = module.metaflow-computation.METAFLOW_BATCH_JOB_QUEUE,
        "METAFLOW_ECS_S3_ACCESS_IAM_ROLE"     = aws_iam_role.batch_s3_task_role.arn,
        "METAFLOW_SERVICE_URL"                = module.metaflow-metadata-service.METAFLOW_SERVICE_URL,
        "METAFLOW_SERVICE_INTERNAL_URL"       = module.metaflow-metadata-service.METAFLOW_SERVICE_INTERNAL_URL,
        "METAFLOW_SFN_IAM_ROLE"               = module.metaflow-step-functions.metaflow_step_functions_role_arn,
        "METAFLOW_SFN_STATE_MACHINE_PREFIX"   = replace("${local.resource_prefix}${local.resource_suffix}", "--", "-"),
        "METAFLOW_EVENTS_SFN_ACCESS_IAM_ROLE" = module.metaflow-step-functions.metaflow_eventbridge_role_arn,
        "METAFLOW_SFN_DYNAMO_DB_TABLE"        = module.metaflow-step-functions.metaflow_step_functions_dynamodb_table_name,
        "METAFLOW_DEFAULT_DATASTORE"          = "s3",
        "METAFLOW_DEFAULT_METADATA"           = "service"
      }
    )
  )
}

resource "aws_secretsmanager_secret" "metaflow_config" {
  name = "metaflow-config"
}

resource "aws_secretsmanager_secret_version" "metaflow_config_value" {
  secret_id     = aws_secretsmanager_secret.metaflow_config.id
  secret_string = local.metaflow_profile_json
}

####
# END
#### 
