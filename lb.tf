resource "aws_alb_listener_rule" "lb-rule" {
  count = var.ENV == "dev" ? 1 : 0
  listener_arn = data.terraform_remote_state.frontend.outputs.BACKEND_LISTENER_ARN_DEV
  priority     = var.lb_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.ENV}.kesavakadiyala.tech"]
    }
  }
}

resource "aws_alb_listener_rule" "lb-rule" {
  count = var.ENV == "prod" ? 1 : 0
  listener_arn = data.terraform_remote_state.frontend.outputs.BACKEND_LISTENER_ARN_PROD
  priority     = var.lb_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.ENV}.kesavakadiyala.tech"]
    }
  }
}