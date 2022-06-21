job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    count = 1

    ephemeral_disk {
      size    = 300
      migrate = true
    }

    restart {
      attempts = 3
      interval = "2m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" { to = 3000 }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"

        cap_drop = [
          "ALL",
        ]

        ports = ["http"]
      }

      env {
        GF_INSTALL_PLUGINS            = "grafana-piechart-panel"
	      GF_SERVER_ROOT_URL            = "http://${NOMAD_HOST_IP_http}/grafana"
        GF_SERVER_SERVE_FROM_SUB_PATH = "true"
        GF_SECURITY_ADMIN_PASSWORD    = "admin"
        GF_SECURITY_DISABLE_GRAVATAR  = "true"
      }

      resources {
        cpu    = 100
        memory = 50
      }

      service {
        name = "grafana"
        port = "http"
        tags = [
          "http",
          "monitoring",
          "traefik.enable=true",
          "traefik.http.routers.grafana.rule=PathPrefix(`/grafana`)",
        ]

        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
