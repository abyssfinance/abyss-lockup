// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the AbyssLockup smart contract.
 */
interface IAbyssLockup {

    /**
     * @dev Returns amount requested for the `token` withdrawal
     * on all `safeContract` smart contracts.
     */
    function deposited(address token) external view returns (uint256);

    /**
     * @dev Returns divFactor requested for the specific `token`.
     */
    function divFactor(address token) external view returns (uint256);

    /**
     * @dev Returns the amount of free deposits left.
     */
    function freeDeposits() external returns (uint256);

    /**
     * @dev Moves `amount` tokens from the `sender` account to `recipient`.
     *
     * This function can be called only by `safeContract` smart contracts: {onlyContract} modifier.
     *
     * All tokens are moved only from `AbyssLockup`smart contract so only one
     * token approval is required.
     *
     * Sets divFactor and deposit amount of specific `token`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount, uint256 abyssRequired) external returns (bool);

    /**
     * @dev Removes deposited and divfactor data for specific token. Used by Safe smart contract only.
     */
    function resetData(address token) external returns (bool);

    /**
     * @dev Updates deposited and divfactor data for specific token. Used by Safe smart contract only.
     */
    function updateData(address token, uint256 balance, uint256 divFactor_) external returns (bool);

    /**
     * @dev Configurates smart contract allowing modification in the amount of
     * free deposits.
     */
    function setup(uint256 freeDeposits__) external returns (bool);

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * addresses for the `safeContract` smart contracts.
     *
     * All three of these values are immutable: they can only be set once.
     */
    function initialize(address safe1, address safe3, address safe7, address safe14, address safe21, address safe28,
                        address safe90, address safe180, address safe365) external returns (bool);

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract if such `token` is not yet deposited.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance requested to
     * withdrawals on all `safeContract` smart contracts.
     */
    function withdrawLostTokens(address token) external returns (bool);

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * another (`recipient`).
     */
    event ExternalTransfer(address indexed SmartContract, address token, address sender, address recipient, uint256 amount);

    /**
     * @dev Emitted when the `AbyssSafe` smart contract updates `divFactor` and information about
     * amount of tokens deposited.
     */
    event UpdateData(address indexed SmartContract, address token, uint256 balance, uint256 divFactor);

    /**
     * @dev Emitted when the `AbyssSafe` smart contract deletes `divFactor` and information about
     * amount of tokens deposited.
     */
    event ResetData(address indexed SmartContract, address token);

    /**
     * @dev Emitted when the `owner` of this contract chages the `freeDeposits`
     * variable.
     */
    event Setup(address indexed user, uint256 freeDeposits);

    /**
     * @dev Emitted when the `owner` of this contract initializes the smart contract
     * with addresses of all AbyssSafe contracts.
     */
    event Initialize(address indexed user, address safe1, address safe3, address safe7, address safe14, address safe21, address safe28, address safe90, address safe180, address safe365);

    /**
     * @dev Emitted when the `owner` of this contract withdraws tokens which
     * were accidentally sent to the smart contract.
     */
    event WithdrawLostTokens(address indexed user, address token, uint256 amount);
}
