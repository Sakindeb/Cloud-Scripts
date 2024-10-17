#!/bin/bash

# Function to create snapshots for all running instances
create_snapshots() {
    echo "Fetching the list of running VM instances in your project..."
    RUNNING_INSTANCES=$(gcloud compute instances list --filter="status=RUNNING" --format="value(name,zone)")

    if [ -z "$RUNNING_INSTANCES" ]; then
        echo "No running instances found. No snapshots will be taken."
        return
    fi

    # Loop through all running instances
    while read -r INSTANCE_NAME ZONE; do
        echo "Creating snapshot for instance: $INSTANCE_NAME in zone: $ZONE"

        # Get the disk attached to the instance
        DISK_NAME=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format="value(disks[0].source)" | cut -d'/' -f11)

        if [ -z "$DISK_NAME" ]; then
            echo "Error: No disk found for instance $INSTANCE_NAME."
            continue
        fi

        # Create a snapshot with a timestamp
        SNAPSHOT_NAME="snapshot-${INSTANCE_NAME}-$(date +%Y-%m-%d)"
        echo "Creating snapshot of disk $DISK_NAME from instance $INSTANCE_NAME in zone $ZONE..."
        gcloud compute disks snapshot $DISK_NAME \
            --snapshot-names=$SNAPSHOT_NAME \
            --zone=$ZONE

        echo "Snapshot $SNAPSHOT_NAME created successfully for $INSTANCE_NAME."
    done <<< "$RUNNING_INSTANCES"
}

# Function to delete snapshots older than 2 days
delete_old_snapshots() {
    echo "Deleting snapshots older than 2 days..."

    # Get the current date and time in UTC
    CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%S")

    # List and filter snapshots older than 2 days and delete them
    SNAPSHOTS=$(gcloud compute snapshots list --filter="creationTimestamp<'$(date -d '2 days ago' -u +"%Y-%m-%dT%H:%M:%S")'" --format="value(name)")

    if [ -z "$SNAPSHOTS" ]; then
        echo "No snapshots older than 2 days were found."
        return
    fi

    while read -r SNAPSHOT_NAME; do
        echo "Deleting snapshot: $SNAPSHOT_NAME"
        gcloud compute snapshots delete $SNAPSHOT_NAME --quiet
        echo "Snapshot $SNAPSHOT_NAME deleted."
    done <<< "$SNAPSHOTS"
}

# Main script execution
echo "Starting snapshot creation and cleanup process..."

# Create snapshots for running instances
create_snapshots

# Delete old snapshots older than 2 days
delete_old_snapshots

echo "Process completed."
