// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/arrays/QuickSort.sol";

/**
 * @dev for current `forge coverage` to work, i needs to call an external contract then invoke internal library
 */
contract QuickSortTester {
  function sort(uint[] memory data)
    external
    view
    returns (uint[] memory sortedIndices)
  {
    return QuickSort.sort(data);
  }

}

contract QuickSortTest is Test {
  QuickSortTester tester;

  function setUp() public {
    tester = new QuickSortTester();
  }

  function testSortEven() public {
    uint[] memory data = new uint[](6);
    data[0] = 10;
    data[1] = 5;
    data[2] = 3;
    data[3] = 100;
    data[4] = 7;
    data[5] = 1;

    uint[] memory sortedIndices = tester.sort(data);
    assertEq(sortedIndices[0], 5);
  }

  // function testSortOdd() {
  //   uint[] memory data = uint[](6);
  //   data = 
  // }
}