#!/bin/bash

# List all instances
echo "Fetching list of instances..."
gcloud compute instances list --format="table(name, zone, status)"

# Prompt  selection of  an instance
echo "Enter the name of the instance you want to start:"
read INSTANCE_NAME

# Get the zone of the selected instance
INSTANCE_ZONE=$(gcloud compute instances list --filter="name=${INSTANCE_NAME}" --format="get(zone)")

if [ -z "$INSTANCE_ZONE" ]; then
  echo "Instance not found. Exiting."
  exit 1
fi

# Start the instance
echo "Starting instance ${INSTANCE_NAME} in zone ${INSTANCE_ZONE}..."
gcloud compute instances start "${INSTANCE_NAME}" --zone="${INSTANCE_ZONE}"

# Fetch IPs
EXTERNAL_IP=$(gcloud compute instances describe "${INSTANCE_NAME}" --zone="${INSTANCE_ZONE}" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
INTERNAL_IP=$(gcloud compute instances describe "${INSTANCE_NAME}" --zone="${INSTANCE_ZONE}" --format="get(networkInterfaces[0].networkIP)")

# Output instance details
echo "Instance details:"
echo "Name: ${INSTANCE_NAME}"
echo "Zone: ${INSTANCE_ZONE}"
echo "External IP: ${EXTERNAL_IP}"
echo "Internal IP: ${INTERNAL_IP}"

# Set a timer for stopping the instance
echo "Enter the number of hours after which the instance should be stopped:"
read TIMER

# Validate input for TIMER
if ! [[ "$TIMER" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid number of hours."
    exit 1
fi

# Convert hours to seconds
let "NUM_SECONDS=TIMER*3600"

# Schedule the stop instance command in the background
(
    sleep "$NUM_SECONDS"
    gcloud compute instances stop "${INSTANCE_NAME}" --zone="${INSTANCE_ZONE}" >> ~/stop_instance.log 2>&1
) &

# Inform the user
echo "Instance ${INSTANCE_NAME} is scheduled to be stopped in ${TIMER} hour(s)."
echo "You can check the log at ~/stop_instance.log for details."
