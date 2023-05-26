//SPDX-License-Identifier: ISC
pragma solidity ^0.8.18;

// Libraries
import "src/decimals/SignedDecimalMath.sol";
import "src/decimals/DecimalMath.sol";
import "./FixedPointMathLib.sol";

import "forge-std/console2.sol";

/**
 * @title SVI
 * @author Lyra
 * @notice Contract to compute the vol for a given strike and set of SVI parameters
 */
library SVI {
  using DecimalMath for uint;
  using SignedDecimalMath for int;
  using FixedPointMathLib for uint;
  using FixedPointMathLib for int;

  error SVI_InvalidParameters();

  /**
   * @dev compute the vol for a given strike and set of SVI parameters
   * @param strike desired strike for which to get vol for, in range [0, inf)
   * @param a SVI parameter in range (-inf, inf)
   * @param b SVI parameter in range [0, inf)
   * @param rho SVI parameter in range (-1, 1)
   * @param m SVI parameter in range (-inf, inf)
   * @param sigma SVI parameter in range (0, inf)
   * @param forwardPrice forward price in range [0, inf)
   * @param tao time to expiry (in years) in range [0, inf)
   * @return vol
   */
  function getVol(uint strike, int a, uint b, int rho, int m, uint sigma, uint forwardPrice, uint64 tao)
    internal
    view
    returns (uint128)
  {
    // k = ln(strike / fwd)
    int k = FixedPointMathLib.ln(int(strike.divideDecimal(forwardPrice)));

    int k_sub_m = int(k) - m;

    // any number squared is positive, so we can cast to uint
    uint k_sub_m_sq = uint(k_sub_m.multiplyDecimal(k_sub_m)); // (k - m)^2
    uint sigma_sq = uint(sigma.multiplyDecimal(sigma)); // sigma^2

    // b * (sqrt((k - m)^2 + sigma^2) + rho * (k - m))
    int bPortion =
      int(b).multiplyDecimal(int(FixedPointMathLib.sqrt(k_sub_m_sq + sigma_sq)) + rho.multiplyDecimal(k_sub_m));

    // a + b * (sqrt((k - m)^2 + sigma^2) + rho * (k - m))
    int w = a + bPortion;

    if (w < 0) {
      revert SVI_InvalidParameters();
    }

    // sqrt((a + b * (sqrt((k - m)^2 + sigma^2) + rho * (k - m)))/tao)
    return uint128(FixedPointMathLib.sqrt(uint(w).divideDecimal(uint(tao))));
  }
}
