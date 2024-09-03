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

### Known issues for management

1. The amount of BPT out in `joinPool` cannot be calculated precisely to be protected, since underlying assets cannot be price without manipulation or concerns of precision directly onchain. Management will handle on best efforts to avoid MEV via multisig.

2. Curve pool oracle can be considered staled based on `curveOracleTimeWindow` value, which can be updated by management. It is advisable to perform a small swap before rewards are processed in case that the pool has zero activity for over 1-2 days.
