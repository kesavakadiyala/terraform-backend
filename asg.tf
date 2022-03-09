resource "aws_launch_template" "launch_template" {
  count = length(var.availability-zones)
  name = "${var.component}-template-${var.availability-zones[count.index]}"
  image_id = data.aws_ami.ami.id
  instance_type = var.INSTANCE_TYPE
  key_name = var.KEYPAIR_NAME
  vpc_security_group_ids = [aws_security_group.allow-template-instance.id]
  monitoring {
    enabled = true
  }
  placement {
    availability_zone = var.availability-zones[count.index]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.component}-${var.ENV}-template-${var.availability-zones[count.index]}-${count.index}",
      Zone = var.availability-zones[count.index]
    }
  }
}

resource "aws_lb_target_group" "lb-target-group" {
  name     = "${var.component}-lb-target-group"
  port     = 8000
  protocol = "HTTP"
  health_check {
    path   = "/health"
  }
  vpc_id   = data.terraform_remote_state.vpc.outputs.VPC_ID
}

resource "aws_autoscaling_group" "asg" {
  count                     = length(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET)
  name                      = "${var.component}-asg-${var.availability-zones[count.index]}"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = [element(data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET, count.index)]
  target_group_arns         = [aws_lb_target_group.lb-target-group.arn]
  launch_template {
    id                      = element(aws_launch_template.launch_template.*.id, count.index)
    version                 = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.component}-asg-${var.availability-zones[count.index]}"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  count = length(aws_autoscaling_group.asg)
  name                   = "scaleup"
  adjustment_type        = "PercentChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup                = "300"
  autoscaling_group_name = aws_autoscaling_group.asg[count.index].name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}