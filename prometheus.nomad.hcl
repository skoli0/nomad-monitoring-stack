job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
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
      port "http" { to = 9090 }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        cap_drop = [
          "ALL",
        ]

        ports = ["http"]

        args = [
          #"--web.external-url=http://${NOMAD_HOST_IP_http}:${NOMAD_HOST_PORT_http}/prometheus",
          "--web.external-url=/prometheus/", # this works too
          "--web.route-prefix=/prometheus/",
          "--config.file=/etc/prometheus/prometheus.yml"
        ]
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml:ro",
        ]
      }

      service {
        name = "prometheus"
        port = "http"

        tags = [
          "http",
          "monitoring",
          "traefik.enable=true",
          "traefik.http.routers.prometheus.rule=PathPrefix(`/prometheus`)",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.httponly=true",
          "traefik.http.services.prometheus.loadbalancer.sticky.cookie.samesite=strict",
        ]

        check {
          type     = "http"
          path     = "/prometheus/-/healthy"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '{{ env "NOMAD_HOST_IP_http" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
EOH
      }
      resources {
        cpu    = 100
        memory = 200
      }
    }
  }
}

