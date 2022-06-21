job "node-exporter" {
  datacenters = ["dc1"]
  
  type = "service"

  group "node-exporter" {
    count = 1  
    restart {
      attempts = 10
      interval = "5m"
      delay = "10s"
      mode = "delay"
    }
    
    network {
      port "http" {
        to = "9100"
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:latest"
        mount {
          type   = "bind"
          source = "local"
          target = "/etc/node-exporter"
          readonly = true
        }
        ports = ["http"]
      }
      
      service {
        name = "node-exporter"

        tags = [
          "http",
          "monitoring",
          "traefik.enable=true",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.routers.node-exporter.rule=PathPrefix(`/node-exporter`)",
          "traefik.http.services.node-exporter.loadbalancer.sticky=true",
          "traefik.http.services.node-exporter.loadbalancer.sticky.cookie.httponly=true",
          "traefik.http.services.node-exporter.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "http"

        check {
          type     = "http"
          path     = "/metrics/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 200 # 500 MHz
        memory = 256 # 256MB
      }
    }
  } 
}
