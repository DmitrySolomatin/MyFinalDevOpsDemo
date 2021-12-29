# myvpc.tf

provider "aws" {
  
  shared_credentials_file = "/Users/dmitrysolom/.aws/credentials"
  profile                 = "default"
}

# Availability zones in the current region
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "-VPC"
  }
}

# Create var.az_counter private subnets in a different AZs
resource "aws_subnet" "private" {
  count             = var.az_counter
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  tags = {
    Name = "Private_subnet"
  }
}

# Create var.az_counter public subnets in a different AZs
resource "aws_subnet" "public" {
  count                   = var.az_counter
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_counter + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_Subnet"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Internet-gw"
  }
}

# Route the public subnet traffic through the Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Create NAT gateway with an Elastic IP for private subnets to get internet access
resource "aws_eip" "gw" {
  count      = var.az_counter
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "EIP"
  }
}

resource "aws_nat_gateway" "gw" {
  count         = var.az_counter
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
  tags = {
    Name = "NAT-gw"
  }
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_counter
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }
  tags = {
    Name = "Route Table"
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_counter
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}