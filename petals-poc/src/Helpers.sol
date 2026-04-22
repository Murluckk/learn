// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Helper used by H2 test: sends all its balance to `target` via SELFDESTRUCT,
/// bypassing receive/fallback. Forces ETH into the target even if target has
/// no receive function — works because SELFDESTRUCT forwards ETH unconditionally.
contract ETHDonor {
    function donate(address payable target) external payable {
        selfdestruct(target);
    }
}

/// Helper used by H4 test: a contract that cannot receive ETH through a
/// 2300-gas `.transfer` stipend. No receive(), no fallback() -> .transfer reverts.
contract NonPayable {
    // Intentionally empty. Any incoming ETH from `.transfer` reverts.
}

/// Helper used by H4 alt variant: burns >2300 gas in its receive() so
/// `.transfer` also fails even though the address is "payable".
contract GasBomb {
    uint256 public x;
    receive() external payable {
        for (uint256 i = 0; i < 1000; ++i) {
            x = x + 1;
        }
    }
}
