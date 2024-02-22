# Namada Proposals

Automate Namada's proposal voting and monitor your participation rate in governance.

This has been written by ZENODE and is licensed under the APACHE 2.0-license (see [LICENSE](./LICENSE)).

## Versions

There are currently **two versions**. While V2 is superior in most cases, V1 could still have its use. Especially in `TEST` mode, which makes it easy to print out vote commands without necessarily executing them.

> [!TIP]
>
> **Tip for both versions**
> 
> Saving `$NAMADA_WALLET_PASSWORD=your_password` to _~/.bashrc_ or _~/.bashprofile_ could really make your life easier when you want to automate these proposals. Make sure to source the file afterwards in your terminal (e.g. `source ~/.bashrc`).

## V2

### Requirements
- Faith and trust that this isn't a Trojan virus.
- `jq` - install this using `sudo apt-get install jq`.
- [Namada binary installed](https://github.com/anoma/namada). 

### Capabilities

- Keeps track of proposals already voted on (saves this in a `.txt` file)
- Shows your governance participation rate (either in `--offline`-mode or via a partial-live calculation).
  > Partial because it uses offline data wherever it can, but also attempts to check the proposals it hasn't processed yet.
  >
  > If you want to recalculate, simply remove the `.txt`-file or point to a different `--output-file`.
- Executes `vote-proposal`-commands for proposals a configured voter(s) has (or have) not yet voted on.
- Parses values like `memo`, `node`, `voters` and `votes` from a `config.json`-file (see [config.json.example](/config.json.example)).
- Randomizes between `votes` and `voters` values during the execution of a vote; can be adapted in the `config.json`-file.

### Quick-start

#### 1. Clone
```
git clone https://github.com/zenodeapp/namada-proposals.git && cd namada-proposals
```

#### 2. Configuration
   
> [!WARNING]
>
> Make sure to change the configurations!

```
cp config.json.example config.json
```

#### 3. Run

> [!IMPORTANT]
>
> The first run will always be slower than subsequent ones, since the utility won't have processed any of your proposals _yet_.

```
bash zen_voting_v2.sh
```
> Use `bash`; _sh_ won't work!

### More

For more help see `bash zen_voting_v2.sh -h` or `bash zen_voting_v2.sh --help`. It will show which configurations it parsed from the `config.json` file and also a list of _optional options_ you're able to use.

```
Usage: zen_voting_v2.sh [options]
Configuration (config.json):
memo      tpknam1qz36mzdvdmxvvcpv3c36zzs5v369jauws0tzrxesuaexy0p25r5sy0jsuac
voters    tnam1qq22qmw72m3e6c8lajx8jmzzh2h4t3dp7cfs4dxf tnam1qy6sfh87d4uy0d8mcc9gww5h0pctxvf0m5vdgw2c
options   yay nay abstain
node      tcp://127.0.0.1:26657

Options (all are optional):
  --output-file                Where all the processed votes should be stored (set to: processed_votes.txt).
  --skip-execution             Prints information about each proposal without attempting to vote (set to: false).
  --show-skipped               Show proposals this utility already processed (set to: false).
  --offline                    Doesn't process new votes and only calculates and prints the percentage for known processed votes (set to: false).
  -h, --help                   Show this help message.
```

> [!TIP]
>
> Creating a cronjob that periodically runs this script - let's say every _epoch_ - would be **the cheat of a lifetime** in this _Shielded Expedition_; *wink*, *wink*.

## V1 (old)

> [!WARNING]
>
> A caveat with this version is that values are hardcoded; you'll have to make the necessary changes at the top of the script. I might change this in the near-future, but is not a priority of mine since V2 already solves this.

### Requirements
- Faith and trust that this isn't a Trojan virus.
- - [Namada binary installed](https://github.com/anoma/namada).

### Capabilities

- Executes `vote-proposal`-commands for a range of proposals (`n1`...`n2`).
- Allows specifying `specific_proposals`, which are useful if you want to process proposals outside the set range.
- A `TEST`-mode where every `vote-proposal`-command only gets printed, either to double-check or have a list of commands for later use. 
- Randomizes between `aliases` and `vote_options` values during the execution of a vote.

### Quick-start

#### 1. Clone
```
git clone https://github.com/zenodeapp/namada-proposals.git && cd namada-proposals
```

#### 2. Configuration
   
Make the necessary changes in the script `zen_voting_v1.sh`.

#### 3. Run

```
bash zen_voting_v1.sh
```
> Use `bash`; _sh_ won't work!

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
