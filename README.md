## Claim Swap Forward on Gnosis chain

This contract claims Gnosis staking rewards, swaps them for EURe and forwards them to a user selected address, like a gnosis pay wallet. The goal is to use this contract to automate this process using PowerPools and recharge the gnosis pay wallet regularly with staking gains. The contract uses balancer and curve to swap the claimed GNO to wxDAI and then the wxDAI to EURe. This route seems to be the cheapest and shortest from GNO-> EURe. The contract needs to be allowed to move GNO from the claimAddress.
Deployed to: [0x3eAb5858ffe41BD352EeFaE4334e18B072c12757](https://gnosisscan.io/address/0x3eab5858ffe41bd352eefae4334e18b072c12757)

## Details for Each Step in the Smart Contract

The contract has several distinct steps. Here I explain each step and the approach I have taken. If any of the steps below fail, the transaction is reverted and it is as if nothing happened.

1. **Claim**: Anyone can call the 'claimWithdrawal' function from the [official GBC Deposit contract](https://gnosisscan.io/address/0x0B98057eA310F4d31F2a452B414647007d1645d9#writeProxyContract) for any of the Gnosis chain validators. This function then withdraws the rewards to the withdrawal address for the specific validator. My smart contract executes this function from the GBC Deposit Contract.
2. **Transfer GNO**. The rewards from step 1. are then forwarded to the address of the smart contract. For this step the smart con tract needs GNO token allowance from the withdrawal address to move the tokens
3. **Swap GNO to wxDAI**: Use Balancer to swap the GNO tokens to wrapped xDAI using a [weighted balancer pool](https://app.balancer.fi/#/gnosis-chain/pool/0xa99fd9950b5d5dceeaf4939e221dca8ca9b938ab000100000000000000000025).
4. **Swap wxDAI to EURe**: Use curve to swap wxDAI to EURe using the [eureusd pool](https://curve.fi/#/xdai/pools/eureusd/deposit).
5. **Forward**: Transfer the received EURe to the destination address stored in the smart contract.

The choice of these two pools to swap the tokens is that the balancer one is not incentivized and still pretty large giving a good liquidity and probably better long term stability than highly incentivized pools. The curve pool gives extremely good liquidity and low fee. Overall a pure balancer path would have been more expensive than this mixed swap path. Manual tests over several weeks have shown that the chosen path beats a pure Balancer swap most of the time and is generally close to cowswaps swaps, but obviously never beating cowswap.

For my own claims, I chose to execute the [transaction automatically](](https://app.powerpool.finance/#/gnosis/explorer/jobs/0x071412e301C2087A4DAA055CF4aFa2683cE1e499/0x483c7847f80a1cfdc701f74fbf8877ddf5c0d4e11f444772d4b44fee5e713b6d/)) at a regular interval (7 days) using PowerPools decentralized network of keepers.

## Possible Attack Vectors and Mitigations

### Sandwiching swaps
Doing swaps in a smart contract opens one up to [sandwich attacks](https://www.coingecko.com/learn/sandwich-attacks-prevention-crypto) as there is not a simple way to define slippage in such a swap. Two different approaches are used here. For the balancer pool, the smart contract checks if the balancer pool balance has been changed in the same block as the one the smart contract wants to swap in. If the balancer pool has been changed this could be an indication of a sandwich attack and therefore the transaction fails. The trade-off is obviously that a normal transaction which did a small swap in the same block will prevent the smart contract to execute the swap. Manual test while writing the contract showed that there was a much smaller than a 1% chance of having another balancer swap in the same block. This is an acceptable trade-off. If chain usage increases massively there might be more false positives with this approach and it might have to be rethought.

With curve the smart contract uses a different approach to prevent sandwiching. It reads an curve internal exponentially moving average price over previous blocks to determine the current EMA price. DOcumentation around this feature is rather thin and I stumbled upon it rather by chance. But the basic idea is if the EMA price differs more than 1% from the current price to the detriment of the smart contract the swap will fail. It is more robust than the balancer approach, but there were times with a high USD/EUR volatility which would have triggered this sandwich prevention mechanism without any sandwiching going on, especially around interest rate changes of central banks.

These two sandwich prevention mechanisms are contract owner configurable. The balancer sandwich prevention is a boolean which can switch the mechanism on and off, whereas the curve one is a integer setting the maximum deviation between EMA price and current price. These are the only two contract owner only functions that exist in the contract.

### Executing Transactions

If the allowance has been given to the smart contract anyone can initiate a transaction. But the only thing that happens will be having GNO tokens claimed, swapped and forwarded to the stored forwarding address. There is no way for anyone to be able to steal funds in this way. They would just pay the gas fees for you.

### Preventing Swaps to go Through

This is connected to the discussion of sandwich attacks. A bad actor could relatively easily just send balancer swaps right before your transaction and prevent your transactions from going through. This would a griefing attack which also costs the attacker money (gas fee) without directly benefitting. The only way to counteract this would be to switch off the balancer sandwich prevention mechanism in the contract. If this would become a problem a cleaner approach would be to use external oracles to get the 'real' exchange rates and only swap if they are within a certain range.

## I want this as well

This contract has obviously **not** been audited by any external party. The contract has been intentionally kept as simple and explicit (i.e. not gas optimized) as possible to make understanding it easier and reduce the surface area for any possible exploits. There is no web interface for this smart contract. You have to use gnosisscan. If you want to use it, do the following:

1. Connect your withdrawal address to gnosisscan.io and register a forwarding address using ['setForwardingAddress'](https://gnosisscan.io/address/0x3eAb5858ffe41BD352EeFaE4334e18B072c12757#writeContract)
2. Set a reasonable GNO token approval for the smart contract. Connect your withdrawal address to the [GNO contract](https://gnosisscan.io/address/0x9c58bacc331c9aa871afd802db6379a98e80cedb#writeProxyContract) on gnosisscan and set the approval to the following contract: 0x3eAb5858ffe41BD352EeFaE4334e18B072c12757
3. Now you can initiate the claim, swap and forward transaction by calling the 'claimSwapForward' function with your withdrawal address as a function parameter. If you want to automate this, open the [Powerpool App](https://app.powerpool.finance/#/gnosis/ppv2/all-jobs) set up a job using PowerAgent. The [PowerPool documentation](https://docs.powerpool.finance/powerpool-and-poweragent-network/power-agent/user-guides/i-want-to-automate-my-tasks/job-registration-guide) or my [current job](https://app.powerpool.finance/#/gnosis/explorer/jobs/0x071412e301C2087A4DAA055CF4aFa2683cE1e499/0x483c7847f80a1cfdc701f74fbf8877ddf5c0d4e11f444772d4b44fee5e713b6d/) can be guide how to set it up yourself.



## Develop it yourself

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
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

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
