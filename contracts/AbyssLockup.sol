/*
░█████╗░██████╗░██╗░░░██╗░██████╗░██████╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔════╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╦╝░╚████╔╝░╚█████╗░╚█████╗░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗░╚═══██╗  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██████╦╝░░░██║░░░██████╔╝██████╔╝  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Abyss Finance's AbyssLockup Contract
 * A smart contract that stores tokens requested for withdrawal, as well as through which tokens are transferred from/to user and between contracts.
 */
contract AbyssLockup is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public safeContract3;
    address public safeContract6;
    address public safeContract12;
    uint256 private _freeDeposits;

    mapping (address => uint256) private _deposits;

    constructor(uint256 freeDeposits) public {
        _freeDeposits = freeDeposits;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Returns amount requested for the `token` withdrawal
     * on all `safeContract` smart contracts.
     */
    function deposited(address token) external view returns (uint256) {
        return _deposits[token];
    }

    /**
     * @dev See {IAbyssLockup-freeDeposits}.
     */
    function freeDeposits() public view returns (uint256) {
        return _freeDeposits;
    }

    // ACTION FUNCTIONS

    /**
     * @dev See {IAbyssLockup-externalTransfer}.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount, uint256 abyssRequired) external onlyContract(msg.sender) returns (bool) {
        if (sender == address(this)) {
            _deposits[token] = SafeMath.sub(_deposits[token], amount);
            IERC20(address(token)).safeTransfer(recipient, amount);
        } else {
            if (recipient == address(this)) {
                _deposits[token] = SafeMath.add(_deposits[token], amount);
            } else if (abyssRequired > 0) {
                _freeDeposits = SafeMath.sub(_freeDeposits, 1);
            }
            IERC20(address(token)).safeTransferFrom(sender, recipient, amount);
        }
        return true;
    }

    // ADMIN FUNCTIONS

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * addresses for the `safeContract` smart contracts.
     *
     * All three of these values are immutable: they can only be set once.
     */
    function initialize(address safe3, address safe6, address safe12) external onlyOwner returns (bool) {
        require(address(safeContract3) == address(0), "AbyssLockup: already initialized");
        safeContract3 = safe3;
        safeContract6 = safe6;
        safeContract12 = safe12;
        return true;
    }

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance requested to
     * withdrawals on all `safeContract` smart contracts.
     */
    function withdrawLostTokens(address token) external onlyOwner returns (bool) {
        uint256 _tempBalance1 = IERC20(address(token)).balanceOf(address(this));

        if (_tempBalance1 > _deposits[token]) {
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, SafeMath.sub(_tempBalance1, _deposits[token]));
        }
        return true;
    }

    /**
     * @dev Modifier that allows usage only for `safeContract` smart contracts
    */
    modifier onlyContract(address account)  {
        require(account == address(safeContract3) || account == address(safeContract6) || account == address(safeContract12), "AbyssLockup: restricted area");
        _;
    }
}
