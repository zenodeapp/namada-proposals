#!/bin/bash

# If TEST is true then we'll only print the commands without executing.
TEST=true

# Define range, specific proposals that have to be checked again, addresses and vote options
n1=1
n2=167
specific_proposals=(79 101 143 146)
aliases=("zen" "anodeofzen")
vote_options=("nay" "abstain" "yay")
memo=$YOUR_MEMO
node=tcp://127.0.0.1:26657

function execute_vote_command() {
    local proposal_id=$1
    local address=${aliases[RANDOM % ${#aliases[@]}]}
    local vote=${vote_options[RANDOM % ${#vote_options[@]}]}

    local command="namada client vote-proposal --memo $memo --vote $vote --address $address --node $node --proposal-id $proposal_id"
    echo $command
    
    if ! $TEST; then
      eval $command
    fi
}

# First, try specific proposal IDs
for proposal_id in "${specific_proposals[@]}"; do
    execute_vote_command $proposal_id
done

# Then, iterate through the range
for ((i=$n1; i<=$n2; i++)); do
    # Skip specific proposal IDs
    if [[ " ${specific_proposals[@]} " =~ " $i " ]]; then
        continue
    fi
    execute_vote_command $i
done
