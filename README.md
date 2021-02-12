Overview of high-level configurations steps to set up HA VPN with Amazon Web Services (AWS):

![lifecycle: alpha](https://img.shields.io/badge/lifecycle-alpha-a0c3d2.svg)
* Create the HA VPN gateway and a Cloud Router. This creates 2 public IP addresses on the GCP side.
* Create two AWS Virtual Private Gateways. This creates 4 public addresses on the AWS side.
* Create two AWS Site-to-Site VPN connections and customer gateways, one for each AWS Virtual Private Gateway. Specify a non-overlapping link-local Tunnel IP Range for each tunnel, 4 total. For example, 169.254.1.4/30.
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
| aws | <4.0,>= 3.22.0 |
| google | <4.0,>= 3.11.0 |
| google-beta | <4.0,>= 3.11.0 |

## Providers

| Name | Version |
|------|---------|
| aws | <4.0,>= 3.22.0 |
| google | <4.0,>= 3.11.0 |
| google-beta | <4.0,>= 3.11.0 |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| transit\_gateway\_id | AWS Transit Gateway ID | `string` | n/a | yes |
| amazon\_side\_asn | BGP ASN Number for the AWS side of the VPN | `number` | `64512` | no |
| google\_network | Google VPN Network name, can be either a name or a self\_link | `string` | `"default"` | no |
| google\_side\_asn | BGP ASN Number for the Google side of the VPN | `number` | `65534` | no |
| router\_advertise\_config | Router custom advertisement configuration, ip\_ranges is a map of address ranges and descriptions. More info can be found here https://www.terraform.io/docs/providers/google/r/compute_router.html#bgp (Default:  null) | <pre>object({<br>    groups    = list(string)<br>    ip_ranges = map(string)<br>    mode      = string<br>  })</pre> | `null` | no |
| suffix | String to identify groups resources created by this module. This allow the module to be called multiple times in the same GCP Project and AWS account. dev/staging/prod are examples inputs. If not passed a 10 character random string will be assigned | `string` | `"null"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_router | Map of cloud router attributes. Map should match the exported resources described in the docs https://www.terraform.io/docs/providers/google/r/compute_router.html |
| ha\_vpn\_gateway\_interfaces | List of objects with interface ID and IP addresses |
| transit\_gateway\_attachment\_ids | Set of AWS Transit Gateway Attachement IDs |

