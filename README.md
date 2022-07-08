Overview of high-level configurations steps to set up HA VPN with Amazon Web Services (AWS):

![lifecycle: alpha](https://img.shields.io/badge/lifecycle-alpha-a0c3d2.svg)
* Create the HA VPN gateway and a Cloud Router. This creates 2 public IP addresses on the GCP side.
* Create two AWS Virtual Private Gateways. This creates 4 public addresses on the AWS side.
* Create two AWS Site-to-Site VPN connections and customer gateways, one for each AWS Virtual Private Gateway. Specify a non-overlapping link-local Tunnel IP Range for each tunnel, 4 total. For example, 169.254.1.4/30.
  * Configure AES-256, SHA-2 and DH group 18, [as a combination of single Phase 1 and Phase 2 encryption algorithms, integrity algorithms, and DH group numbers.](https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-ha-vpn)
* Download the AWS configuration files for the generic device type.
* Create four VPN tunnels on the HA VPN gateway.
* Configure BGP sessions on the Cloud Router using the BGP IP addresses from the downloaded AWS configuration files.

### Single Region Example
```hcl
module "tgw-us-east-1" {
   source          = "terraform-aws-modules/transit-gateway/aws"
   version         = "1.1.0"
   name            = "tgw-example-us-east-1"
   description     = "TGW example shared with several other AWS accounts"
   amazon_side_asn = "64512"

   enable_auto_accept_shared_attachments = true
   ram_allow_external_principals         = true

   tags = {
     Purpose = "tgw example"
   }
}

module "cb-us-east-1" {
   source             = "github.com/spotify/terraform-google-aws-hybrid-cloud-vpn"
   transit_gateway_id = module.tgw-us-east-1.this_ec2_transit_gateway_id
   google_network     = default
   amazon_side_asn    = 64512
   google_side_asn    = 65534
}
```

### Refrence Docs
https://cloud.google.com/files/CloudVPNGuide-UsingCloudVPNwithAmazonWebServices.pdf
https://cloud.google.com/vpn/docs/how-to/creating-ha-vpn

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.22.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.11.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 3.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.22.0 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.11.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 3.11.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.cgw-alpha](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_customer_gateway.cgw-beta](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_vpn_connection.vpn-alpha](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [aws_vpn_connection.vpn-beta](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |
| [google-beta_google_compute_external_vpn_gateway.external_gateway](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_external_vpn_gateway) | resource |
| [google-beta_google_compute_ha_vpn_gateway.gateway](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_ha_vpn_gateway) | resource |
| [google-beta_google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_router) | resource |
| [google-beta_google_compute_router_interface.interfaces](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_router_interface) | resource |
| [google-beta_google_compute_router_peer.router_peers](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_router_peer) | resource |
| [google-beta_google_compute_vpn_tunnel.tunnels](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_vpn_tunnel) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | AWS Transit Gateway ID | `string` | n/a | yes |
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | BGP ASN Number for the AWS side of the VPN | `number` | `64512` | no |
| <a name="input_aws_vpn_configs"></a> [aws\_vpn\_configs](#input\_aws\_vpn\_configs) | AWS Tunnels Configs for aws\_vpn\_connection. This addresses this [known issue](https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-ha-vpn). | `map(any)` | <pre>{<br>  "dh_group_numbers": [<br>    "18"<br>  ],<br>  "encryption_algorithms": [<br>    "AES256"<br>  ],<br>  "integrity_algorithms": [<br>    "SHA2-256"<br>  ]<br>}</pre> | no |
| <a name="input_google_network"></a> [google\_network](#input\_google\_network) | Google VPN Network name, can be either a name or a self\_link | `string` | `"default"` | no |
| <a name="input_google_side_asn"></a> [google\_side\_asn](#input\_google\_side\_asn) | BGP ASN Number for the Google side of the VPN | `number` | `65534` | no |
| <a name="input_router_advertise_config"></a> [router\_advertise\_config](#input\_router\_advertise\_config) | Router custom advertisement configuration, ip\_ranges is a map of address ranges and descriptions. More info can be found here https://www.terraform.io/docs/providers/google/r/compute_router.html#bgp (Default:  null) | <pre>object({<br>    groups    = list(string)<br>    ip_ranges = map(string)<br>    mode      = string<br>  })</pre> | `null` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | String to identify groups resources created by this module. This allow the module to be called multiple times in the same GCP Project and AWS account. dev/staging/prod are examples inputs. If not passed a 10 character random string will be assigned | `string` | `"null"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_router"></a> [cloud\_router](#output\_cloud\_router) | Map of cloud router attributes. Map should match the exported resources described in the docs https://www.terraform.io/docs/providers/google/r/compute_router.html |
| <a name="output_ha_vpn_gateway_interfaces"></a> [ha\_vpn\_gateway\_interfaces](#output\_ha\_vpn\_gateway\_interfaces) | List of objects with interface ID and IP addresses |
| <a name="output_transit_gateway_attachment_ids"></a> [transit\_gateway\_attachment\_ids](#output\_transit\_gateway\_attachment\_ids) | Set of AWS Transit Gateway Attachement IDs |
