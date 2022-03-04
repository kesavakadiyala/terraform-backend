resource "aws_alb_listener_rule" "lb-rule" {
  listener_arn = data.terraform_remote_state.frontend.outputs.BACKEND_LISTENER_ARN
  priority     = var.lb_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.ENV}.devopsb51.tk"]
    }
  }
}