#!/bin/bash

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")" && pwd)

# Process configuration
source $REPO_ROOT/dependencies/process_config.sh

# Options
OUTPUT_FILE="processed_votes.txt"
SKIP_EXECUTION=false
SKIP_PROCESSING=false
SHOW_SKIPPED=false

function usage {
    echo "Usage: $0 [options]"
    echo "Configuration ($CONFIG_FILE):"
    echo "memo      $memo"
    echo "voters    ${voters[*]}"
    echo "options   ${votes[*]}"
    echo "node      $node"
    echo ""
    echo "Options (all are optional):"
    echo "  --output-file                Where all the processed votes should be stored (set to: $OUTPUT_FILE)."
    echo "  --skip-execution             Prints information about each proposal without attempting to vote (set to: $SKIP_EXECUTION)."
    echo "  --skip-processing            Doesn't process new votes and only calculates and prints the percentage for known processed votes [set to: $SKIP_PROCESSING]."
    echo "  --show-skipped               Also shows proposals this utility already processed (set to: $SHOW_SKIPPED)."
    echo "  -h, --help                   Show this help message."
    exit 0
}

# Process command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-file)
            shift
            OUTPUT_FILE=$1
            ;;
        --skip-execution)
            SKIP_EXECUTION=true
            ;;
        --skip-processing)
            SKIP_PROCESSING=true
            ;;
        --show-skipped)
            SHOW_SKIPPED=true
            ;;
        -h | --help)
            usage
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
    shift
done

# Variables
voted_proposals=0
total_proposals=$(namada client query-proposal | awk '/Proposal Id:/ {id=$3} END {print id + 1}')
executed_proposals=()

# Check if the output file exists, if not create it.
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR" || { echo "Error creating directory: $OUTPUT_DIR"; exit 1; }
touch "$OUTPUT_FILE"

# Function to try and execute a vote proposal (this randomizes between given addresses and vote options)
function execute_proposal() {
    local proposal_id=$1
    local address=${voters[RANDOM % ${#voters[@]}]}
    local vote=${votes[RANDOM % ${#votes[@]}]}

    local command="namada client vote-proposal --memo $memo --vote $vote --address $address --node $node --proposal-id $proposal_id"
    echo $command
    eval $command
}

# Function to process a proposal and check whether it has already been voted on or not
function process_proposal() {
    local proposal_id=$1
    local skip_execution=$2

    # Loop through the voters for the current proposal
    for ((i=0; i<${#voters[@]}; i++)); do
        voter="${voters[i]}"
        # Run the command to check if the voter voted for the proposal
        vote_result=$(namada client query-proposal-votes --proposal-id $proposal_id --voter $voter)

        # If the vote doesn't exist, 
        if [[ $vote_result == *"has not voted on proposal $proposal_id"* ]]; then
            # Check if we are at the last item in voters list
            if [ $i -eq $((${#voters[@]} - 1)) ]; then
                echo -e "\e[91m✘ No votes found for proposal $proposal_id by any of the specified voters.\e[0m \e[92m("$voted_proposals"/"$total_proposals")\e[0m"
                if ! $skip_execution; then
                    execute_proposal $proposal_id
                    executed_proposals+=("$proposal_id")
                fi
            fi
        elif [ -n "$vote_result" ]; then
            ((voted_proposals++))
            echo -e "\e[92m✔ Vote found for proposal $proposal_id by voter $voter. ("$voted_proposals"/"$total_proposals")\e[0m"
            echo ""$proposal_id" "$voter"" >> "$OUTPUT_FILE"
            break  # Exit the inner loop if a vote is found
        else
            echo "An error occurred while checking votes for proposal $proposal_id by voter $voter."
        fi
    done
}

# Function to process all proposals using total_proposals as the upper (inclusive) limit
function process_proposals() {
    for ((proposal_id=0; proposal_id<$total_proposals; proposal_id++)); do
        # Check if the proposal already has been processed
        if grep -q "^$proposal_id" "$OUTPUT_FILE"; then
            ((voted_proposals++))
            
            if $SHOW_SKIPPED; then
              echo "Proposal $proposal_id already processed. Skipping. ("$voted_proposals"/"$total_proposals")"
            fi
            continue
        fi

        process_proposal $proposal_id $SKIP_EXECUTION
    done
}

# Skip process if we want a quick calculation of our current (known) voting percentage (uses the output file)
if $SKIP_PROCESSING; then
    voted_proposals=$(wc -l < "$OUTPUT_FILE")
else
    process_proposals
fi

# Process the results of the executed proposals before we calculate the percentage
if [ ${#executed_proposals[@]} -ne 0 ]; then
    echo ""
    echo -e "\e[93mChecking executed proposals:\e[0m"

    # Iterate over the executed proposals
    for executed_id in "${executed_proposals[@]}"; do
        process_proposal $executed_id true
    done
fi

# Calculate and print the percentage
percentage=$(bc <<< "scale=2; ($voted_proposals / $total_proposals) * 100")

# Result
if ! $SKIP_PROCESSING; then 
  echo ""
fi

echo -e "\e[93mResult:\e[0m"
if (( $(echo "$percentage < 90" | bc -l) )); then
    echo -e "\e[91mPercentage of processed proposals (with valid votes): $percentage%\e[0m"
else
    echo -e "\e[92mPercentage of processed proposals (with valid votes): $percentage%\e[0m"
fi