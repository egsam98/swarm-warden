#!/bin/bash

function check_service() {
  service=$1
  echo "Checking service $service"

  service_info=$(docker service inspect "$service")

  service_updated_at=$(jq '.[].UpdatedAt' <<< "$service_info" | tr -d '"')
  image=$(jq '.[].Spec.TaskTemplate.ContainerSpec.Image' <<< "$service_info" | tr -d '"' | cut -f1 -d"@")
  echo "Service $service was updated at $service_updated_at"

  docker pull "$image" > /dev/null
  image_created_at=$(docker inspect "$image" | jq -r '.[].Created')
  echo "Image $image was build at $image_created_at"

  if (( $(date -d "$image_created_at" +%s) > $(date -d "$service_updated_at" +%s) ));
  then
    echo "Updating..."
    docker service update --force --with-registry-auth --image="$image" "$service"
    echo -e "Service $service was successfully updated\n"
  else
    echo -e "Service $service is up to date\n"
  fi
}

set -e
trap "echo 'Stopping warden...'; exit" INT TERM

sleep_interval=${SLEEP_INTERVAL:-10}
services=$SERVICES
echo "Watching services: $services"
echo -e "Sleep interval: ${sleep_interval}s\n"

IFS=','
read -r services_arr <<< "$services"

while true
do
  for service in $services_arr
  do
    check_service "$service"
  done
  sleep "$sleep_interval"
done
