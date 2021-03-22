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

