resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "tgw creado por terraform"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "disable"
  amazon_side_asn                 = 64512

  tags = merge(var.tags, {
    Name = "tgw-${var.Ambiente}-${var.Proyecto}"
    }
  )
}

resource "aws_ram_resource_share" "ram" {
  name                      = "ram"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name = "ram-${var.Ambiente}-${var.Proyecto}"
    }
  )
}
resource "aws_ram_resource_association" "ram" {
  resource_arn       = aws_ec2_transit_gateway.tgw.arn
  resource_share_arn = aws_ram_resource_share.ram.arn
}
resource "aws_ram_principal_association" "ram" {
  principal          = var.ram_organization_arn
  resource_share_arn = aws_ram_resource_share.ram.arn
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attach" {
  subnet_ids                                      = [aws_subnet.tg-priv["us-west-2a"].id, aws_subnet.tg-priv["us-west-2b"].id, aws_subnet.tg-priv["us-west-2c"].id]
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  vpc_id                                          = aws_vpc.main.id
  appliance_mode_support                          = "enable"
  dns_support                                     = "enable"
  ipv6_support                                    = "disable"

  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-tgw-attach"
    }
  )
}
resource "aws_ec2_transit_gateway_route_table" "tgw-rtb" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-tgw-rtb"
    }
  )
}
resource "aws_ec2_transit_gateway_route_table_association" "rtb-assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rtb.id
}