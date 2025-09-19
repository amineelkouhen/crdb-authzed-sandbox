############################################################
# Security Groups

resource "aws_security_group" "allow-global" {
  name        = "${var.name}-sg-allow-global"
  description = "Allow External inbound traffic"
  vpc_id      = aws_vpc.client_vpc.id

  ingress {
    description      = "All Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

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