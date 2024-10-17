#!/bin/bash

# List all instances in the current project
echo "Fetching the list of running VM instances in your project..."
gcloud compute instances list --filter="status=RUNNING" --format="table(name,zone)"

# Prompt user to select a VM instance
echo ""
read -p "Enter the name of the VM instance whose snapshot should be taken: " INSTANCE_NAME

# Get the zone of the selected instance
ZONE=$(gcloud compute instances list --filter="name=$INSTANCE_NAME" --format="value(zone)")

if [ -z "$ZONE" ]; then
    echo "Error: Instance not found."
    exit 1
fi

# Get the disk attached to the instance
DISK_NAME=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format="value(disks[0].source)" | cut -d'/' -f11)

if [ -z "$DISK_NAME" ]; then
    echo "Error: No disk found for the selected instance."
    exit 1
fi

# Create a snapshot with a timestamp
SNAPSHOT_NAME="snapshot-${INSTANCE_NAME}-$(date +%Y-%m-%d)"

echo "Creating snapshot of disk $DISK_NAME from instance $INSTANCE_NAME in zone $ZONE..."
gcloud compute disks snapshot $DISK_NAME \
    --snapshot-names=$SNAPSHOT_NAME \
    --zone=$ZONE

echo "Snapshot $SNAPSHOT_NAME created successfully."
