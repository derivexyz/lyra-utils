// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "src/math/SVI.sol";

struct SVITestParams {
  uint64 tau;
  int a;
  uint b;
  int rho;
  int m;
  uint sigma;
  uint forwardPrice;
}

/**
 * @dev for current `forge coverage` to work, it needs to call an external contract then invoke internal library
 */
contract SVITester {
  function getVol(uint strike, SVITestParams memory params) external pure returns (uint vol) {
    uint res =
      SVI.getVol(strike, params.a, params.b, params.rho, params.m, params.sigma, params.forwardPrice, params.tau);
    return res;
  }
}

contract SVITest is Test {
  SVITester tester;

  function setUp() public {
    tester = new SVITester();
  }

  function testGetVols() public {
    SVITestParams memory params = SVITestParams({
      tau: 0.00821917808219178e18,
      a: 0.00821917808219178e18,
      b: 0.01232876712328767e18,
      rho: -int(0.000821917808219178e18),
      m: -int(0.000410958904109589e18),
      sigma: 0.000410958904109589e18,
      forwardPrice: 1800e18
    });

    uint[] memory strikes = new uint[](4);
    strikes[0] = 1500e18;
    strikes[1] = 1800e18;
    strikes[2] = 2100e18;
    strikes[3] = 2400e18;

    uint[] memory results = new uint[](4);
    results[0] = 1.1283132838354804e18;
    results[1] = 1.0004355395636404e18;
    results[2] = 1.1097985052091757e18;
    results[3] = 1.1965721054381622e18;
    for (uint i = 0; i < 1; i++) {
      uint vol = tester.getVol(strikes[i], params);
      assertApproxEqAbs(vol, results[i], 1e4);
    }

    params = SVITestParams({
      tau: 0.038356164383561646e18,
      a: 0.027616438356164386e18,
      b: 0.041424657534246574e18,
      rho: 0.003452054794520548e18,
      m: 0.001726027397260274e18,
      sigma: 0.000345205479452055e18,
      forwardPrice: 1805e18
    });

    results[0] = 0.9597244734120128e18;
    results[1] = 0.8513856076969522e18;
    results[2] = 0.939244986304054e18;
    results[3] = 1.0133571334275668e18;

    for (uint i = 0; i < 4; i++) {
      uint vol = tester.getVol(strikes[i], params);
      assertApproxEqAbs(vol, results[i], 1e4);
    }

    params = SVITestParams({
      tau: 0.2465753424657534e18,
      a: 0.17753424657534247e18,
      b: 0.17753424657534247e18,
      rho: 0.05917808219178082e18,
      m: 0.02958904109589041e18,
      sigma: 0.0216986301369863e18,
      forwardPrice: 1830e18
    });

    results[0] = 0.9356728218442784e18;
    results[1] = 0.8687530747337932e18;
    results[2] = 0.8966269017413266e18;
    results[3] = 0.9512721744218694e18;

    for (uint i = 0; i < 4; i++) {
      uint vol = tester.getVol(strikes[i], params);
      assertApproxEqAbs(vol, results[i], 1e4);
    }
  }

  function testRevertsForBadParams() public {
    SVITestParams memory params = SVITestParams({
      tau: 0.00821917808219178e18,
      a: -10e18,
      b: 0.01232876712328767e18,
      rho: -int(0.000821917808219178e18),
      m: -int(0.000410958904109589e18),
      sigma: 0.000410958904109589e18,
      forwardPrice: 1800e18
    });
    vm.expectRevert(SVI.SVI_InvalidParameters.selector);
    tester.getVol(1800e18, params);
  }

  function testZeroStrikeVolIsZero() public {
    uint forwardPrice = 2000e18;
    SVITestParams memory params = _getDefaultSVIParams(forwardPrice);
    uint vol = tester.getVol(0, params);
    assertEq(vol, 0);
  }

  function testRevertWhenForwardPriceIsZero() public {
    SVITestParams memory params = _getDefaultSVIParams(0);
    vm.expectRevert(SVI.SVI_NoForwardPrice.selector);
    uint vol = tester.getVol(1800e18, params);
  }

  // function testMaxVarInSVIShouldBeCapped() public {
  //   SVITestParams memory params = SVITestParams({
  //     a: -0.041e18,
  //     b: 0.1331e18,
  //     sigma: 0.4153e18,
  //     rho: 0.306e18,
  //     m: 0.3586e18,
  //     tau: 0.082e18,
  //     forwardPrice: 1700e18
  //   });
  //   uint strike = 3000_000e18;
  //   uint vol = tester.getVol(strike, params);
  // }

  function testSmallStrike() public {
    uint strike = 1;
    uint forwardPrice = 1800e18;
    SVITestParams memory params = _getDefaultSVIParams(forwardPrice);

    uint vol = tester.getVol(strike, params);
    assertEq(vol / 1e18, 2); // 200%
  }

  function testFuzzGetVol(uint strike, uint forwardPrice, uint64 tau) public {
    // fuzz test the get vol function will not revert
    vm.assume(tau > 0);
    vm.assume(tau < 5e18); // expiry < 5 years
    vm.assume(forwardPrice < 10000_00e18);
    vm.assume(forwardPrice != 0);
    vm.assume(strike < 1000_000e18);

    SVITestParams memory params = _getDefaultSVIParams(forwardPrice);
    params.tau = tau;

    uint vol = tester.getVol(strike, params);

    // todo: what are the bonds?
    // assert(vol < 10e18);
  }

  function _getDefaultSVIParams(uint forwardPrice) internal view returns (SVITestParams memory params) {
    params = SVITestParams({
      a: 0.00821917808219178e18,
      b: 0.01232876712328767e18,
      rho: -int(0.000821917808219178e18),
      m: -int(0.000410958904109589e18),
      sigma: 0.000410958904109589e18,
      tau: 0.00821917808219178e18,
      forwardPrice: forwardPrice
    });
  }
}
