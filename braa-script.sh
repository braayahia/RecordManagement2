#!/bin/bash

# Define global variables for the record file and its associated log file.
recordFile="$1"
logFile="${recordFile}_log"

# Check if the record file name is provided when running the script.
if [[ -z "$recordFile" ]]; then
    echo "Error: No record file name provided."
    exit 1
fi

# Function to validate input: both record name and quantity.
validate_input() {
    local recordName="$1"
    local quantity="$2"

    # Check if record name contains only letters, numbers, and spaces.
    if ! [[ "$recordName" =~ ^[a-zA-Z0-9\s]+$ ]]; then
        echo "Error: Record name can only contain letters, numbers, and spaces."
        return 1
    fi

    # Ensure quantity is a positive integer.
    if ! [[ "$quantity" =~ ^[0-9]+$ ]]; then
        echo "Error: Quantity must be a positive integer."
        return 1
    fi

    return 0 # Indicate success.
}

# Function to log events to a specified log file.
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$logFile"
}

# Function to add or merge records based on user choice.
add_record() {
    echo "Enter record name:"
    read recordName
    echo "Enter quantity:"
    read quantity

    # Input validation.
    if ! validate_input "$recordName" "$quantity"; then
        return # Exit if validation fails.
    fi

    # Search for similar records.
    matchingRecords=($(grep -i "$recordName" "$recordFile"))
    if [ ${#matchingRecords[@]} -gt 0 ]; then
        echo "A record with a similar name was found."
        echo "1. Create a new file"
        echo "2. Add quantity to the existing file"
        echo "3. Exit"
        read -p "Select an option: " option

        case "$option" in
            1)
                # Option 1: Add as a new record.
                echo "$recordName,$quantity" >> "$recordFile"
                echo "New record added successfully."
                log_event "Added new record: $recordName, Quantity: $quantity"
                ;;
            2)
                # Option 2: Merge quantity with the first matching record.
                # Extracts the first matching record's details.
                local lineNum=$(echo "${matchingRecords[0]}" | cut -d: -f1)
                local existingRecord=$(echo "${matchingRecords[0]}" | cut -d: -f2)
                local existingName=$(echo "$existingRecord" | cut -d, -f1)
                local existingQuantity=$(echo "$existingRecord" | cut -d, -f2)
                echo $existingRecord
                update_record_quantity "$existingName" "$existingQuantity" "$quantity" "$lineNum"
                ;;
            3)
                # Option 3: Exit.
                echo "Exiting..."
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    else
        # Add a new record if no similar records are found.
        echo "$recordName,$quantity" >> "$recordFile"
        echo "New record added successfully."
        log_event "Added new record: $recordName, Quantity: $quantity"
    fi
}

# Function to directly update a record's quantity, now modified to handle direct values for integration.
update_record_quantity() {
    local recordName="$1"
    local existingQuantity="$2"
    local addQuantity="$3"
    local lineNum="$4"
    
    # Calculate new quantity.
    let newQuantity=existingQuantity+addQuantity

    # Update the record with the new quantity.
    sed -i "${lineNum}s/.*/$recordName,$newQuantity/" "$recordFile"
    echo "Quantity added to the existing record successfully."
    log_event "Added quantity to $recordName, New Quantity: $newQuantity"
}

# Other functions (update_record_name, delete_record, list_records) remain unchanged.

# Main menu function to navigate through options.
main_menu() {
    while true; do
        echo "1. Add a record"
        echo "2. Delete a record"
        echo "3. List all records"
        echo "4. Update a record's name"
        echo "5. Update a record's quantity"
        echo "6. Exit"
        read -p "Select an option: " option

        case "$option" in
            1) add_record ;;
            2) delete_record ;;
            3) list_records ;;
            4) update_record_name ;;
            5) update_record_quantity ;;
            6) echo "Exiting..."; log_event "Exited the application."; break ;;
            *) echo "Invalid option. Please try again."; log_event "Invalid option selected." ;;
        esac
    done
}


# Check if record file exists, if not create it
if [ ! -f "$recordFile" ]; then
    touch "$recordFile"
    log_event "Created record file: $recordFile"
fi

# Check if log file exists, if not create it
if [ ! -f "$logFile" ]; then
    touch "$logFile"
    log_event "Created log file: $logFile"
fi

# Start the application
main_menu
