/*
░█████╗░██████╗░██╗░░░██╗░██████╗░██████╗  ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔════╝██╔════╝  ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
███████║██████╦╝░╚████╔╝░╚█████╗░╚█████╗░  █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
██╔══██║██╔══██╗░░╚██╔╝░░░╚═══██╗░╚═══██╗  ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║░░██║██████╦╝░░░██║░░░██████╔╝██████╔╝  ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═════╝░╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/interfaces/IAbyssLockup.sol";

/**
 * Abyss Finance's AbyssLockup Contract
 * A smart contract that stores tokens requested for withdrawal, as well as through which tokens are transferred from/to user and between contracts.
 */
contract AbyssLockup is IAbyssLockup, Ownable {
    using SafeERC20 for IERC20;

    address public safeContract1;
    address public safeContract3;
    address public safeContract7;
    address public safeContract14;
    address public safeContract21;
    address public safeContract28;
    address public safeContract90;
    address public safeContract180;
    address public safeContract365;
    uint256 private _freeDeposits;

    struct Token {
        uint256 deposited;
        uint256 divFactor;
    }

    mapping (address => Token) private _tokens;

    constructor(uint256 freeDeposits_) {
        _freeDeposits = freeDeposits_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev See {IAbyssLockup-deposited}.
     */
    function deposited(address token) external override view returns (uint256) {
        return _tokens[token].deposited;
    }

    /**
     * @dev See {IAbyssLockup-divFactor}.
     */
    function divFactor(address token) external override view returns (uint256) {
        return _tokens[token].divFactor;
    }

    /**
     * @dev See {IAbyssLockup-freeDeposits}.
     */
    function freeDeposits() public override view returns (uint256) {
        return _freeDeposits;
    }

    // ACTION FUNCTIONS

    /**
     * @dev See {IAbyssLockup-externalTransfer}.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount, uint256 abyssRequired) external override onlyContract(msg.sender) returns (bool) {
        require(address(token) != address(0) && address(sender) != address(0) && address(recipient) != address(0), "AbyssLockup: variables cannot be 0");
        if (sender == address(this)) {
            IERC20(address(token)).safeTransfer(recipient, amount);
        } else {
            if (recipient != address(this) && abyssRequired > 0 && _freeDeposits > 0) {
                _freeDeposits = _freeDeposits - 1;
            }
            IERC20(address(token)).safeTransferFrom(sender, recipient, amount);
        }
        emit ExternalTransfer(msg.sender, token, sender, recipient, amount);
        return true;
    }

    function resetData(address token) external override onlyContract(msg.sender) returns (bool) {
        require(address(token) != address(0), "AbyssLockup: variable cannot be 0");
        delete _tokens[token].deposited;
        delete _tokens[token].divFactor;
        emit ResetData(msg.sender, token);
        return true;
    }

    function updateData(address token, uint256 balance, uint256 divFactor_) external override onlyContract(msg.sender) returns (bool) {
        require(address(token) != address(0), "AbyssLockup: variable cannot be 0");
        _tokens[token].deposited = balance;
        if (divFactor_ == 1) {
            delete _tokens[token].divFactor;
        } else if (divFactor_ > 0) {
            _tokens[token].divFactor = divFactor_;
        }
        emit UpdateData(msg.sender, token, balance, divFactor_);
        return true;
    }

    // ADMIN FUNCTIONS

    /**
     * @dev See {IAbyssLockup-setup}.
     */
    function setup(uint256 freeDeposits__) external override onlyOwner returns (bool) {
        _freeDeposits = freeDeposits__;
        emit Setup(msg.sender, freeDeposits__);
        return true;
    }

    /**
     * @dev See {IAbyssLockup-initialize}.
     */
    function initialize(address safe1, address safe3, address safe7, address safe14, address safe21,
                        address safe28, address safe90, address safe180, address safe365) external override onlyOwner returns (bool) {
        require(address(safe1) != address(0) && address(safe3) != address(0) && address(safe7) != address(0) &&
                address(safe14) != address(0) && address(safe21) != address(0) && address(safe28) != address(0) &&
                address(safe90) != address(0) && address(safe180) != address(0) && address(safe365) != address(0), "AbyssLockup: variables cannot be 0");
        require(address(safeContract1) == address(0), "AbyssLockup: already initialized");
        safeContract1 = safe1;
        safeContract3 = safe3;
        safeContract7 = safe7;
        safeContract14 = safe14;
        safeContract21 = safe21;
        safeContract28 = safe28;
        safeContract90 = safe90;
        safeContract180 = safe180;
        safeContract365 = safe365;
        emit Initialize(msg.sender, safe1, safe3, safe7, safe14, safe21, safe28, safe90, safe180, safe365);
        return true;
    }

    /**
     * @dev See {IAbyssLockup-withdrawLostTokens}.
     */
    function withdrawLostTokens(address token) external override onlyOwner returns (bool) {
        require(address(token) != address(0), "AbyssLockup: variable cannot be 0");
        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(this));

        if (_tokens[token].deposited == 0 && _tempBalance > 0) {
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, _tempBalance);
            emit WithdrawLostTokens(msg.sender, token, _tempBalance);
        }
        return true;
    }

    /**
     * @dev Modifier that allows usage only for `safeContract` smart contracts
    */
    modifier onlyContract(address account)  {
        require(account == address(safeContract1) || account == address(safeContract3) || account == address(safeContract7) ||
        account == address(safeContract14) || account == address(safeContract21) || account == address(safeContract28) ||
        account == address(safeContract90) || account == address(safeContract180) || account == address(safeContract365), "AbyssLockup: restricted area");
        _;
    }

}
