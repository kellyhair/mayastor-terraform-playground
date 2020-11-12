resource "hcloud_volume" "mayastor" {
  count     = length(hcloud_server.node)
  name      = "mayastor-${hcloud_server.node[count.index].name}"
  size      = 10
  server_id = hcloud_server.node[count.index].id
  automount = false
}
