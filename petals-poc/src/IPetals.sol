// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPetals {
    function buySeeds(bytes4 _ref) external payable;
    function sellPetals() external;
    function compoundAll() external;

    function updateRate(uint256 _rate) external;
    function updatePlatform(address _newPlatform) external;
    function updateOwner(address _newOwner) external;
    function updateFees(uint256 _devFeeVal, uint256 _refShare, uint256 _wlRefShare) external;
    function whitelistReferral(bytes4 _ref) external;

    function multipliers(address) external view returns (uint256);
    function petalsBalance(address) external view returns (uint256);
    function lastHireTime(address) external view returns (uint256);
    function seedsAccumulated(address) external view returns (uint256);
    function deposited(address) external view returns (uint256);
    function rewardsClaimed(address) external view returns (uint256);
    function userReferral(bytes4) external view returns (address);
    function wlReferrals(bytes4) external view returns (bool);

    function PETALS_TO_INCREASE_MULTIPLIER_BY_ONE() external view returns (uint256);
    function devFeeVal() external view returns (uint256);
    function refShare() external view returns (uint256);
    function wlRefShare() external view returns (uint256);

    function getMyPetals(address user) external view returns (uint256);
    function getPetalsSinceLastHireTime(address user) external view returns (uint256);
    function calculatePetalsSell(uint256 petalsAmount) external view returns (uint256);
    function calculateSeedsBuy(uint256 ethAmount, uint256 contractBalance) external view returns (uint256);
    function calculateSeedsBuySimple(uint256 ethAmount) external view returns (uint256);
    function petalsRewardsToEth(address user) external view returns (uint256);
}
