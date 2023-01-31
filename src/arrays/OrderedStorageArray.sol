// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title OrderedStorageArray
 * @author Lyra
 * @notice util functions for operations on ordered arrays stored in memory
 */

library UnorderedMemoryArray {
  
  /**
   * @dev Binary searches a sorted array and returns the leftNearest index
   * @param sortedArray sorted array of uint256s
   * @param target uint to find
   * @return leftNearest always returns the left nearest value
   * @return index returns the index of the left nearest value
   */
  function binarySearch(uint[] storage sortedArray, uint target) public view returns (uint leftNearest, uint index) {
    uint leftPivot;
    uint rightPivot;
    uint leftBound = 0;
    uint rightBound = sortedArray.length;
    uint i;
    while (true) {
      i = (leftBound + rightBound) / 2;
      leftPivot = sortedArray[i];
      rightPivot = sortedArray[i + 1];

      bool onRightHalf = leftPivot <= target;
      bool onLeftHalf = target <= rightPivot;

      // check if we've found the answer!
      if (onRightHalf && onLeftHalf) {
        return (target == rightPivot) 
            ? (rightPivot, i + 1) 
            : (leftPivot, i);
      }

      // otherwise start next search iteration
      if (!onRightHalf) {
        rightBound = i - 1;
      } else {
        leftBound = i + 1;
      }
    }
  }
}