# Namada Proposals

Automate Namada's proposal voting and monitor your participation rate in governance.

> [!TIP]
>
> Saving `$NAMADA_WALLET_PASSWORD=your_password` to `~/.bashrc` or `~/.bashprofile` could really make your life easier when you want to automate these proposals. Make sure to source the file afterwards in your terminal (e.g. `source ~/.bashrc`) if you do this.


## Versions

There are currently two versions. While V2 is superior in most cases, V1 could still have its use. Especially in `TEST` mode, which makes it easy to print out vote commands without necessarily executing them.

I'll start off by explaining V2, since this is the most verbose and the one I recommend to use.

### V2

#### Requirements
- Faith and trust that this isn't a Trojan virus.
- `jq` - install this using `sudo apt-get install jq`.

#### Capabilities

- **Keeps track of proposals already voted on** (saves this in a `.txt` file)
- Shows your **governance participation rate** (either in `--offline`-mode or via a partial-live calculation).
  > Partial because it uses offline data wherever it can, but also attempts to check the proposals it hasn't processed yet.
  >
  > If you want to recalculate, simply remove the `.txt`-file or point to a different `--output-file`.
- **Executes `vote-proposal`-commands** for proposals a configured voter(s) has (or have) not yet voted on.
- Parses values like `memo`, `node`, `voters` and `votes` from a `config.json`-file (see [config.json.example](/config.json.example)).
- Randomizes between `votes` and `voters` values during the execution of a vote; can be adapted in the `config.json`-file.

#### Quick-start

**1. Clone**
```
git clone https://github.com/zenodeapp/namada-proposals && cd namada-proposals
```

**2. Configuration**
   
> [!WARNING]
>
> Make sure you change the configurations!

```
cp config.json.example config.json
```

**3. Run**

```
bash zen_voting_v2.sh
```
> Use `bash`; _sh_ won't work!




#### Usage

> [!IMPORTANT]
>
> The first run will always be slower than subsequent ones, since the utility won't have processed any of your proposals.

Use `bash zen_voting_v2.sh -h` or `bash zen_voting_v2.sh --help` to access this. It will show which configurations it parsed from the `config.json` file and also a list of _options_ you're able to use.

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
  --show-skipped               Also shows proposals this utility already processed (set to: false).
  --offline                    Doesn't process new votes and only calculates and prints the percentage for known processed votes (set to: false).
  -h, --help                   Show this help message.
```
