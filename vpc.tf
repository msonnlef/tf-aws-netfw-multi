resource "aws_vpc" "main" {
  cidr_block         = var.proy_cidr_block
  instance_tenancy   = "default"
  enable_dns_support = true
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-vpc-tf"
    }
  )
}
resource "aws_subnet" "app" {
  for_each = var.subnet_numbers

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 6, each.value - 1)
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-subnet-app${each.value}"
    }
  )
}
resource "aws_subnet" "public" {
  for_each = var.subnet_numbers

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 11, 95 + each.value)
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-subnet-public${each.value}"
    }
  )
}
resource "aws_subnet" "datos" {
  for_each = var.subnet_numbers

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 11, 127 + each.value)
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-subnet-datos${each.value}"
    }
  )
}
resource "aws_subnet" "tg-priv" {
  for_each = var.subnet_numbers

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 11, 131 + each.value)
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-subnet-tg-priv${each.value}"
    }
  )
}
resource "aws_subnet" "fw-priv" {
  for_each = var.subnet_numbers

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 11, 135 + each.value)
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-subnet-fw-priv${each.value}"
    }
  )
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-igw"
    }
  )
}
resource "aws_route_table" "rt-public-1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block      = "10.0.0.0/8"
    vpc_endpoint_id = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.tags, {
    Name = "rt-public-${var.Ambiente}-${var.Proyecto}-1"
    }
  )
}
resource "aws_route_table_association" "rt-public-1" {
  subnet_id      = aws_subnet.public["us-west-2a"].id
  route_table_id = aws_route_table.rt-public-1.id
}
# se fuerza el mapeo contra endpoints del FW
resource "aws_route_table" "rt-public-2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block      = "10.0.0.0/8"
    vpc_endpoint_id = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[2]
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.tags, {
    Name = "rt-public-${var.Ambiente}-${var.Proyecto}-2"
    }
  )
}
resource "aws_route_table_association" "rt-public-2" {
  subnet_id      = aws_subnet.public["us-west-2b"].id
  route_table_id = aws_route_table.rt-public-2.id
}
# se fuerza el mapeo contra endpoints del FW
resource "aws_route_table" "rt-public-3" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block      = "10.0.0.0/8"
    vpc_endpoint_id = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[1]
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.tags, {
    Name = "rt-public-${var.Ambiente}-${var.Proyecto}-3"
    }
  )
}
resource "aws_route_table_association" "rt-public-3" {
  subnet_id      = aws_subnet.public["us-west-2c"].id
  route_table_id = aws_route_table.rt-public-3.id
}
resource "aws_route_table" "rt-private" {
  for_each = var.subnet_numbers
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[each.value - 1]
  }
  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = merge(var.tags, {
    Name = "rt-private-${var.Ambiente}-${var.Proyecto}-${each.value}"
    }
  )
}
resource "aws_route_table_association" "rt-private" {
  for_each = var.subnet_numbers

  subnet_id      = aws_subnet.datos[each.key].id
  route_table_id = aws_route_table.rt-private[each.key].id
}
resource "aws_route_table_association" "rt-private-2" {
  for_each = var.subnet_numbers

  subnet_id      = aws_subnet.app[each.key].id
  route_table_id = aws_route_table.rt-private[each.key].id
}
resource "aws_route_table_association" "rt-private-3" {
  for_each = var.subnet_numbers

  subnet_id      = aws_subnet.tg-priv[each.key].id
  route_table_id = aws_route_table.rt-private[each.key].id
}
resource "aws_eip" "eip-nat-gw" {
  for_each = var.subnet_numbers
  tags = merge(var.tags, {
    Name = "eip-nat-gw-${var.Ambiente}-${var.Proyecto}-${each.value}"
    }
  )
}
resource "aws_nat_gateway" "gw" {
  for_each = var.subnet_numbers

  allocation_id = aws_eip.eip-nat-gw[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "nat-gw-${var.Ambiente}-${var.Proyecto}-${each.value}"
  }
}
resource "aws_route_table" "rt-fw" {
  for_each = var.subnet_numbers
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw[each.key].id
  }
  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  tags = merge(var.tags, {
    Name = "rt-fw-${var.Ambiente}-${var.Proyecto}-${each.value}"
    }
  )
}
resource "aws_route_table_association" "rt-fw-1" {
  for_each = var.subnet_numbers

  subnet_id      = aws_subnet.fw-priv[each.key].id
  route_table_id = aws_route_table.rt-fw[each.key].id
}
output "subnet-fw-priv-1" {
  value = aws_subnet.fw-priv["us-west-2a"].id
}
output "subnet-fw-priv-2" {
  value = aws_subnet.fw-priv["us-west-2b"].id
}
output "subnet-fw-priv-3" {
  value = aws_subnet.fw-priv["us-west-2c"].id
}