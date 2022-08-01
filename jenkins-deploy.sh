#!/bin/bash

jobs=("prometheus" "grafana" "alertmanager" "node-exporter" "sachet" "traefik" "whoami")
action=$(echo "$1" | tr [A-Z] [a-z])
job=$2

case "$action" in
   "start") 
        if [[ " ${jobs[*]} " =~ " ${job} " ]]; then
            echo "=== Deploying job ${job}..."
            nomad run job/${job}.nomad.hcl
        else
            echo "=== Invalid job. Exiting..."
        fi
   ;;
   "stop")
        if [[ " ${jobs[*]} " =~ " ${job} " ]]; then
            echo "=== Stopping job ${job}..."
            nomad job stop -purge ${job}
        else
            echo "=== Invalid job. Exiting..."
        fi
   ;;
   "status")
       nomad status
   ;;
esac
