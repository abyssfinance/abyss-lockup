// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the AFLockup smart contract.
 */
interface ILockup {

    /**
     * @dev Moves `amount` tokens from the `sender` account to `recipient`.
     *
     * This function can be called only by `safeContract` smart contracts: {onlyContract} modifier.
     *
     * All tokens are moved only from `AFLockup`smart contract so only one
     * token approval is required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount) external returns (bool);

}
