job "alertmanager" {
  datacenters = ["dc1"]
  
  type = "service"

  group "alertmanager" {
    count = 1  
    restart {
      attempts = 10
      interval = "5m"
      delay = "10s"
      mode = "delay"
    }
    
    network {
      port "http" {
        to = "9093"
      }
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:latest"
        mount {
          type   = "bind"
          source = "local"
          target = "/etc/alertmanager"
          readonly = true
        }
        ports = ["http"]

        args = [
          #"--web.external-url=http://${NOMAD_HOST_IP_http}:${NOMAD_HOST_PORT_http}/alertmanager",
          #"--web.external-url=/alertmanager/",
          "--web.route-prefix=/alertmanager/",
          "--config.file=/etc/alertmanager/alertmanager.yml"
        ]

        volumes = [
          "local/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro",
        ]
      }
      
        template {
        change_mode = "noop"
        destination = "local/alertmanager.yml"

        data = <<EOH
---
global:
  # The smarthost and SMTP sender used for mail notifications.
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@example.org'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'

# The directory from which notification templates are read.
templates:
- '/etc/alertmanager/template/*.tmpl'

# The root route on which each incoming alert enters.
route:
  group_by: ['alertname', 'cluster', 'service']

  group_wait: 30s

  group_interval: 5m

  repeat_interval: 3h

  # A default receiver
  receiver: team-X-mails

receivers:
- name: 'team-X-mails'
  email_configs:
  - to: 'team-X+alerts@example.org'
EOH
      }

      service {
        name = "alertmanager"

        tags = [
          "http",
          "monitoring",
          "traefik.enable=true",
          # See: https://docs.traefik.io/routing/services/
          "traefik.http.routers.alertmanager.rule=PathPrefix(`/alertmanager`)",
          "traefik.http.services.alertmanager.loadbalancer.sticky=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.httponly=true",
          "traefik.http.services.alertmanager.loadbalancer.sticky.cookie.samesite=strict",
        ]

        port = "http"

        check {
          type     = "http"
          path     = "/alertmanager/-/healthy"
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
