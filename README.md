## Claim Swap Forward on Gnosis chain

This contract claims Gnosis staking rewards, swaps them for ETHe and forwards them to a user selected address, like a gnosis pay wallet. The goal is to use this contract to automate this process using PowerPools and recharge the gnosis pay wallet regularly with staking gains.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge create --rpc-url https://rpc.gnosischain.com --private-key <your_private_key> src/<YourContract>.sol:<YourContract>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
