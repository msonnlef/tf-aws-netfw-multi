
resource "aws_networkfirewall_rule_group" "network-fw-rule-group-1" {
  description = "Stateless Rate Limiting Rule"
  capacity    = 100
  name        = "network-fw-rule-group-1"
  type        = "STATELESS"

  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-network-fw-rule-group-1"
    }
  )
}
resource "aws_networkfirewall_firewall_policy" "network-fw-policy" {
  name = "network-fw-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]
    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.network-fw-rule-group-1.arn
    }
  }
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-network-fw-policy"
    }
  )
}
resource "aws_networkfirewall_firewall" "network-fw" {
  name                     = "network-fw"
  firewall_policy_arn      = aws_networkfirewall_firewall_policy.network-fw-policy.arn
  vpc_id                   = aws_vpc.main.id
  subnet_change_protection = false
  delete_protection        = false
  subnet_mapping {
    subnet_id = aws_subnet.fw-priv["us-west-2a"].id
  }
  subnet_mapping {
    subnet_id = aws_subnet.fw-priv["us-west-2c"].id
  }
  subnet_mapping {
    subnet_id = aws_subnet.fw-priv["us-west-2b"].id
  }
  tags = merge(var.tags, {
    Name = "${var.Ambiente}-${var.Proyecto}-network-fw"
    }
  )
}
output "vpce" {
  value = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].endpoint_id)
}
output "subnet-vpce" {
  value = (aws_networkfirewall_firewall.network-fw.firewall_status[0].sync_states[*].attachment[0].subnet_id)
}