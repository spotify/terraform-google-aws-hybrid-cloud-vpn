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

variable "transit_gateway_id" {
  type        = string
  description = "AWS Transit Gateway ID"
}

variable "google_network" {
  type        = string
  default     = "default"
  description = "Google VPN Network name, can be either a name or a self_link"

}
variable "amazon_side_asn" {
  type        = number
  default     = 64512
  description = "BGP ASN Number for the AWS side of the VPN"
}

variable "google_side_asn" {
  type        = number
  default     = 65534
  description = "BGP ASN Number for the Google side of the VPN"
}

variable "suffix" {
  type        = string
  default     = "null"
  description = "String to identify groups resources created by this module. This allow the module to be called multiple times in the same GCP Project and AWS account. dev/staging/prod are examples inputs. If not passed a 10 character random string will be assigned"
}

variable "router_advertise_config" {
  description = "Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions. More info can be found here https://www.terraform.io/docs/providers/google/r/compute_router.html#bgp (Default:  null)"
  default     = null

  type = object({
    groups    = list(string)
    ip_ranges = map(string)
    mode      = string
  })
}
