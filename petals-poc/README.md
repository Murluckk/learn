# Petals Protocol — Foundry PoC Suite

End-to-end, **fork-only** proof-of-concept for the vulnerabilities described
in the security audit of [petals.farm](https://www.petals.farm)
(contract `0xe097a4AD957633844448b65C63614A50dB70308A` on Ethereum mainnet).

> **Safety statement.** Every test runs against a *local* Anvil fork of
> Ethereum mainnet via `vm.createSelectFork`. Transactions are signed only
> inside the in-memory EVM. Nothing is broadcast, no real ETH moves, no
> private keys are needed, and no side effects on mainnet are possible.

## Scenarios covered

| ID | Scenario                                                                     | Test                                  | Result on fork                                                                       |
| -- | ---------------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------ |
| C1 | `updateRate(1)` → iterative `compoundAll()` → `sellPetals()` (owner drain)   | `test_C1_owner_rate_manipulation_drain` | Attacker netted **74.38 ETH** from a 1 ETH seed; pool lost **83.2%** of TVL in ≈ 480 s of real-block time |
| H2 | `SELFDESTRUCT` price pump + `sellPetals()`                                   | `test_H2_selfdestruct_pump`           | Pump of 5 ETH raised sell-price by 5.36%; attacker lost ≈ 4.53 ETH (not profitable, but price manipulable) |
| H4 | DoS via `updatePlatform(<non-payable contract>)`                             | `test_H4_DoS_via_non_payable_platform` | All `buySeeds`/`sellPetals` revert; `compoundAll` still functions (partial DoS)     |
| H4′ | DoS via `updatePlatform(<gas-bomb contract>)`                                | `test_H4_DoS_via_gas_bomb_platform`   | Same result using a payable receive() that burns >2300 gas                          |
| —  | Single-step `updateOwner` allows permanent brick                             | `test_ownership_bricking_single_step` | Ownership passed to a non-EOA address; admin functions reachable only by unreachable contract |
| H1 | Offline brute-force `bytes4(keccak256(addr)) == target`                      | `tools/collide_refcode_fast.py`       | Single CPU core: ~267 k keccak/s → ETA for 2³² ≈ 4.5 h; multi-core native: ~5 min; GPU (RTX 4090): seconds. USD cost: well under $1. |

Full numeric output is at the bottom of this README.

## Prerequisites

- Foundry (`forge`, `cast`, `anvil` ≥ 1.5.x): <https://getfoundry.sh/>
- Python 3.10+ with `pycryptodome` (only for the H1 brute-force calibration):
  ```bash
  pip install pycryptodome eth-keys eth-utils
  ```

## Running

```bash
# All fork-based EVM tests:
export ETH_RPC_URL="https://ethereum.publicnode.com"   # any full-state mainnet RPC
forge test -vvv

# Just one scenario:
forge test -vvv --match-test test_C1

# Pin a specific block (the tests accept FORK_BLOCK env):
FORK_BLOCK=24933000 forge test -vv --match-test test_C1
```

For the offline brute-force calibration (H1):

```bash
python3 tools/collide_refcode_fast.py --target 00000000 --budget 2000000
```

## Layout

```
src/
  Petals.sol       # Flattened mainnet source pulled from Sourcify (full_match)
  IPetals.sol      # Minimal interface used by the tests
  Helpers.sol      # ETHDonor, NonPayable, GasBomb exploit helpers
test/
  PetalsExploit.t.sol   # Five fork-based scenarios
tools/
  collide_refcode_fast.py  # H1 keccak-throughput calibration + extrapolation
  collide_refcode.py       # H1 reference implementation with real priv-key derivation
```

## C1 — `updateRate` ExploiT math

The vulnerable path:

```solidity
// In compoundAll():
uint256 newMultipliers = petalsBalance[msg.sender] / PETALS_TO_INCREASE_MULTIPLIER_BY_ONE;
multipliers[msg.sender] += newMultipliers;

// In getPetalsSinceLastHireTime():
return Math.min(PETALS_TO_INCREASE_MULTIPLIER_BY_ONE, block.timestamp - lastHireTime[user]) * multipliers[user];
```

With `rate = 1` the rewards-per-tick formula caps at `1 * multipliers` per
second, but **each** `compoundAll` converts those rewards 1:1 into more
multipliers. That doubles `multipliers` per round, so after `N` rounds the
attacker's petals-per-second = `2^N · multipliers_0`.

The payout bonding curve

```solidity
calculateTrade(p, marketPetals, balance) = PSN*balance / (PSNH + (PSN*marketPetals + PSNH*p)/p)
```

saturates as `p → ∞` at `PSN*balance / 2*PSNH = balance`. So the attacker's
single `sellPetals()` asymptotes to the **entire ETH balance**.

Actual run (block 24933316, live pool 89.45 ETH):

- 40 rounds of compoundAll → multiplier grew from 6 698 to **3.36 · 10¹⁷**
- `getMyPetals` ≈ 3.36 · 10¹⁷ lepetals after 1 extra second
- `calculatePetalsSell` payout = **75.33 ETH**
- Attacker bottom line: +74.38 ETH on a 1 ETH deposit
- Rounds × ~12 s/block ≈ **8 minutes** on real mainnet

## H2 — SELFDESTRUCT pump

`address(this).balance` is the only state in the pool. A helper contract with
balance can `SELFDESTRUCT(payable(PETALS))` and force ETH into the pool even
if it had no `receive()`. For a single attacker this is usually not
profitable (they donate more than they recover), but it DOES manipulate the
price curve for all other users — i.e. it can be used to grief, not to steal.

Measured at block 24933316:

- Before pump (5 ETH): `calculatePetalsSell(attacker_petals) = 0.470 ETH`
- After pump (+5 ETH via `selfdestruct`): `0.495 ETH` (+5.36%)
- Attacker's realized loss: ~4.53 ETH (donation > extraction for their share)

## H4 — DoS via `updatePlatform`

The contract sends dev fees with the legacy pattern:

```solidity
payable(platform).transfer(fee);
```

`.transfer` forwards only **2 300 gas**. Two ways for the owner (or a
compromised owner key) to brick the protocol:

1. `updatePlatform(<contract without receive>)` — any `receive()`-less
   contract address. `.transfer` reverts → every buy/sell reverts.
2. `updatePlatform(<gas bomb>)` — a `receive()` that writes to storage in a
   loop. Same outcome under the 2 300-gas stipend.

`compoundAll()` does not touch the platform address, so users can still
reshape their own multipliers; but they can never convert back to ETH.

## H1 — Offline brute-force of `bytes4(keccak256(addr))`

The ref-code space is `2^32 ≈ 4.3 · 10^9`. For targeted captures — e.g.

- `0x00000000` (the front-end's default-ref fallback, earning the attacker
  **25 % of every deposit that doesn't carry an explicit `?ref=`**);
- any `bytes4` that the owner whitelisted via `whitelistReferral(...)`
  before the legitimate influencer has claimed it;

— the attacker needs a single 32-bit preimage match.

Measured with `pycryptodome`'s native keccak (single core):

```
throughput        : 267,280 keccak(20B)/s per core
ETA for 2^32      : ~4.5 h on one core
16-core native C  : ~5 min (conservative 50× speedup)
RTX 4090          : seconds  (vanity-eth-style miners do 2–4 Gkeccak/s on 20-byte inputs)
```

Economic cost to mine an address whose keccak[:4] = `0x00000000`:

- Cloud GPU: ~$0.25 / hour on vast.ai/salad.com → **sub-$1 total**.
- Reward: 25 % of every default-ref `buySeeds` until someone else
  out-competes for that slot. At the time of audit, the `0x00000000`
  slot is unoccupied (verified via `userReferral(bytes4(0x00000000))`
  returning the zero address on mainnet).

Mitigations (summary from the audit):

1. Use 6–8 byte refCodes or sequential uint32 ids with explicit
   registration.
2. Explicitly disallow `bytes4(0)` and any `wlReferrals[code] == true`
   from being captured by `_buySeeds`.
3. Make referral registration require a signed message or a direct call
   from the referrer, not a side-effect of the first deposit.

## Raw `forge test -vv` output

```
Ran 5 tests for test/PetalsExploit.t.sol:PetalsExploitTest
[PASS] test_C1_owner_rate_manipulation_drain() (gas: 1249858)
[PASS] test_H2_selfdestruct_pump() (gas: 465972)
[PASS] test_H4_DoS_via_gas_bomb_platform() (gas: 153902)
[PASS] test_H4_DoS_via_non_payable_platform() (gas: 315674)
[PASS] test_ownership_bricking_single_step() (gas: 66964)

Suite result: ok. 5 passed; 0 failed; 0 skipped
```

## Scope of this PoC

This suite proves **reachability and economic impact** of specific code
paths described in the audit. It does not touch mainnet state and cannot —
even by accident — move real funds. To harm real users, an attacker would
have to (a) hold the owner key for C1/H4, or (b) burn GPU-hours and a tiny
amount of gas for H1.

Any follow-up work should be a `PetalsV2` that fixes these issues:

- bounds/min on `updateRate` + timelock,
- `Ownable2Step`, `Pausable`, and events on every admin function,
- 6-8 byte refCodes, explicit registration,
- virtual `ethReserve` instead of `address(this).balance`,
- `minOut` / `deadline` parameters on `buySeeds` and `sellPetals`,
- `.call{value:…}("")` with success-check, not `.transfer`.
