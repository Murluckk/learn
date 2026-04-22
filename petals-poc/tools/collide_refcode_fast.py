#!/usr/bin/env python3
"""
H1 PoC (fast variant): measures how many `keccak256(random 20-byte address)`
operations per second one CPU core can do. For the Petals contract,
refCode = bytes4(keccak256(abi.encodePacked(msg.sender))). An attacker who
wants to pre-compute a specific refCode does NOT need to derive the address
from a private key upfront — they can:

  1. pick a random seed s,
  2. compute addr_candidate = keccak256(s)[:20] (same as how CREATE2/vanity
     tools work),
  3. when refCode(addr) matches, derive the actual EOA priv from s or, more
     realistically, use an ECDSA vanity miner (libsecp256k1 + OpenCL).

So the bottleneck for a real attacker is *one* keccak per attempt, not two.
This script measures that raw rate and extrapolates.
"""

import argparse, os, secrets, time, hashlib

# Use the Ethereum keccak-256 via pycryptodome (it has native C binding).
from Crypto.Hash import keccak as _kk

def k(b):
    h = _kk.new(digest_bits=256)
    h.update(b)
    return h.digest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", default="00000000",
                    help="target 4-byte refCode in hex, e.g. 00000000")
    ap.add_argument("--budget", type=int, default=2_000_000)
    args = ap.parse_args()

    target = bytes.fromhex(args.target)
    assert len(target) == 4

    t0 = time.time()
    hits = 0
    full_hit = None
    bs = os.urandom  # alias
    for i in range(1, args.budget + 1):
        # 20-byte "address" candidate. (In reality an attacker still needs a
        # private key; they can use a vanity-address miner that generates
        # pubkey -> addr -> refcode in one pipeline. This just measures
        # keccak throughput, which is the dominant cost.)
        addr = bs(20)
        rc = k(addr)[:4]
        if rc == target:
            hits += 1
            if full_hit is None:
                full_hit = (addr.hex(), rc.hex(), i, time.time() - t0)
                print(f"FULL HIT after {i:,} tries: addr=0x{addr.hex()} rc=0x{rc.hex()}")
        if i % 500_000 == 0:
            dt = time.time() - t0
            rate = i / dt
            print(f"  [{i:>10,}] {dt:6.1f}s  {rate:>12,.0f} keccak/s  ETA 2^32: {(2**32)/rate/3600:.2f} h")

    dt = time.time() - t0
    rate = args.budget / dt
    print()
    print(f"throughput         : {rate:,.0f} keccak(20B)/s per core (pycryptodome C binding)")
    print(f"budget             : {args.budget:,} in {dt:.2f}s")
    print(f"full hits          : {hits}")
    print()
    print("extrapolation to a targeted refCode (exact 32-bit match):")
    print(f"  expected tries   : ~2^32 = 4.295e9")
    print(f"  single core py   : ~{(2**32)/rate/3600:.2f} h = {(2**32)/rate/3600/24:.2f} days")
    print(f"  16-core native C : ~{(2**32)/rate/3600/16/50:.2f} h   (assume 50x over Python)")
    print(f"  NVIDIA RTX 4090  : seconds  (vanity-ETH reports ~2-4 billion keccak/s for 20B inputs)")
    print()
    print("Economic cost estimate for the `0x00000000` capture attack:")
    print("  Cloud: rent a single 4090 on vast.ai / salad.com for ~$0.20-0.40/h")
    print("  Expected time: ~a few seconds to minutes of GPU -> well under $1.")
    print("  Reward: a share of EVERY buySeeds() call that doesn't pass ?ref=...")
    print("          i.e. 25% of the front-end's default traffic forever.")

if __name__ == "__main__":
    main()
