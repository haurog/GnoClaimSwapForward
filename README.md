## Claim Swap Forward on Gnosis chain

This contract claims Gnosis staking rewards, swaps them for EURe and forwards them to a user selected address, like a gnosis pay wallet. The goal is to use this contract to automate this process using PowerPools and recharge the gnosis pay wallet regularly with staking gains. The contract uses balancer and curve to swap the claimed GNO to wxDAI and then the wxDAI to EURe. This route seems to be the cheapest and shortest from GNO-> EURe. At the moment the addresses are hard coded. The contract needs to be allowed to move GNO from the claimAddress.

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
