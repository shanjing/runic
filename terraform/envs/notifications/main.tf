terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use for notifications infrastructure"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "Region for SNS/Billing resources (Budgets is global but requires a region context)"
  type        = string
  default     = "us-east-1"
}

variable "billing_phone_number" {
  description = "E.164 formatted phone number (e.g. +15558675309) to receive billing alerts"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly spend limit in USD that should trigger alerts"
  type        = number
  default     = 30
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_sns_topic" "billing_alerts" {
  name = "trevoux-billing-alerts"

  tags = {
    Project = "trevoux"
    Purpose = "billing-alerts"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic_policy" "allow_budgets" {
  arn = aws_sns_topic.billing_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowBudgetsPublish"
        Effect    = "Allow"
        Principal = { Service = "budgets.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.billing_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "sms"
  endpoint  = var.billing_phone_number
}

resource "aws_budgets_budget" "monthly" {
  name         = "trevoux-monthly-billing"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_types {
    include_tax          = true
    include_subscription = true
    include_refund       = false
    include_credit       = false
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.billing_alerts.arn]
  }
}
