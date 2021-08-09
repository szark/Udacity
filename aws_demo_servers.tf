resource "aws_iam_role" "roec2" {
    path                = "/"
    assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "role_attach" {
    role = aws_iam_role.roec2.id 
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
    role = aws_iam_role.roec2.id
}

resource "aws_security_group" "LBSecGroup" {
    name        = "LBSecGroup"
    description = "Allow http access to loadbalancers"
    vpc_id      = aws_vpc.mydemo.id 

    ingress = [
        {
            description         = "Http from all addresses"
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            cidr_blocks         = ["0.0.0.0/0"]
            ipv6_cidr_blocks    = ["::/0"]
            prefix_list_ids     = []
            security_groups     = []
            self                = false
        }
    ]

    egress = [
        {
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            description         = ""
            cidr_blocks         = ["0.0.0.0/0"]
            ipv6_cidr_blocks    = ["::/0"]
            prefix_list_ids     = []
            security_groups     = []
            self                = false
        }
    ]
}

resource "aws_security_group" "WebServer" {
    name        = "WebServer"
    description = "Allow http access to servers"
    vpc_id      = aws_vpc.mydemo.id 

    ingress = [
        {
            description         = "Http from all addresses"
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            cidr_blocks         = ["0.0.0.0/0"]
            ipv6_cidr_blocks    = ["::/0"]
            security_groups     = []
            prefix_list_ids     = []
            self                = false
        }
    ]

    egress = [
        {
            from_port           = 0
            to_port             = 65535
            protocol            = "tcp"
            description         = ""
            cidr_blocks         = ["0.0.0.0/0"]
            ipv6_cidr_blocks    = ["::/0"]
            prefix_list_ids     = []
            security_groups     = []
            self                = false
        }
    ]
}

resource "aws_launch_configuration" "WebAppLaunch" {
    name                    = "WebAppLaunch"
    user_data_base64        = filebase64("./setup.sh")
    image_id                = "ami-0cc158853935719b7"
    iam_instance_profile    = aws_iam_instance_profile.iam_instance_profile.id
    security_groups         = [aws_security_group.WebServer.id]
    instance_type           = "t2.micro"
    
}

resource "aws_autoscaling_group" "asgroup" {
    name                    = "asgroup"
    vpc_zone_identifier     = [aws_subnet.private_cidr1.id, aws_subnet.private_cidr2.id]
    min_size                = 2
    max_size                = 4
    target_group_arns       = [aws_alb_target_group.WebAppTargetGroup.arn]
    launch_configuration    = "WebAppLaunch"

    depends_on = [
      aws_launch_configuration.WebAppLaunch
    ]
}

resource "aws_alb_target_group" "WebAppTargetGroup" {
    name        = "WebAppTargetGroup"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = aws_vpc.mydemo.id
    health_check {
        enabled             = true
        interval            = 10
        path                = "/"
        timeout             = 8
        healthy_threshold   = 2
        unhealthy_threshold = 5
    }
}

resource "aws_autoscaling_policy" "cpu" {
    name = "auto-scaling-policy-asp"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 40.0
    }
    autoscaling_group_name   = aws_autoscaling_group.asgroup.name
    policy_type              = "TargetTrackingScaling"
    depends_on = [
      aws_autoscaling_group.asgroup
    ]
}

resource "aws_autoscaling_policy" "req" {
    name = "auto-scaling-policy-asp"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type  = "ALBRequestCountPerTarget"
            resource_label          = join("/", [ "${aws_lb.webapplb.arn_suffix}", "${aws_alb_target_group.WebAppTargetGroup.arn_suffix}"])
        }
        target_value = 4
    }
    autoscaling_group_name  = aws_autoscaling_group.asgroup.name
    policy_type             = "TargetTrackingScaling"           
    depends_on = [
      aws_autoscaling_group.asgroup
    ]
}

resource "aws_lb" "webapplb" {
    subnets         = [aws_subnet.public_cidr1.id, aws_subnet.public_cidr2.id]
    security_groups = [aws_security_group.LBSecGroup.id]
    depends_on = [
      aws_security_group.LBSecGroup
    ]
}

resource "aws_lb_listener" "AlbListener" {
    load_balancer_arn   = aws_lb.webapplb.arn
    port                = 80
    protocol            = "HTTP"

    default_action {
        type                = "forward"
        target_group_arn    = aws_alb_target_group.WebAppTargetGroup.arn
    }
}

resource "aws_lb_listener_rule" "ALBListenerRule" {
    listener_arn    = aws_lb_listener.AlbListener.arn
    priority        = 1
    action {
        type                = "forward"
        target_group_arn    = aws_alb_target_group.WebAppTargetGroup.arn
    }
    condition {
        path_pattern {
            values = ["/"]
        }
    }
}