variable "db_instance_type" {
  type        = string
  description = "RDS instance type to launch for PostgresQL database."
  default     = "db.t3.small"
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "17"
}

variable "db_name" {
  type        = string
  description = "Name of PostgresQL database for Metaflow service."
  default     = "metaflow"
}

variable "force_destroy_s3_bucket" {
  type        = bool
  description = "Empty S3 bucket before destroying via terraform destroy"
  default     = false
}
variable "db_username" {
  type        = string
  description = "PostgresQL username; defaults to 'metaflow'"
  default     = "metaflow"
}

variable "metadata_service_security_group_id" {
  type        = string
  description = "The security group ID used by the MetaData service. We'll grant this access to our DB."
}

variable "metaflow_vpc_id" {
  type        = string
  description = "ID of the Metaflow VPC this SageMaker notebook instance is to be deployed in"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix given to all AWS resources to differentiate between applications"
}

variable "resource_suffix" {
  type        = string
  description = "Suffix given to all AWS resources to differentiate between environment and workspace"
}

variable "standard_tags" {
  type        = map(string)
  description = "The standard tags to apply to every AWS resource."
}

variable "subnet1_id" {
  type        = string
  description = "First subnet used for availability zone redundancy"
}

variable "subnet2_id" {
  type        = string
  description = "Second subnet used for availability zone redundancy"
}

variable "enable_key_rotation" {
  type        = bool
  description = "Enable key rotation for KMS keys"
  default     = false
}

variable "kms_admin_arns" {
  description = "Principals allowed to administer the KMS key"
  type        = list(string)
  default     = []
}

variable "kms_usage_arns" {
  description = "Principals allowed to use (encrypt/decrypt) the KMS key"
  type        = list(string)
  default     = []
}

variable "ecs_s3_access_iam_role" {
  description = "ECS S3 role used by metaflow to use (encrypt/decrypt) the S3 KMS key"
  type        = string
}