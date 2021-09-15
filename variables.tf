variable "proy_cidr_block" {
  type = string
}
variable "tags" {
  type = map(string)
}
variable "Ambiente" {
  type = string
}
variable "Proyecto" {
  type = string
}
variable "Subproyecto" {
  type = string
}
variable "subnet_numbers" {
  description = "Map from availability zone to the number that should be used for each availability zone's subnet"
}
variable "ram_organization_arn" {
  type = string
}
variable "ip-matias" {
  type = string
}
variable "role_arn" {
  type = string
}
variable "region" {

}
variable "repo" {

}