## Claim Swap Forward on Gnosis chain

This contract claims Gnosis staking rewards, swaps them for EURe and forwards them to a user selected address, like a gnosis pay wallet. The goal is to use this contract to automate this process using PowerPools and recharge the gnosis pay wallet regularly with staking gains. The contract uses balancer and curve to swap the claimed GNO to wxDAI and then the wxDAI to EURe. This route seems to be the cheapest and shortest from GNO-> EURe. At the moment the addresses are hard coded. The contract needs to be allowed to move GNO from the claimAddress.
Deployed to: [0x3eAb5858ffe41BD352EeFaE4334e18B072c12757](https://gnosisscan.io/address/0x3eab5858ffe41bd352eefae4334e18b072c12757)

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
forge create --rpc-url https://rpc.gnosischain.com --private-key <your_private_key> src/<YourContract>.sol:<YourContract>

forge create \
    --rpc-url https://rpc.gnosischain.com \
    -ledger \
    --mnemonic-derivation-path "m/44'/60'/2'/0/0"  \
    --from 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1 \
    --verify \
    src/ClaimSwapForward.sol:ClaimSwapForward
```
### Verify (if the above step failed)

```shell
forge verify-contract \
    --chain-id 100 \
    --watch \
    --etherscan-api-key ETHERSCAN_API_KEY \
    --compiler-version v0.8.21 \
     0x3eAb5858ffe41BD352EeFaE4334e18B072c12757 \
    src/ClaimSwapForward.sol:ClaimSwapForward
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
