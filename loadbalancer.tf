# loadbalancer.tf

resource "aws_lb" "main" {
  name            = "Webapp-lb"
  load_balancer_type = "application"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}



resource "aws_lb_target_group" "web_app" {
  name        = "App-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  #proxy_protocol_v2 = true
  
  health_check {
    healthy_threshold   = "3"
    interval            = "10"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }
}

#resource "aws_launch_configuration" "web_app" {
  #name_prefix          = "web_app"
  #image_id      = data.aws_ami.ubuntu.id
  #instance_type = "t3.micro"
  #associate_public_ip_address = true
  #user_data       = file("user_data.sh")
  #security_groups = [aws_security_group.lb.id]
  
  #lifecycle {
    #create_before_destroy = true
  #}
 #}



# Redirect all traffic from the ALB to the target group
resource "aws_lb_listener" "port_listener" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web_app.id
    type             = "forward"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web_app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  #security_groups = [aws_security_group.instance.id]
  user_data       = file ("user_data.sh")

  tags = {
    Name = "HelloDevOps"
  }
}

#resource "aws_lb_target_group_attachment" "web_app" {
  #target_group_arn = aws_lb_target_group.web_app.arn
  #target_id        = aws_instance.web_app.id
  #target_id        = data.aws_ami.ubuntu.id
  #port             = 80
#}
  