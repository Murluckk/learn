// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Website: https://petals.farm
// X: https://x.com/PetalsFarmETH
// Telegram: https://t.me/PetalsFarm


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Petals is ReentrancyGuard {

    uint256 public PETALS_TO_INCREASE_MULTIPLIER_BY_ONE = 100 * 1 days / 25;  //25% daily rate
    uint256 internal constant PSN = 10_000;
    uint256 internal constant PSNH = 5_000;

    uint256 public devFeeVal = 5; //5%
    uint256 public refShare = 25; //25%
    uint256 public wlRefShare = 25; //25%

    uint256 internal constant MAX_DEV_FEE = 10;
    uint256 internal constant MAX_REF_SHARE = 30;
    uint256 internal constant MAX_WL_REF_SHARE = 30;
    uint256 internal constant DENOMINATOR = 100;

    mapping (address => uint256) public multipliers;
    mapping (address => uint256) public petalsBalance;
    mapping (address => uint256) public lastHireTime;

    mapping (address => uint256) public seedsAccumulated;
    mapping (address => uint256) public deposited;
    mapping (address => uint256) public rewardsClaimed;

    mapping(bytes4 => address) public userReferral;
    mapping (bytes4 => bool) public wlReferrals;

    uint256 private marketPetals = 10_0000 * PETALS_TO_INCREASE_MULTIPLIER_BY_ONE;

    address private platform;
    address private owner;

    constructor(address _owner, address _platform) {
        owner = _owner;
        platform = _platform;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _compound(uint256 _petalsToCompound) internal  {
        uint256 myPetalRewards = getPetalsSinceLastHireTime(msg.sender);
        petalsBalance[msg.sender] += myPetalRewards;
        seedsAccumulated[msg.sender] += myPetalRewards;

        require(_petalsToCompound <= petalsBalance[msg.sender], "Not enough Petals");

        uint256 newMultipliers = _petalsToCompound/PETALS_TO_INCREASE_MULTIPLIER_BY_ONE;

        petalsBalance[msg.sender] -= (PETALS_TO_INCREASE_MULTIPLIER_BY_ONE * newMultipliers);
        multipliers[msg.sender] += newMultipliers;

        lastHireTime[msg.sender] = block.timestamp;

        marketPetals += (PETALS_TO_INCREASE_MULTIPLIER_BY_ONE * newMultipliers) * 20 / DENOMINATOR; //market boost: add 20% to the market
    }

    function compoundAll() public nonReentrant {
        uint256 myPetalRewards = getPetalsSinceLastHireTime(msg.sender);
        petalsBalance[msg.sender] += myPetalRewards;
        seedsAccumulated[msg.sender] += myPetalRewards;

        uint256 newMultipliers = petalsBalance[msg.sender]/PETALS_TO_INCREASE_MULTIPLIER_BY_ONE;

        petalsBalance[msg.sender] -= (PETALS_TO_INCREASE_MULTIPLIER_BY_ONE * newMultipliers);
        multipliers[msg.sender] += newMultipliers;

        lastHireTime[msg.sender] = block.timestamp;

        marketPetals += (PETALS_TO_INCREASE_MULTIPLIER_BY_ONE * newMultipliers) * 20 / DENOMINATOR; //market boost: add 20% to the market
    }

    function sellPetals() public nonReentrant {
        uint256 hasPetals = getMyPetals(msg.sender);
        uint256 petalsValue = calculatePetalsSell(hasPetals);
        uint256 fee = devFee(petalsValue);

        petalsBalance[msg.sender] = 0;
        lastHireTime[msg.sender] = block.timestamp;
        marketPetals += hasPetals;
        rewardsClaimed[msg.sender] += petalsValue - fee;

        payable(platform).transfer(fee);
        payable(msg.sender).transfer(petalsValue - fee);

        emit PetalsSold(petalsValue - fee, msg.sender);
    }

    function buySeeds(bytes4 _ref) external payable nonReentrant {
        _buySeeds(_ref, msg.value);
        emit SeedsBought(msg.value, msg.sender, _ref);
    }

    function _buySeeds(bytes4 _ref, uint256 ethAmount) private {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes4 refCode = bytes4(hash);
        if (userReferral[refCode] == address(0)) {
            userReferral[refCode] = msg.sender;
            emit ReferralGenerated(refCode, msg.sender);
        }

        uint256 seedsBought = calculateSeedsBuy(ethAmount, address(this).balance - ethAmount);
        seedsBought -= devFee(seedsBought);
        uint256 fee = devFee(ethAmount);

        payable(platform).transfer(fee);

        petalsBalance[msg.sender] += seedsBought;
        seedsAccumulated[msg.sender] += seedsBought;
        deposited[msg.sender] += ethAmount;

        address _refAddr = userReferral[_ref];
        if (_refAddr != address(0) && _refAddr != msg.sender) {
            uint256 share = wlReferrals[_ref] ? wlRefShare : refShare;
            petalsBalance[_refAddr] += seedsBought * share / DENOMINATOR;
        }

        _compound(seedsBought);

    }

    function petalsRewardsToEth(address user) external view returns(uint256) {
        uint256 hasPetals = getMyPetals(user);
        uint256 petalsValue;

        try this.calculatePetalsSell(hasPetals) returns (uint256 value) {petalsValue=value;} catch{}

        return petalsValue;
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return (PSN * bs) / (PSNH + (PSN * rs + PSNH * rt) / rt);
    }

    function calculatePetalsSell(uint256 petalsAmount) public view returns(uint256) {
        return calculateTrade(petalsAmount, marketPetals, address(this).balance);
    }

    function calculateSeedsBuy(uint256 ethAmount, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(ethAmount, contractBalance, marketPetals);
    }

    function calculateSeedsBuySimple(uint256 ethAmount) external view returns(uint256) {
        return calculateSeedsBuy(ethAmount, address(this).balance);
    }

    function devFee(uint256 amount) private view returns(uint256) {
        return amount * devFeeVal / DENOMINATOR;
    }

    function getMyPetals(address user) public view returns(uint256) {
        return petalsBalance[user] + getPetalsSinceLastHireTime(user);
    }

    function getPetalsSinceLastHireTime(address user) public view returns(uint256) {
        return Math.min(PETALS_TO_INCREASE_MULTIPLIER_BY_ONE, block.timestamp - lastHireTime[user]) * multipliers[user];
    }

    function getSeedsAccumulationValue(address user) public view returns(uint256) {
        return Math.min(PETALS_TO_INCREASE_MULTIPLIER_BY_ONE, block.timestamp - lastHireTime[user]);
    }

    function updatePlatform(address _newPlatform) public onlyOwner {
        platform = payable(_newPlatform);
    }

    function updateRate(uint256 _rate) public onlyOwner {
        PETALS_TO_INCREASE_MULTIPLIER_BY_ONE = _rate;
    }

    function updateFees(uint256 _devFeeVal, uint256 _refShare, uint256 _wlRefShare) public onlyOwner {
        require(_devFeeVal <= MAX_DEV_FEE, "Max dev fee exceeded");
        require(_refShare <= MAX_REF_SHARE, "Max ref share exceeded");
        require(_wlRefShare <= MAX_WL_REF_SHARE, "Max wl ref share exceeded");

        devFeeVal = _devFeeVal;
        refShare =_refShare;
        wlRefShare = _wlRefShare;
    }

    function updateOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function whitelistReferral(bytes4 _ref) public onlyOwner {
        wlReferrals[_ref] = true;
    }

    receive() external payable {}

    event ReferralGenerated(bytes4 refCode, address _user);
    event SeedsBought(uint256 _amount, address _user, bytes4 _ref);
    event PetalsSold(uint256 _amount, address _user);

}
