#!/bin/bash

# Verify that exactly one argument is provided to the script. This argument should be the filename where records are stored.
if [ "$#" -ne 1 ]; then
    echo "Error: You must provide a filename as an argument."
    exit 1
fi

# Define global variables used throughout the script.
FILENAME="$1"  # The filename for storing records, provided as an argument.
LOGFILE="${FILENAME}_log"  # A log file associated with the records file for logging events.
CHOSEN_RECORD_NAME=""  # Temporarily holds the name of a record during certain operations.
CHOSEN_RECORD_AMOUNT=""  # Temporarily holds the amount of a record during certain operations.
CHECK_FLAG=0  # A flag used to indicate certain conditions, such as whether a record exists.
ONE_RECORD_MATCH=1  # A flag to indicate if exactly one record matches during search operations. Not actively used in this provided script excerpt.

# Function to log events with a timestamp.
logEvent() {
    local eventName="$1"
    local eventOutcome="$2"
    local additionalDetails="$3"
    if [[ -n "$additionalDetails" ]]; then
        # If additional details are provided, include them in the log entry.
        echo "$(date +'%d/%m/%Y %H:%M:%S') - $eventName $eventOutcome $additionalDetails" >> "$LOGFILE"
    else
        # Otherwise, log without additional details.
        echo "$(date +'%d/%m/%Y %H:%M:%S') - $eventName $eventOutcome" >> "$LOGFILE"
    fi
}



# Function to initialize the environment.
initialize() {
    # Check if the record file exists, if not, create it.
    if [ ! -f "$FILENAME" ]; then
        touch "$FILENAME"
        logEvent "Initialization" "Success" "Created record file: $FILENAME"
    fi
    # Check if the log file exists, if not, create it.
    if [ ! -f "$LOGFILE" ]; then
        touch "$LOGFILE"
        logEvent "Initialization" "Success" "Created log file: $LOGFILE"
    fi
}

# Function to validate record names.
validateRecordName() {
    local recordName="$1"  # The record name to validate.

    # Validate that the record name is non-empty and alphanumeric, not starting with a number.
    if [[ -z "recordName" || ! "recordName" =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
        echo "Invalid record name. Please use a non-empty string that doesn't start with a number."
        logEvent "Validation" "Failure" "Invalid record name attempted with '$1'"
        return 1
    fi
    return 0
}

# Function to validate record amounts.
validateRecordAmount() {
    local recordAmount="$1"  # The amount to validate.

    # Validate that the amount is a positive integer.
    if ! [[ "recordAmount" =~ ^[0-9]+$ ]]; then
        echo "Invalid amount. Please enter a positive integer."
        logEvent "Invalid amount" "Attempted with '$1'"
        return 1
    fi
    return 0
}

# Function to add a new record into the record file.
addRecord() {
    # Prompt the user for the record name and read the input.
    echo "Enter record name:"
    read -r recordName
    # Validate the input record name. If it fails validation, return from the function.
    validateRecordName "$recordName" || return

    # Prompt the user for the record amount and read the input.
    echo "Enter record amount:"
    read -r recordAmount
    # Validate the input record amount. If it fails validation, return from the function.
    validateRecordAmount "$recordAmount" || return

    # Search if the record already exists. The 'silent' mode is a placeholder, 
    # indicating that the function could be modified to suppress output or handle searches differently.
    # If the record doesn't exist, append it to the record file.
    if [ "$CHECK_FLAG" -eq 0 ]; then
        echo "$recordName,$recordAmount" >> "$FILENAME"
        logEvent "Add Record" "Success" "Record $recordName added"
        echo "Record added successfully."
    else
        # If the record exists, inform the user.
        echo "Record already exists. Consider updating the record instead."
    fi
}

# Function to delete a specified record from the record file.
deleteRecord() {
    # Prompt the user for the name of the record to delete.
    echo "Enter record name to delete:"
    read -r recordName
    # Search for the record. If not found, indicate failure.
    searchRecord "$recordName" silent
    if [ "$CHECK_FLAG" -eq 1 ]; then
        echo "Record not found."
        return
    fi

    # If the record is found, delete it from the file.
    sed -i "/^$recordName,/d" "$FILENAME"
    logEvent "Delete Record" "Success" "Record $recordName deleted"
    echo "Record deleted successfully."
}

# Function to search for records by a keyword and display matching records.
searchRecord() {
    local keyword="$1"
    # Prompt for a keyword to search within the records.
    echo "Enter keyword to search:"
    read -r keyword
    # Perform the search; if matches are found, display them.
    if grep -n "$keyword" "$FILENAME" > /dev/null; then
        grep -n "$keyword" "$FILENAME"
        logEvent "Search Record" "Success" "Search for $keyword found matches"
    else
        # If no matches are found, inform the user.
        echo "No records found matching $keyword."
        logEvent "Search Record" "Failure" "No matches for $keyword"
    fi
}
# Function to update the name of an existing record.
updateRecordName() {
    # Prompt for the current and new names for the record.
    echo "Enter current record name:"
    read -r currentName
    echo "Enter new record name:"
    read -r newName
    # Validate the new name. If invalid, return.
    validateRecordName "$newName" || return

    # Replace the old name with the new name in the record file.
    sed -i "s/^$currentName,/$newName,/" "$FILENAME"
    logEvent "Update Record Name" "Success" "Record name changed from $currentName to $newName"
    echo "Record name updated successfully."
}

# Function to update the amount associated with a specific record.
updateRecordAmount() {
    # Prompt the user for the record name and the new amount.
    echo "Enter record name:"
    read -r recordName
    echo "Enter new record amount:"
    read -r newAmount
    # Validate the new amount. If invalid, return.
    validateRecordAmount "$newAmount" || return

    # Update the amount for the specified record in the file.
    sed -i -r "s/^($recordName,)[0-9]+/\1$newAmount/" "$FILENAME"
    logEvent "Update Record Amount" "Success" "Amount updated for $recordName"
    echo "Record amount updated successfully."
}

# Function to display all records sorted by name.
printAllSortedRecords() {
    # Check if there are records to display.
    if [ -s "$FILENAME" ]; then
        sort "$FILENAME"
        logEvent "Print All Sorted" "Success" "All records sorted"
    else
        echo "No records to display."
    fi
}

# Function to calculate and display the total amount of all records.
printRecordsTotalAmount() {
    # Check if there are records to calculate the total amount.
    if [ -s "$FILENAME" ]; then
        local total=$(awk -F ',' '{sum += $2} END {print sum}' "$FILENAME")
        echo "Total amount of all records: $total"
        logEvent "Print Total Amount" "Success" "Displayed total amount"
    else
        echo "No records to calculate total amount."
    fi
}


# Function to exit the script.
exitScript() {
    logEvent "Exit Script" "Success" "Script exited"
    echo "Exiting the script. Goodbye!"
    exit 0
}


# Menu and Main Function
displayMenu() {
    echo
    echo "Record Management System"
    echo "1. Add a Record"
    echo "2. Delete a Record"
    echo "3. Search for a Record"
    echo "4. Update a Record's Name"
    echo "5. Update a Record's Amount"
    echo "6. Print Total Amount of Records"
    echo "7. Print All Records Sorted"
    echo "8. Exit"
    echo "Enter your choice:"
}

main() {
    while true; do
        displayMenu
        read choice
        case $choice in
            1) addRecord ;;
            2) deleteRecord ;;
            3) searchRecord ;;
            4) updateRecordName ;;
            5) updateRecordAmount ;;
            6) printRecordsTotalAmount ;;
            7) printAllSortedRecords ;;
            8) exitScript ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

initialize
main
