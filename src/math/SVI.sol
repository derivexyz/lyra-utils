//SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

// Libraries
import "src/decimals/SignedDecimalMath.sol";
import "src/decimals/DecimalMath.sol";
import "./FixedPointMathLib.sol";
import "./IntLib.sol";

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
  error SVI_NoForwardPrice();

  /// @dev Upper bound of of w in SVI
  int internal constant MAX_TOTAL_VAR = 25e18;

  int internal constant SHORT_DATE_k = 0.3e18;
  int internal constant LONG_DATE_k = -0.3e18;

  int internal constant ABS_K_MAX = 2.5e18;
  int internal constant ABS_K_MIN = -2.5e18;

  int internal constant TAU_MULTIPLIER = 3e18;

  /**
   * @dev compute the vol for a given strike and set of SVI parameters
   * @param strike desired strike for which to get vol for, in range [0, inf)
   * @param a SVI parameter in range (-inf, inf)
   * @param b SVI parameter in range [0, inf)
   * @param rho SVI parameter in range (-1, 1)
   * @param m SVI parameter in range (-inf, inf)
   * @param sigma SVI parameter in range (0, inf)
   * @param forwardPrice forward price in range [0, inf)
   * @param tau time to expiry (in years) in range [0, inf)
   * @return vol
   */
  function getVol(uint strike, int a, uint b, int rho, int m, uint sigma, uint forwardPrice, uint64 tau)
    internal
    pure
    returns (uint)
  {
    if (strike == 0) return 0;
    if (forwardPrice == 0) revert SVI_NoForwardPrice();

    // k = ln(strike / fwd)
    int sk = int(strike.divideDecimal(forwardPrice));
    int k;
    if (sk == 0) {
      k = ABS_K_MIN;
    } else {
      // k = ln (strike / fwd)
      // restrict k value to be within a certain range
      k = FixedPointMathLib.ln(int(strike.divideDecimal(forwardPrice)));
      int tauFactor = int(FixedPointMathLib.sqrt(uint(tau))).multiplyDecimal(TAU_MULTIPLIER);
      int k_max = IntLib.min(ABS_K_MAX, IntLib.max(SHORT_DATE_k, tauFactor));
      int k_min = IntLib.max(ABS_K_MIN, IntLib.min(LONG_DATE_k, -tauFactor));
      k = IntLib.min(k_max, IntLib.max(k_min, k));
    }

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
    } else if (w > MAX_TOTAL_VAR) {
      w = MAX_TOTAL_VAR;
    }

    // sqrt((a + b * (sqrt((k - m)^2 + sigma^2) + rho * (k - m)))/tau)
    uint vol = FixedPointMathLib.sqrt(uint(w).divideDecimal(uint(tau)));
    return vol;
  }
}
