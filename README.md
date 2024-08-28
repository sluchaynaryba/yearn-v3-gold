## ST-YETH/GOLD [BPT](https://app.balancer.fi/#/ethereum/pool/0xcf8dfdb73e7434b05903b5599fb96174555f43530002000000000000000006c3) Strategy for yearn V3

Strategy autocompounds BPT (`ST-YETH/GOLD`)

### Requirements

First you will need to install [Foundry](https://book.getfoundry.sh/getting-started/installation).

### Set your environment Variables

Sign up for [Infura](https://infura.io/) and generate an API key and copy your RPC url. Store it in the `ETH_RPC_URL` environment variable.
NOTE: you can use other services.

Use .env file

1. Make a copy of `.env.example`
2. Add value for `ETH_RPC_URL`

### Run tests

```
forge test --fork-url ${ETH_RPC_URL}
```
