variable "region" {
  type = string
  description = "Enter Region:"
}
variable "a_key" {
  type        = string
  description = "Enter Access Key:"
}
variable "s_key" {
  type        = string
  description = "Enter Secret Key:"
}
variable "key_name" {
  type        = string
  description = "Enter SSH Key Name:"

}

variable "db_user" {
  type        = string
  description = "Enter DB User:"
}

variable "db_name" {
  type        = string
  description = "Enter DB Name:"
}

variable "db_pass" {
  type        = string
  description = "Enter DB Password:"
}

variable "ami" {
  type        = string
  description = "Enter AMI ID:"
}

variable "bucket" {
  type        = string
  description = "Enter Bucket Name:"
}

provider "aws" {
  region = var.region
}



# Create a VPC
resource "aws_vpc" "aws_demo" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = false
  tags = {
      Name = "csyee6225"
      Tag2 = "new tag"
  }
}

# Create a Subnet
resource "aws_subnet" "subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = "${aws_vpc.aws_demo.id}"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "csyee6225-subnet"
  }
}

resource "aws_subnet" "subnet1" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = "${aws_vpc.aws_demo.id}"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "csyee6225-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  cidr_block = "10.0.3.0/24"
  vpc_id     = "${aws_vpc.aws_demo.id}"
  availability_zone = "${var.region}c"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "csyee6225-subnet2"
  }
}

# Create a internt gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.aws_demo.id}"

  tags = {
    Name = "csyee6225-gateway"
  }
}

#Create a route table
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.aws_demo.id}"

  # route {
  #   cidr_block = "${aws_subnet.subnet.cidr_block}"
  #   gateway_id = "${aws_internet_gateway.gateway.id}"
  # }

  # route {
  #   cidr_block = "${aws_subnet.subnet1.cidr_block}"
  #   gateway_id = "${aws_internet_gateway.gateway.id}"
  # }

  # route {
  #   cidr_block = "${aws_subnet.subnet2.cidr_block}"
  #   gateway_id = "${aws_internet_gateway.gateway.id}"
  # }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }


  tags = {
    Name = "csyee6225-route"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r.id
}


resource "aws_security_group" "my_sg" {
  name        = "Demo SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.aws_demo.id

  # ingress {
  #   description = "SSH"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    
  }

  # ingress {
  #   description = "WebApp"
  #   from_port   = 8080
  #   to_port     = 8080
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Application"
  }
}

resource "aws_security_group" "mydb_sg" {
  name        = "allow_db"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.aws_demo.id

  ingress {
    description     = "DB Connection"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.my_sg.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database"
  }
}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 30
}

resource "aws_s3_bucket" "b" {
  bucket        = var.bucket
  force_destroy = true
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  lifecycle_rule {
    prefix  = "config/"
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

  }
  tags = {
    Name        = "My_bucket"
    Environment = "Dev"
  }
}

resource "aws_db_subnet_group" "db_group" {
  name       = "db_group"
  subnet_ids = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]

  tags = {
    Name = "My_DB_subnet_group"
  }
}

resource "aws_dynamodb_table" "dbTable" {
  name = "csye6225"
  hash_key = "id"
  billing_mode = "PROVISIONED"
  write_capacity = 5
  read_capacity = 5
  attribute {
    name = "id"
    type = "S"
  }

}

resource "aws_db_instance" "default" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "11"
  instance_class    = "db.t3.micro"
  name              = var.db_name
  username          = var.db_user
  password          = var.db_pass
  identifier        = "csye6225-su2020"
  db_subnet_group_name = aws_db_subnet_group.db_group.name
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.mydb_sg.id]
  parameter_group_name = aws_db_parameter_group.parameter-group.name
  storage_encrypted    = true

}





resource "aws_iam_role" "EC2_Role" {
  name = "EC2-CSYE6225"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    name = "EC2-CSYE6225"
  }
}

resource "aws_iam_policy" "mypolicy" {
  name   = "WebAppS3"
  # role   = aws_iam_role.EC2Role.id
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Action": [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ],
		"Resource": [
			"arn:aws:s3:::web.abhi.thakkar",
			"arn:aws:s3:::web.abhi.thakkar/*"
		]
	}]
}
  EOF

}

resource "aws_iam_role_policy_attachment" "attach-policy" {
  role       = "${aws_iam_role.EC2_Role.name}"
  policy_arn = "${aws_iam_policy.mypolicy.arn}"
}

resource "aws_iam_instance_profile" "EC2Profile" {
  name = "EC2-CSYE6225"
  role = "${aws_iam_role.EC2_Role.name}"
}

resource "aws_iam_role_policy_attachment" "cloud-watch-policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = "${aws_iam_role.EC2_Role.name}"
}

# #create Instance
# resource "aws_instance" "web" {
#   ami                    = var.ami
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.subnet2.id
#   iam_instance_profile   = "EC2-CSYE6225"
#   key_name = var.key_name
#   vpc_security_group_ids = [aws_security_group.my_sg.id]
#   root_block_device {
#     volume_size = 20
#     volume_type = "gp2"
#   }
#   user_data = "${data.template_file.data.rendered}"
#   tags = {
#     Name = "Instance"
#   }
# }

data "template_file" "data" {
  template = "${file("install.tpl")}"

  vars={
    endpoint = trimsuffix("${aws_db_instance.default.endpoint}",":5432")
    a_key= var.a_key
    s_key= var.s_key
    db_name = var.db_name
    db_user = var.db_user
    db_pass = var.db_pass
    bucket = var.bucket
  }
}


# create IAM User 

resource "aws_iam_user" "circleci" {
  name = "CircleCi"
  path = "/system/"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "circleci" {
  user = "${aws_iam_user.circleci.name}"
}




#Policy for code deploy

resource "aws_iam_user_policy" "CircleCI-Code-Deploy" {
  name = "CircleCI-Code-Deploy"
  user = "${aws_iam_user.circleci.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:var.region:682607698449:application:web_app"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:var.region:682607698449:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:var.region:682607698449:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:var.region:682607698449:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}



resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name = "CodeDeploy-EC2-S3"
 
  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Effect": "Allow",
            "Resource": [
              "*"
              
              ]
        }
    ]
  }
  )
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.EC2_Role.name}"
  policy_arn = "${aws_iam_policy.CodeDeploy-EC2-S3.arn}"
}

resource "aws_iam_user_policy" "CircleCI-Upload-To-S3" {
  name = "CircleCI-Upload-To-S3"
  user = "${aws_iam_user.circleci.name}"

  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.abhithakkar.me",
			          "arn:aws:s3:::codedeploy.abhithakkar.me/*"
            ]
        }
    ]
  }
  )
}

resource "aws_iam_user_policy" "circleci-ec2-ami" {
  name = "circleci-ec2-ami"
  user = "${aws_iam_user.circleci.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CopyImage",
          "ec2:CreateImage",
          "ec2:CreateKeypair",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteKeyPair",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:DeregisterImage",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:GetPasswordData",
          "ec2:ModifyImageAttribute",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifySnapshotAttribute",
          "ec2:RegisterImage",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        "Resource": "*"
      }
  ]
}
EOF
}

#Create s3 bucket for codedeploy

resource "aws_s3_bucket" "codedeployabhithakkar" {
  bucket = "codedeploy.abhithakkar.me"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  lifecycle_rule {
    prefix  = "config/"
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  tags = {
    Name        = "codedeployabhithakkar"
   
  }
}

#create IAM role for CodeDeployEC2ServiceRole

resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = "CodeDeployEC2ServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": [
        "sts:AssumeRole"
        
      ]

    }
  ]
}
EOF

  tags = {
    name = "CodeDeployEC2ServiceRole"
  }
}

#Create policy for the CodeDeployEC2ServiceRole

resource "aws_iam_policy" "CodeDeployEC2ServiceRolepolicy" {
  name   = "CodeDeployEC2ServiceRolepolicy"
  # role   = aws_iam_role.EC2Role.id
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Action": [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ],
		"Resource": [
			"arn:aws:s3:::codedeploy.abhithakkar.me",
			"arn:aws:s3:::codedeploy.abhithakkar.me/*"
		]
	}]
}
  EOF

}

resource "aws_iam_role_policy_attachment" "attach-policy-codedeplyeEC2" {
  role       = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
  policy_arn = "${aws_iam_policy.CodeDeployEC2ServiceRolepolicy.arn}"
}

resource "aws_iam_instance_profile" "CodeDeployeEC2Profile" {
  name = "CodeDeployEC2ServiceRole"
  role = "${aws_iam_role.CodeDeployEC2ServiceRole.name}"
}

# Create CodeDeploy Application 

resource "aws_codedeploy_app" "csye6225-webapp" {
  compute_platform = "Server"
  name             = "csye6225-webapp"

}

#Create policy for the codedeployservicerole


resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF

  tags = {
    name = "CodeDeployServiceRole"
  }
}


resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.CodeDeployServiceRole.name}"
}

# resource "aws_codedeploy_app" "webapp" {
#   name = "webapp"
# }


resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = "${aws_codedeploy_app.csye6225-webapp.name}"
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn      = "${aws_iam_role.CodeDeployServiceRole.arn}"

  
  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "Instance"
  }

  
  deployment_style {
    deployment_type   = "IN_PLACE"
  }
  
  
  deployment_config_name= "CodeDeployDefault.OneAtATime"
   autoscaling_groups = [aws_autoscaling_group.autoscale-group.id]


  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.lb-listener.arn]
      }
      target_group {
        name = aws_lb_target_group.lb-target-group.name
      }
    }
  }

  # alarm_configuration {
  #   alarms  = ["my-alarm-name"]
  #   enabled = true
  # }
}

#Create policy for the CodeDeployServiceRole

resource "aws_iam_policy" "CodeDeployServiceRolepolicy" {
  name   = "CodeDeployServiceRolepolicy"
  # role   = aws_iam_role.EC2Role.id
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Effect": "Allow",
		"Action": [
       "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:EnableMetricsCollection",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribePolicies",
                "autoscaling:DescribeScheduledActions",
                "autoscaling:DescribeNotificationConfigurations",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:SuspendProcesses",
                "autoscaling:ResumeProcesses",
                "autoscaling:AttachLoadBalancers",
                "autoscaling:AttachLoadBalancerTargetGroups",
                "autoscaling:PutScalingPolicy",
                "autoscaling:PutScheduledUpdateGroupAction",
                "autoscaling:PutNotificationConfiguration",
                "autoscaling:PutLifecycleHook",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DeleteAutoScalingGroup",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:TerminateInstances",
                "tag:GetResources",
                "sns:Publish",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeInstanceHealth",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
    ],
		"Resource": [
			"arn:aws:s3:::codedeploy.abhithakkar.me",
			"arn:aws:s3:::codedeploy.abhithakkar.me/*"
		]
	}]
}
  EOF

}


resource "aws_iam_instance_profile" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"
  role = "${aws_iam_role.CodeDeployServiceRole.name}"
}

#Create launch configurations for EC2 Instance

resource "aws_launch_configuration" "asg_launch_config" {
  //name_prefix   = "asg_launch_config"
  image_id                    = var.ami
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  user_data                   = "${data.template_file.data.rendered}"
  iam_instance_profile        = "EC2-CSYE6225"
  name                        = "asg_launch_config"
  security_groups             = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
}

# Create Auto Scaling Group

resource "aws_autoscaling_group" "autoscale-group" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  default_cooldown     = 60
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifier  = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
  target_group_arns    = [aws_lb_target_group.lb-target-group.arn]
  tag {
    key                 = "Name"
    value               = "Instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.autoscale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "CPUAlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.autoscale-group.name}"
  }

  alarm_description = "Scale-up if CPU > 50% for 60 seconds"
  alarm_actions     = ["${aws_autoscaling_policy.WebServerScaleUpPolicy.arn}"]
}

resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.autoscale-group.name}"
}


resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = "CPUAlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.autoscale-group.name}"
  }

  alarm_description = "Scale-up if CPU < 30% for 60 seconds"
  alarm_actions     = ["${aws_autoscaling_policy.WebServerScaleDownPolicy.arn}"]
}

#load balancer sg

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow http traffic traffic"
  vpc_id      = aws_vpc.aws_demo.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   

  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load balancer SG"
  }
}



resource "aws_lb" "lb-webapp" {
  name               = "lb-webapp"
  internal           = false
  load_balancer_type = "application"
  # security_groups    = [aws_security_group.my_sg.id]
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet.id,aws_subnet.subnet1.id,aws_subnet.subnet2.id]

  enable_deletion_protection = false

  tags = {
    name = "lb-webapp"
  }
}

resource "aws_lb_target_group" "lb-target-group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.aws_demo.id


  stickiness {
    type = "lb_cookie"
    enabled = true
  }
}

# resource "aws_lb_listener" "lb-listener" {
#   load_balancer_arn = "${aws_lb.lb-webapp.arn}"
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.lb-target-group.arn}"
#   }
# }


# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = "${aws_lb_target_group.lb-target-group.arn}"
#   target_id        = "${aws_instance.web.id}"
#   port             = 80
# }


resource "aws_route53_record" "www" {
  zone_id = "Z0749463321KIEFGL34KC"
  name    = ""
  type    = "A"

  alias {
    name                   = aws_lb.lb-webapp.dns_name
    zone_id                = aws_lb.lb-webapp.zone_id
    evaluate_target_health = true
  }
}


#create lambda policy

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = "${aws_iam_role.iam_for_lambda.name}"
}

resource "aws_iam_role_policy_attachment" "EC2-SNS-Access" {
  policy_arn = "arn:aws:iam::682607698449:policy/EC2-SNS-Access"
  role       = "${aws_iam_role.EC2_Role.name}"
}

resource "aws_iam_role_policy_attachment" "Lambda-DynamoDB-Access" {
  policy_arn = "arn:aws:iam::682607698449:policy/Lambda-DynamoDB-Access"
  role       = "${aws_iam_role.iam_for_lambda.name}"
}

resource "aws_iam_role_policy_attachment" "Lambda-SES-Access" {
  policy_arn = "arn:aws:iam::682607698449:policy/Lambda-SES-Access"
  role       = "${aws_iam_role.iam_for_lambda.name}"
}


# Lamba Function

resource "aws_lambda_function" "test_lambda" {
  filename      = "webapp.zip"
  function_name = "lambda_function_name"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "handler.my_handler"

  source_code_hash = "${filebase64sha256("webapp.zip")}"

  runtime = "python3.8"

}


#  SNS Topic

resource "aws_sns_topic" "user_updates" {
  name = "sns_topic"
}

#  SNS Subscription

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.test_lambda.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.user_updates.arn}"
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = "${aws_lb.lb-webapp.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:682607698449:certificate/c9c7a90d-e2d5-4827-b201-4549404d6de5"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb-target-group.arn}"
  }
}

resource "aws_lb_listener" "listener-lb" {
  load_balancer_arn = "${aws_lb.lb-webapp.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_db_parameter_group" "parameter-group" {
  name   = "rds-pg"
  family = "postgres11"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

}



#  Code Deploy Lambda
# resource "aws_codedeploy_app" "csye6225-lambda" {
#   compute_platform = "Lambda"
#   name             = "csye6225-lambda"
# }


#  Deployment Config for Lambda
# resource "aws_codedeploy_deployment_config" "foo" {
#   deployment_config_name = "test-deployment-config"
#   compute_platform       = "Lambda"

#   traffic_routing_config {
#     type = "AllAtOnce"
#   }
# }


# #  Deployment for Lambda


# resource "aws_codedeploy_deployment_group" "csye6225-lambda-deployment" {
#   app_name              = "${aws_codedeploy_app.csye6225-lambda.name}"
#   deployment_group_name = "csye6225-lambda-deployment"
#   service_role_arn      = "${aws_iam_role.CodeDeployLambdaServiceRole.arn}"
#   deployment_config_name = "${aws_codedeploy_deployment_config.foo.id}"
#   deployment_style {
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#     deployment_type   = "BLUE_GREEN"
#   }

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_STOP_ON_ALARM"]
#   }  

# }