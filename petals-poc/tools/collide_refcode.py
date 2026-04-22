#!/usr/bin/env python3
"""
H1 PoC: offline brute-force of an EOA whose keccak256(address)[:4]
matches a target 4-byte referral code.

Key insight from Petals contract:
    bytes32 hash = keccak256(abi.encodePacked(msg.sender));
    bytes4 refCode = bytes4(hash);   // top 4 bytes of the hash

The 4-byte code space is 2^32 ~= 4.29e9. A birthday-attack collision
with 77k existing codes already has >50% probability, but for a
*targeted* code (e.g. 0x00000000 — the default-ref sink — or a code
the owner whitelisted) we need to hit one specific 32-bit value.

Expected work to hit any given target: 2^32 ~= 4.3e9 tries.
Expected work to collide with ANY of N existing codes: 2^32 / N tries.

This script:
  1. generates random private keys,
  2. derives each address,
  3. hashes it and checks the first 4 bytes,
  4. reports hit-rate and estimated time to find a fully-targeted code.

Run with:  python3 tools/collide_refcode.py --target 00000000 --budget 2000000
"""

import argparse, os, secrets, time
from eth_keys import keys
from eth_utils import keccak

def addr_from_priv(priv_bytes: bytes) -> bytes:
    pk = keys.PrivateKey(priv_bytes)
    return pk.public_key.to_canonical_address()  # 20 bytes

def refcode(addr: bytes) -> bytes:
    return keccak(addr)[:4]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", default="00000000",
                    help="target 4-byte refCode in hex, e.g. 00000000")
    ap.add_argument("--budget", type=int, default=1_000_000,
                    help="how many tries to run for timing calibration")
    ap.add_argument("--prefix-bits", type=int, default=0,
                    help="search a shorter prefix for demo (<=32)")
    args = ap.parse_args()

    target = bytes.fromhex(args.target)
    assert len(target) == 4

    prefix_nibbles = args.prefix_bits // 4
    mask_hex = args.target[:prefix_nibbles] if prefix_nibbles > 0 else args.target
    print(f"target refCode          : 0x{args.target}")
    print(f"searching prefix-bits   : {args.prefix_bits or 32}")
    print(f"-> matching hex prefix  : 0x{mask_hex}")
    print(f"budget                  : {args.budget:,} tries")
    print()

    t0 = time.time()
    hits = 0
    first_full_hit = None
    prefix_bits = args.prefix_bits or 32
    prefix_bytes = prefix_bits // 8
    rem_bits = prefix_bits - prefix_bytes * 8

    for i in range(1, args.budget + 1):
        priv = secrets.token_bytes(32)
        addr = addr_from_priv(priv)
        rc = refcode(addr)

        # compare the first `prefix_bits` bits of rc and target
        ok = True
        if prefix_bytes and rc[:prefix_bytes] != target[:prefix_bytes]:
            ok = False
        if ok and rem_bits > 0:
            mask = (0xFF << (8 - rem_bits)) & 0xFF
            if (rc[prefix_bytes] & mask) != (target[prefix_bytes] & mask):
                ok = False
        if ok:
            hits += 1
            if rc == target and first_full_hit is None:
                first_full_hit = (priv.hex(), addr.hex(), rc.hex(), i, time.time() - t0)
                print(f"FULL HIT after {i:,} tries: priv={priv.hex()} addr=0x{addr.hex()} rc=0x{rc.hex()}")
        if i % 100_000 == 0:
            dt = time.time() - t0
            rate = i / dt
            eta32 = (2**32) / rate
            print(f"  [{i:>9,}] elapsed {dt:6.1f}s  rate {rate:>10,.0f} tries/s  ETA(2^32) ~ {eta32/3600:.1f} h")

    dt = time.time() - t0
    rate = args.budget / dt
    print()
    print(f"done: {args.budget:,} tries in {dt:.2f}s -> {rate:,.0f} tries/s (1 CPU core, Python)")
    print(f"prefix hits ({prefix_bits} bits) : {hits}")
    if first_full_hit:
        print(f"first full-32-bit hit   : {first_full_hit}")
    else:
        print(f"no full 32-bit hit within budget")
    print()
    print("extrapolation:")
    print(f"  expected tries for full 2^32 match : ~4.29e9")
    print(f"  wall-clock on this core            : ~{(2**32)/rate/3600:.1f} h = {(2**32)/rate/3600/24:.1f} days")
    print(f"  on a 16-core machine (Python)      : ~{(2**32)/rate/3600/16:.1f} h")
    print(f"  on a native C/Rust impl (10-100x)  : ~{(2**32)/rate/3600/16/50:.1f} h (16c, 50x speedup)")
    print(f"  GPU (billions keccak/s)            : seconds")

if __name__ == "__main__":
    main()
