resource "aws_instance" "Bastion_Host" {
  ami             = var.bastion_host_ami
  key_name        = var.key_pair_name
  count      = "${length(var.public_subnets)}"
  instance_type   = "t2.micro"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  security_groups = [aws_security_group.Public_Security_Group.id]
  tags = {
    Name = "Public Host - Testing"
  }
}


