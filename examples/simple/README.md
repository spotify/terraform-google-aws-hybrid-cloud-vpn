This example configures a simple single region connection

* Create the HA VPN gateway and a Cloud Router. This creates 2 public IP addresses on the GCP side.
* Create two AWS Virtual Private Gateways. This creates 4 public addresses on the AWS side.
* Create two AWS Site-to-Site VPN connections and customer gateways, one for each AWS Virtual Private Gateway. Specify a non-overlapping link-local Tunnel IP Range for each tunnel, 4 total. For example, 169.254.1.4/30.
* Download the AWS configuration files for the generic device type.
* Create four VPN tunnels on the HA VPN gateway.
* Configure BGP sessions on the Cloud Router using the BGP IP addresses from the downloaded AWS configuration files.

## Requirements

| Name | Version |
|------|---------|
| aws | 2.51.0 |
| google-beta | 3.11.0 |

## Providers

No provider.

## Inputs

No input.

## Outputs

No output.

