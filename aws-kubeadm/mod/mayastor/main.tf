
resource "null_resource" "hugepages" {
  count = length(var.workers)

  connection {
    type = "ssh"
    user = var.user
    private_key = file(var.private_key_file)
    host = element(var.workers, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.nr_hugepages} | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages",
      "echo \"vm.nr_hugepages = ${var.nr_hugepages}\" | sudo tee -a /etc/sysctl.d/10-hugepages.conf",
    ]
  }

  triggers = {
    workers = join(",", var.workers)
  }
}
