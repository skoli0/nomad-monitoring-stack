job "sachet" {
  datacenters = ["dc1"]
  
  type = "service"

  group "sachet" {
    count = 1  

    restart {
      attempts = 10
      interval = "5m"
      delay = "10s"
      mode = "delay"
    }
    
    network {
      port "http" {
        to = "9876"
      }
    }

    task "sachet" {
           template {
        change_mode = "noop"
        destination = "local/config.yml"

        data = <<EOH
providers:
  messagebird:
    access_key: 'n0UxnDvLLsu9QD6037jPD7Rte'
    debug: true
EOH
      }
      driver = "docker"

      config {
        image = "sachet:local"

        
        volumes = [
          "local/config.yml:/etc/sachet/config.yml",
        ]

        ports = ["http"]

        args = [
          "-config",
          "/etc/sachet/config.yml",
        ]
      }

      service {
        name = "sachet"

        tags = [
          "http",
          "monitoring",
          "traefik.enable=true",
          "traefik.http.routers.sachet.rule=PathPrefix(`/sachet`)",
          "traefik.http.middlewares.sachet.replacepath.path=/alert",
        ]

        port = "http"
      }
      
      resources {
        cpu    = 200 # 500 MHz
        memory = 256 # 256MB
      }
    }
  } 
}
