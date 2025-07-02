locals {
  prefix = "${var.project}-${var.env}"  # re‑used in naming
}

# 1) ECS cluster (one per env)
resource "aws_ecs_cluster" "this" {
  name = "${local.prefix}-cluster"
  tags = var.tags
}

# 2) CloudWatch log group (/{prefix}/{env})
# Commented due to user not being authorized to perform logs:ListTagsForResource
# resource "aws_cloudwatch_log_group" "app" {
#   name              = "/${var.log_group_prefix}/${var.project}/${var.env}"
#   retention_in_days = var.log_retention
#   tags              = var.tags
# }

# 3) IAM – execution role

data "aws_iam_policy_document" "exec_assume" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
        type = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.prefix}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "exec_base" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4) IAM – task role (no permissions by default)

data "aws_iam_policy_document" "task_assume" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
        type = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "${local.prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}

# 5) Application security group
resource "aws_security_group" "app" {
  name_prefix = "${local.prefix}-sg-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [var.alb_sg_id]
  }

  egress {
    description = "All egress"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 6) Task definition – single‑container Fargate task
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.prefix}-task"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = var.image_uri

    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs",
      options   = {
#  Commented due to user not being authorized to perform logs:ListTagsForResource
#  awslogs-group         = aws_cloudwatch_log_group.app.name,
        awslogs-group         = "/emilian-applogs/${var.project}/${var.env}" # hard-coded
        awslogs-region        = "eu-central-1",
        awslogs-stream-prefix = "app"
      }
    }

    environment = [
      {
        name = "APP_VERSION",
        value = var.image_tag
      },
      {
        name = "LOG_LEVEL",
        value = var.log_level
      },
      {
        name = "GREETING_MESSAGE",
        value = var.greeting_message
      }
    ]
  }])
}

# 7) ECS service (rolling updates, circuit‑breaker off by default)
resource "aws_ecs_service" "this" {
  name            = "${local.prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.app.id]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = 3000
  }

  deployment_controller { type = "ECS" }

  lifecycle {
    ignore_changes = [desired_count]  # allows manual scaling via console/ASG
  }

  tags = var.tags
}
