variable "workers" {
  type        = map(string)
  description = "A map of worker_name=>worker_public_ip"
}

variable "nr_hugepages" {
  type        = number
  description = "Number of 2MB hugepages to allocate on the worker node"
  default     = 640
}
