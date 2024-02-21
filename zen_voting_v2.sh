#!/bin/bash

# Options
CONFIG_FILE="config.json"
PRINT_ONLY=false
CALCULATE_PERCENTAGE_ONLY=false
SHOW_SKIPPED=false
OUTPUT_FILE="processed_votes.txt"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

# Check if the JSON is valid
if ! jq empty "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Invalid JSON in $CONFIG_FILE."
    exit 1
fi

# Check if required keys are present
if ! jq -e 'has("node") and has("voters") and has("votes") and has("memo")' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required keys in $CONFIG_FILE."
    exit 1
fi

# Parse config.json
mapfile -t voters < <(jq -r '.voters[]' $CONFIG_FILE)
mapfile -t votes < <(jq -r '.votes[]' $CONFIG_FILE)
node=$(jq -r '.node' $CONFIG_FILE)
memo=$(jq -r '.memo' $CONFIG_FILE)

# Function to display script usage
function show_help {
    echo "Usage: $0 [options]"
    echo "Configuration ($CONFIG_FILE):"
    echo "memo      $memo"
    echo "voters    ${voters[*]}"
    echo "options   ${votes[*]}"
    echo "node      $node"
    echo ""
    echo "Options (all are optional):"
    echo "  --print-only                 Prints information about each proposal without attempting to vote (set to: $PRINT_ONLY)."
    echo "  --calculate-percentage-only  Calculate and print the percentage for all known processed votes (for a quick look at your percentage) [set to: $CALCULATE_PERCENTAGE_ONLY]."
    echo "  --show-skipped               Show which proposals were already processed by this utility (set to: $SHOW_SKIPPED)."
    echo "  --output-file                Where all the processed votes should be stored (set to: $OUTPUT_FILE)."
    echo "  -h, --help                   Show this help message."
    exit 0
}

# Process command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --print-only)
            PRINT_ONLY=true
            ;;
        --calculate-percentage-only)
            CALCULATE_PERCENTAGE_ONLY=true
            ;;
        --show-skipped)
            SHOW_SKIPPED=true
            ;;
        --output-file)
            shift
            OUTPUT_FILE=$1
            ;;
        -h | --help)
            show_help
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
    shift
done

# Fetch the last proposal ID
total_proposals=$(namada client query-proposal | awk '/Proposal Id:/ {id=$3} END {print id + 1}')

# Initialize counters
proposals_with_votes=0
executed_proposals=()

# Check if the processed file exists, if not create it
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR" || { echo "Error creating directory: $OUTPUT_DIR"; exit 1; }
touch "$OUTPUT_FILE"

function execute_vote() {
    local proposal_id=$1
    local address=${voters[RANDOM % ${#voters[@]}]}
    local vote=${votes[RANDOM % ${#votes[@]}]}

    local command="namada client vote-proposal --memo $memo --vote $vote --address $address --node $node --proposal-id $proposal_id"
    echo $command
    eval $command
}

function process_vote() {
    local proposal_id=$1
    local print_only=$2

    # Loop through the voters for the current proposal
    for ((i=0; i<${#voters[@]}; i++)); do
        target_voter="${voters[i]}"
        # Run the command to check if the voter voted for the proposal
        vote_result=$(namada client query-proposal-votes --proposal-id $proposal_id --voter $target_voter)

        # Check if the vote exists
        if [[ $vote_result == *"has not voted on proposal $proposal_id"* ]]; then
            # Check if we are at the last item in voters list
            if [ $i -eq $((${#voters[@]} - 1)) ]; then
                echo -e "\e[91m✘ No votes found for proposal $proposal_id by any of the specified voters.\e[0m \e[92m("$proposals_with_votes"/"$total_proposals")\e[0m"
                if ! $print_only; then
                    execute_vote $proposal_id
                    executed_proposals+=("$proposal_id")
                fi
            fi
        elif [ -n "$vote_result" ]; then
            ((proposals_with_votes++))
            echo -e "\e[92m✔ Vote found for proposal $proposal_id by voter $target_voter. ("$proposals_with_votes"/"$total_proposals")\e[0m"
            # Record the processed proposal ID
            echo ""$proposal_id" "$target_voter"" >> "$OUTPUT_FILE"
            break  # Exit the inner loop if a vote is found
        else
            echo "An error occurred while checking votes for proposal $proposal_id by voter $target_voter."
        fi
    done
}

function process_proposals() {
    # Loop through the range of proposal IDs
    for ((proposal_id=0; proposal_id<$total_proposals; proposal_id++)); do
        # Check if the proposal has been processed
        if grep -q "^$proposal_id" "$OUTPUT_FILE"; then
            ((proposals_with_votes++))
            
            if $SHOW_SKIPPED; then
              echo "Proposal $proposal_id already processed. Skipping. ("$proposals_with_votes"/"$total_proposals")"
            fi
            continue
        fi

        process_vote $proposal_id $PRINT_ONLY
    done
}

if $CALCULATE_PERCENTAGE_ONLY; then
    proposals_with_votes=$(wc -l < "$OUTPUT_FILE")
else
    process_proposals
fi

# Check if executed proposals array is not empty
if [ ${#executed_proposals[@]} -ne 0 ]; then
    echo ""
    echo -e "\e[93mChecking executed proposals:\e[0m"

    # Iterate over the executed proposals
    for executed_id in "${executed_proposals[@]}"; do
        process_vote $executed_id true
    done
fi

# Calculate and print the percentage
percentage=$(bc <<< "scale=2; ($proposals_with_votes / $total_proposals) * 100")
if (( $(echo "$percentage < 90" | bc -l) )); then
    # If percentage is below 90%, print in red
    echo -e "\e[91mPercentage of processed proposals (with valid votes): $percentage%\e[0m"
else
    # If percentage is 90% or above, print in green
    echo -e "\e[92mPercentage of processed proposals (with valid votes): $percentage%\e[0m"
fi