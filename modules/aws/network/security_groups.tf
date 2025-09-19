############################################################
# Security Groups

resource "aws_security_group" "allow-global" {
  name        = "${var.name}-sg-allow-global"
  description = "Allow External inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description       = "ICMP Protocol"
    from_port         = -1
    to_port           = -1
    protocol          = "icmp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from anywhere"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    description      = "DB Console"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    description = "Local to cockroach db host connection"
    from_port   = 26257
    to_port     = 26257
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Local to postgres db host connection"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ## outbound traffic

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-allow-global"
  })
}