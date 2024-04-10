// SPDX-License-Identifier: MIT
// @notice We intentionally want to leave this as floating point so others can use it as a library.
pragma solidity ^0.8.3;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @notice People taking my course: Don't cheat and look at the answers!
/// @author Math Masters
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library MathMasters {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MathMasters__FactorialOverflow();
    error MathMasters__MulWadFailed();
    error MathMasters__DivWadFailed();
    error MathMasters__FullMulDivFailed();

    /*//////////////////////////////////////////////////////////////
    /*                         CONSTANTS                          */
    //////////////////////////////////////////////////////////////*/
    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18; // WAD just means 18 decimal places

    // History lesson: WAD, RAY, and RAD were introduced in DappHub/DappTools/the DS test system and popularized by MakerDAO's original DAI system. The names sort of stuck.
    // https://github.com/dapphub
    // wad: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
    // ray: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
    // rad: fixed point decimal with 45 decimals (result of integer multiplication with a wad and a ray)

    /*//////////////////////////////////////////////////////////////
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    //////////////////////////////////////////////////////////////*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y,                               // if y == 0 continue, else fail due to overflow if gt != 0
                    gt(x,                           // check if x * y will overflow in 256 bits
                        div(                        // div uint256 max / input y
                            not(0), y)))            // not -> flip all bits e.g. 0x00 ... 0xff ...
            {                           
                //overriding free memory pointer!!
                // @audit blank error message
                // @audit wrong error selector, should be 0xa56044f7
                mstore(0x40, 0xbac65e5b)// `MathMasters__MulWadFailed()`.
                revert(0x1c, 0x04)      // 0x1c = 28 bytes offset, revert with 4 bytes value of named error 0xbac65e5b
            }
            z := div(mul(x, y), WAD)    // looks good, due to checks above, auto round down
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) { //init z = 0
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {  //same as above, check for overflow if gt != 0
                // @audit wrong error selector, should be 0xa56044f7
                // same issues as above, override fmp
                mstore(0x40, 0xbac65e5b) // `MathMasters__MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            // @audit this is not needed, rounds up too much
            if iszero(
                sub(
                    div(
                        add(z, x), y),  //  0 + x / y - 1 == 0 ?
                                        1)) 
                                        {   // true x += 1
                                            // else continue
                                            x := add(x, 1) 
                                        }

            z := add(
                    iszero(
                        iszero(
                            mod(
                                mul(x, y), WAD) // x * y % 1e18 ... remainder
                            )                   // remainder == 0 ?
                        ),                      // remainder != 0 ?
                        div(                    // if not divide in evenly ... add 1 to result
                            mul(x, y), WAD)
                    )
        }
    }

    /*//////////////////////////////////////////////////////////////
    /*                  GENERAL NUMBER UTILITIES                  */
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := 181

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.
            let r := shl(7, lt(87112285931760246646623899502532662132735, x))
            r := or(r, shl(6, lt(4722366482869645213695, shr(r, x))))
            r := or(r, shl(5, lt(1099511627775, shr(r, x))))
            // Correct: 16777215 0xffffff               // better to use hexadecimal instead of decimal
            r := or(r, shl(4, lt(16777002, shr(r, x)))) //should be 0xffffffff not 0xffffff2a
            z := shl(shr(1, r), z)

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }
}
