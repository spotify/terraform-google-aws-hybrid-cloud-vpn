# Copyright 2020 Spotify AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
locals {
  ha_vpn_interfaces_ips = [
    for x in google_compute_ha_vpn_gateway.gateway.vpn_interfaces :
    lookup(x, "ip_address")
  ]
  suffix = var.suffix != "null" ? var.suffix : random_string.suffix.result
  external_vpn_gateway_interfaces = {
    "0" = {
      tunnel_address        = aws_vpn_connection.vpn-alpha.tunnel1_address
      vgw_inside_address    = aws_vpn_connection.vpn-alpha.tunnel1_vgw_inside_address
      asn                   = aws_vpn_connection.vpn-alpha.tunnel1_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.vpn-alpha.tunnel1_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.vpn-alpha.tunnel1_preshared_key
      vpn_gateway_interface = 0
    },
    "1" = {
      tunnel_address        = aws_vpn_connection.vpn-alpha.tunnel2_address
      vgw_inside_address    = aws_vpn_connection.vpn-alpha.tunnel2_vgw_inside_address
      asn                   = aws_vpn_connection.vpn-alpha.tunnel2_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.vpn-alpha.tunnel2_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.vpn-alpha.tunnel2_preshared_key
      vpn_gateway_interface = 0
    },
    "2" = {
      tunnel_address        = aws_vpn_connection.vpn-beta.tunnel1_address
      vgw_inside_address    = aws_vpn_connection.vpn-beta.tunnel1_vgw_inside_address
      asn                   = aws_vpn_connection.vpn-beta.tunnel1_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.vpn-beta.tunnel1_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.vpn-beta.tunnel1_preshared_key
      vpn_gateway_interface = 1
    },
    "3" = {
      tunnel_address        = aws_vpn_connection.vpn-beta.tunnel2_address
      vgw_inside_address    = aws_vpn_connection.vpn-beta.tunnel2_vgw_inside_address
      asn                   = aws_vpn_connection.vpn-beta.tunnel2_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.vpn-beta.tunnel2_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.vpn-beta.tunnel2_preshared_key
      vpn_gateway_interface = 1
    },
  }
}

data "aws_region" "current" {}
data "google_project" "project" {}

resource "random_string" "suffix" {
  length  = 10
  special = false
  upper   = false
}

resource "google_compute_ha_vpn_gateway" "gateway" {
  provider = google-beta
  name     = "ha-vpn-gw-to-aws-${data.aws_region.current.name}-${local.suffix}"
  project  = data.google_project.project.project_id
  network  = var.google_network
}

# Can't loop the cgw because TF erros with : Terraform value depends on resource attributes that cannot be determined
# until apply, so Terraform cannot predict how many instances will be created.
# We know for each GW there will always be 2 interfaces so maybe a map of alpha/beta if we want a loop. For now
# I'm leaving as seperate resources.

resource "aws_customer_gateway" "cgw-alpha" {
  bgp_asn    = var.google_side_asn
  ip_address = google_compute_ha_vpn_gateway.gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "aws-to-google-vpn-gateway-alpha-${local.suffix}"
  }
}

resource "aws_customer_gateway" "cgw-beta" {
  bgp_asn    = var.google_side_asn
  ip_address = google_compute_ha_vpn_gateway.gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "aws-to-google-vpn-gateway-beta-${local.suffix}"
  }
}

// TODO Track this Issue and implement when ready https://github.com/terraform-providers/terraform-provider-aws/issues/11584

resource "aws_vpn_connection" "vpn-alpha" {
  customer_gateway_id = aws_customer_gateway.cgw-alpha.id
  transit_gateway_id  = var.transit_gateway_id
  type                = aws_customer_gateway.cgw-alpha.type

  tags = {
    "Name" = "vpn-to-google-alpha-${local.suffix}"
  }
}

resource "aws_vpn_connection" "vpn-beta" {
  customer_gateway_id = aws_customer_gateway.cgw-beta.id
  transit_gateway_id  = var.transit_gateway_id
  type                = aws_customer_gateway.cgw-beta.type

  tags = {
    "Name" = "vpn-to-google-beta-${local.suffix}"
  }
}

resource "google_compute_router" "router" {
  provider    = google-beta
  name        = "cr-to-aws-tgw-ha-vpn-${data.aws_region.current.name}-${local.suffix}"
  network     = var.google_network
  description = "Google to AWS via Transit GW connection for AWS region ${data.aws_region.current.name}"
  bgp {
    asn = var.google_side_asn
    advertise_mode = (
      var.router_advertise_config == null
      ? null
      : var.router_advertise_config.mode
    )
    advertised_groups = (
      var.router_advertise_config == null ? null : (
        var.router_advertise_config.mode != "CUSTOM"
        ? null
        : var.router_advertise_config.groups
      )
    )
    dynamic advertised_ip_ranges {
      for_each = (
        var.router_advertise_config == null ? {} : (
          var.router_advertise_config.mode != "CUSTOM"
          ? null
          : var.router_advertise_config.ip_ranges
        )
      )
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
  }
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  provider        = "google-beta"
  name            = "aws-${var.transit_gateway_id}-${data.aws_region.current.name}-${local.suffix}"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "AWS Transit GW: ${var.transit_gateway_id} in AWS region ${data.aws_region.current.name}"

  dynamic interface {
    for_each = local.external_vpn_gateway_interfaces
    content {
      id         = interface.key
      ip_address = interface.value["tunnel_address"]
    }
  }
}

resource "google_compute_vpn_tunnel" "tunnels" {
  provider                        = google-beta
  for_each                        = local.external_vpn_gateway_interfaces
  name                            = "tunnel${each.key}-${google_compute_router.router.name}"
  description                     = "Tunnel to AWS - HA VPN interface ${each.key} to AWS interface ${each.value.tunnel_address}"
  router                          = google_compute_router.router.self_link
  ike_version                     = 2
  shared_secret                   = each.value.shared_secret #local.external_vpn_gateway_interfaces[0].shared_secret #aws_vpn_connection.vpn-alpha.tunnel1_preshared_key
  vpn_gateway                     = google_compute_ha_vpn_gateway.gateway.self_link
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.self_link
  peer_external_gateway_interface = each.key
}

resource "google_compute_router_interface" "interfaces" {
  provider   = google-beta
  for_each   = local.external_vpn_gateway_interfaces
  name       = "interface${each.key}-${google_compute_router.router.name}"
  router     = google_compute_router.router.name
  ip_range   = each.value.cgw_inside_address #"${aws_vpn_connection.vpn-alpha.tunnel1_cgw_inside_address}/30" #"169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_router_peer" "router_peers" {
  provider        = google-beta
  for_each        = local.external_vpn_gateway_interfaces
  name            = "peer${each.key}-${google_compute_router.router.name}"
  router          = google_compute_router.router.name
  peer_ip_address = each.value.vgw_inside_address #aws_vpn_connection.vpn-alpha.tunnel1_vgw_inside_address #"169.254.0.2"
  peer_asn        = each.value.asn                #aws_vpn_connection.vpn-alpha.tunnel1_bgp_asn # aws_customer_gateway.cgw-alpha.bgp_asn #aws_vpn_connection.vpn-alpha.tunnel1_bgp_asn #64515
  interface       = google_compute_router_interface.interfaces[each.key].name
}
