/**
 * This example configures a multi region connection
 *
 * In each region a Cloud Router and HA VPN Connection is connected to AWS Site to Site VPN connections and connected
 * to a transit gateway. Transit gatway peering connections must be done outside this module.
 *
 * * Create the HA VPN gateway and a Cloud Router. This creates 2 public IP addresses on the GCP side.
 * * Create two AWS Virtual Private Gateways. This creates 4 public addresses on the AWS side.
 * * Create two AWS Site-to-Site VPN connections and customer gateways, one for each AWS Virtual Private Gateway. Specify a non-overlapping link-local Tunnel IP Range for each tunnel, 4 total. For example, 169.254.1.4/30.
 * * Download the AWS configuration files for the generic device type.
 * * Create four VPN tunnels on the HA VPN gateway.
 * * Configure BGP sessions on the Cloud Router using the BGP IP addresses from the downloaded AWS configuration files.
 *
 */

provider "google" {
  project = "project"
  region  = "us-central1"
  version = "3.11.0"
}

provider "google-beta" {
  project = "project"
  region  = "us-central1"
  version = "3.13.0"
}

provider "google" {
  project = "project"
  alias   = "us-central1"
  region  = "us-central1"
}

provider "google-beta" {
  project = project
  alias  = "us-central1"
  region  = "us-central1"
}

provider "google" {
  project = "project"
  alias   = "europe-west1"
  region  = "europe-west1"
}

provider "google-beta" {
  project = "project"
  alias   = "europe-west1"
  region  = "europe-west1"
}

provider "aws" {
  region  = "us-east-1"
  version = "2.51.0"
}

# N. Virginia / USA
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Frankfurt
provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
}

# AWS Transit Gateways in the Grand Central AWS Account
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
  providers = {
    aws = "aws.us-east-1"
  }
}

module "cb-us-east-1" {
  source                  = "github.com/spotify/terraform-google-aws-hybrid-cloud-vpn"
  transit_gateway_id      = module.tgw-us-east-1.this_ec2_transit_gateway_id
  google_network          = "default"
  amazon_side_asn         = 64512
  google_side_asn         = 65534
  router_advertise_config = {
    mode = "CUSTOM"
    ip_ranges = {
      "10.0.0.0/8" = "10.0.0.0/8"
    }
    groups    = null

  }

  providers = {
    aws         = "aws.us-east-1"
    google      = "google.us-central1"
    google-beta = "google-beta.us-central1"
  }
}

module "tgw-eu-central-1" {
  source          = "terraform-aws-modules/transit-gateway/aws"
  version         = "1.1.0"
  name            = "tgw-example-eu-central-1"
  description     = "TGW example shared with several other AWS accounts"
  amazon_side_asn = "64513"

  enable_auto_accept_shared_attachments = true
  ram_allow_external_principals         = true

  tags = {
    Purpose = "tgw example"
  }
  providers = {
    aws = "aws.eu-central-1"
  }
}
module "cb-eu-central-1" {
  source                  = "github.com/spotify/terraform-google-aws-hybrid-cloud-vpn"
  transit_gateway_id      = module.tgw-eu-central-1.this_ec2_transit_gateway_id
  google_network          = "default"
  amazon_side_asn         = 64513
  google_side_asn         = 65533
  router_advertise_config = {
    mode = "CUSTOM"
    ip_ranges = {
      "10.0.0.0/8" = "10.0.0.0/8"
    }
    groups    = null

  }

  providers = {
    aws         = "aws.eu-central-1"
    google      = "google.europe-west1"
    google-beta = "google-beta.europe-west1"
  }
}
