#!/bin/bash

jobs=("prometheus" "grafana" "alertmanager" "node-exporter" "sachet" "traefik" "whoami")
action=$1
job=$(echo "$2" | tr [A-Z] [a-z])

echo $action $job
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
    "validate")
        if [[ " ${jobs[*]} " =~ " ${job} " ]]; then
            echo "=== Stopping job ${job}..."
            nomad job validate ${job}.nomad.hcl
        else
            echo "=== Invalid job. Exiting..."
        fi
   ;;
   "status")
       nomad status
   ;;
esac
