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
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../contracts/interfaces/IAbyssLockup.sol";

/**
 * Abyss Finance's AbyssSafe Contract
 * The main smart contract that is responsible for deposits and withdrawal of tokens.
 */
contract AbyssSafe12 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public tokenContract;
    IAbyssLockup public lockupContract;
    uint256 private _lockupTime;
    uint256 private _abyssRequired;

    /**
     * @dev The parameter responsible for global disabling and enabling of new deposits.
     */
    bool public disabled;

    /**
     * @dev Here we store data for each locked token address of a specific wallet.
     *
     * - deposited - Amount of deposited tokens.
     * - requested - Amount of requested tokens for withdrawing.
     * - timestamp - Token deposit time or token unlock time established at an active withdrawal request
     */
    struct Data {
        uint256 deposited;
        uint256 requested;
        uint256 timestamp;
    }

    /**
     * @dev Here we store data for every ever locked token on this smart contract.
     *
     * - disabled - A true value implies that this token cannot be deposited on the smart contract, while all other actions are allowed.
     * - approved - A true value implies that lockupContract is approved on transferFrom this smart contract.
     * - deposited - A total deposited token amount on the smart contract for the token address.
     * - requested - A total requested token amount from the smart contract.
     */
    struct Token {
        bool disabled;
        bool approved;
        uint256 deposited;
        uint256 requested;
    }

    mapping (address => mapping (address => Data)) private _data;
    mapping (address => Token) private _tokens;

    /**
     * @dev Stores the amount of Abyss required for withdrawals after deposit for the caller's address.
     */
    mapping (address => uint256) private _rates;

    constructor(address token, address lockup, uint256 lockupTime, uint256 abyssRequired) public {
        tokenContract = IERC20(address(token));
        lockupContract = IAbyssLockup(address(lockup));
        _lockupTime = lockupTime;
        _abyssRequired = abyssRequired;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Lockup delay (in seconds) after withdrawal request.
     */
    function lockupTime() public view returns (uint256) {
        return _lockupTime;
    }

    /**
     * @dev Amount of Abyss required for service usage.
     */
    function abyssRequired() public view returns (uint256) {
        return _abyssRequired;
    }

    /**
     * @dev Time of possible `token` withdrawal for the `account` if withdrawal request was made.
     * Time of `token` deposit if there were no withdrawal requests by the `account`.
     */
    function timestamp(address account, address token) public view returns (uint256) {
        return _data[account][token].timestamp;
    }

    /**
     * @dev Amount of `token` deposited by the `account`.
     */
    function deposited(address account, address token) public view returns (uint256) {
        return _data[account][token].deposited;
    }

    /**
     * @dev Amount of `token` requested for withdrawal by the `account`.
     */
    function requested(address account, address token) public view returns (uint256) {
        return _data[account][token].requested;
    }

    /**
     * @dev Total mount of `token` deposited to this smart contract.
     */
    function totalDeposited(address token) public view returns (uint256) {
        return _tokens[token].deposited;
    }

    /**
     * @dev Total mount of `token` requested for withdrawal from this smart contract.
     */
    function totalRequested(address token) public view returns (uint256) {
        return _tokens[token].requested;
    }

    // ACTION FUNCTIONS

    /**
     * @dev Moves `amount` of `token` from the caller's account to this smart contract.
     *
     * Requirements:
     *
     * - Contract is active and deposits for a specific token are not prohibited.
     * - Required Abyss amount is available on the account.
     * - Token smart contract has the right to move the tokens intended for deposit.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function deposit(address token, uint256 amount) public nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(disabled == false && _tokens[token].disabled == false, "AbyssSafe: disabled");

        uint256 _tempFreeDeposits;

        if (_abyssRequired > 0 && token != address(tokenContract)) {
            _tempFreeDeposits = lockupContract.freeDeposits();
            require(_tempFreeDeposits > 0 || tokenContract.balanceOf(msg.sender) >= _abyssRequired, "AbyssSafe: not enough Abyss");
        }

        require(IERC20(address(token)).allowance(msg.sender, address(lockupContract)) > amount, "AbyssSafe: you need to approve token first");
        require(IERC20(address(token)).balanceOf(msg.sender) >= amount && amount > 0, "AbyssSafe: you cannot lock this amount");

        /**
         * @dev Increases the number of deposited User tokens.
         */
        _data[msg.sender][token].deposited = SafeMath.add(_data[msg.sender][token].deposited, amount);

        /**
         * @dev Changes the total amount of deposited tokens.
         */
        _tokens[token].deposited = SafeMath.add(_tokens[token].deposited, amount);

        /**
         * @dev Writes down the cost of using the service so that any future amount requirement
         * increases won’t affect pre-existing users until they make a new deposit.
         */
        if (_tempFreeDeposits > 0) {
            _rates[msg.sender] = 0;
        } else {
            _rates[msg.sender] = _abyssRequired;
        }

        /**
         * @dev If this token has a timestamp earlier than the current block time, records the
         * current block time. Verification is done in order to prevent overwriting of `timestamp` for
         * the callers with active `token` withdrawal request.
         */
        if (_data[msg.sender][token].timestamp < block.timestamp) {
            _data[msg.sender][token].timestamp = block.timestamp;
        }

        /**
         * @dev Verifies that the `lockupContract` has permission to move a given token located on this contract.
         */
        if (_tokens[token].approved == false) {

            /**
             * @dev Add permission to move `token` from this contract for `lockupContract`.
             */
            SafeERC20.safeApprove(IERC20(address(token)), address(lockupContract), uint256(-1));
            /**
             * @dev Verify that the permission was correctly applied to exclude any future uncertainties.
             */
            require(IERC20(address(token)).allowance(address(this), address(lockupContract)) > 0, "AbyssSafe: allowance issue");
            /**
             * @dev Add verification flag to improve efficiency and avoid revisiting the token smart contract, for gas economy.
             */
            _tokens[token].approved = true;
        }

        emit Deposited(msg.sender, token, amount);

        /**
         * @dev Moves `amount` of `token` from the caller's account to this smart contract with the help of `lockupContract` smart contract.
         */
        lockupContract.externalTransfer(token, msg.sender, address(this), amount, _abyssRequired);
        return true;
    }

    /**
     * @dev Creates withdrawal request for the full amount of `token` deposited to this smart contract by the caller's account.
     *
     * Requirements:
     *
     * - Required Abyss amount is available on the account.
     * - There is no pending active withdrawal request for `token` by the caller's account.
     * - The caller has any amount of `token` deposited to this smart contract.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function withdrawalRequest(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested == 0, "AbyssSafe: you already requested");
        require(_data[msg.sender][token].deposited > 0, "AbyssSafe: nothing to withdraw");

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the decreasing direction.
         */
        _tokens[token].deposited = SafeMath.sub(_tokens[token].deposited, _data[msg.sender][token].deposited);

        /**
         * @dev Changes the total amount of requested `token by the sum of the withdrawing request in the increasing direction.
         */
        _tokens[token].requested = SafeMath.add(_tokens[token].requested, _data[msg.sender][token].deposited);

        uint256 _tempAmount = _data[msg.sender][token].deposited;

        /**
         * @dev The requested amount of the caller's tokens for withdrawal request becomes equal to their deposit of `token`.
         */
        _data[msg.sender][token].requested = _data[msg.sender][token].deposited;

        /**
         * @dev Resets the caller's token deposit.
         */
        delete _data[msg.sender][token].deposited;

        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(this));

        if (_tempAmount > _tempBalance) {

            /**
             * @dev Protection against unforeseen situations such as when the amount of withdrawal
             * requested is greater than the amount of `token` balance on this smart contract.
             * If caller's deposit is more than the real balance of `token` on this smart contract,
             * then only remaining `token` balance will be transferred to 'lockupContract' smart contract.
             */
            _tempAmount = _tempBalance;
        }

        /**
         * @dev Sets a date for `lockupTime` seconds from the current date.
         */
        _data[msg.sender][token].timestamp = SafeMath.add(block.timestamp, _lockupTime);

        emit Requested(msg.sender, token, _tempAmount);

        if (_tempBalance > 0) {

            /**
             * @dev If `token` balance on this smart contract is greater than zero,
             * sends tokens to the 'lockupContract' smart contract.
             */
            lockupContract.externalTransfer(token, address(this), address(lockupContract), _tempAmount, 0);
        }
        return true;
    }

    /**
     * @dev Cancels withdrawal request for the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - There is a pending active withdrawal request for `token` by the caller's account.
     */
    function cancelWithdraw(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: nothing to cancel");

        uint256 _tempAmount = _data[msg.sender][token].requested;
        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempAmount > _tempBalance) {
            /**
             * Protection against unforeseen situations such as cancelation of withdrawal request and `token` reimbursement
             * to the smart contract in a sum greater than the token balance of the 'lockupContract' smart contract.
             * If the caller's requested amount is more than the real balance of `token` on the 'lockupContract' smart contract,
             * then only remaining `token` balance will be transferred back to this smart contract.
             */
            _tempAmount = _tempBalance;
        }

        /**
         * @dev Changes the total amount of deposited `token` by the amount of withdrawing request in the increasing direction.
         */
        _tokens[token].deposited = SafeMath.add(_tokens[token].deposited, _tempAmount);

        /**
         * @dev Changes the total amount of requested `token` by the cancelation withdrawal amount in the decreasing direction.
         */
        _tokens[token].requested = SafeMath.sub(_tokens[token].requested, _tempAmount);

        /**
         * @dev Taking withdrawal request cancellation into account, restores the caller's `token` balance.
         */
        _data[msg.sender][token].deposited = SafeMath.add(_data[msg.sender][token].deposited, _tempAmount);

        /**
         * @dev Resets information on the number of `token` requested by the caller for withdrawal request.
         */
        delete _data[msg.sender][token].requested;

        /**
         * @dev Resets the date when `token` can be withdrawn by setting the current block time.
         */
        _data[msg.sender][token].timestamp = block.timestamp;

        emit CancelWithdraw(msg.sender, token, _tempAmount);

        if (_tempBalance > 0) {

            /**
             * @dev If the 'lockupContract' smart contract `token` balance is greater than zero,
             * transfer tokens back to the this smart contract.
             */
            lockupContract.externalTransfer(token, address(lockupContract), address(this), _tempAmount, 0);
        }
        return true;
    }

    /**
     * @dev Withdraws the full amount of `token` requested from this smart contract by the caller's account.
     *
     * Requirement:
     *
     * - Required Abyss amount is available on the account.
     * - There is pending active withdrawal request for `token` by the caller's account.
     * - Required amount of time has already passed since withrawal request execution.
     * - User’s balance is greater than zero and greater than the amount they intend to deposit.
     */
    function withdraw(address token) external nonReentrant isAllowed(msg.sender, token) returns (bool) {
        require(
            _rates[msg.sender] == 0 ||
            token == address(tokenContract) ||
            tokenContract.balanceOf(msg.sender) >= _rates[msg.sender],
            "AbyssSafe: not enough Abyss");
        require(_data[msg.sender][token].requested > 0, "AbyssSafe: request withdraw first");
        require(_data[msg.sender][token].timestamp < block.timestamp, "AbyssSafe: patience you must have!");

        uint256 _tempAmount = _data[msg.sender][token].requested;

        /**
         * @dev Changes the total amount of requested `token` for withdrawing by the sum of the withdraw in the decreasing direction.
         */
        _tokens[token].requested = SafeMath.sub(_tokens[token].requested, _tempAmount);

        /**
         * @dev Changes the amount of the caller's requested `token` in the decreasing direction.
         */
        _data[msg.sender][token].requested = SafeMath.sub(_data[msg.sender][token].requested, _tempAmount);

        uint256 _tempBalance = IERC20(address(token)).balanceOf(address(lockupContract));

        if (_tempAmount > _tempBalance) {

            /**
             * @dev Protection against unforeseen situations such as when withdrawal amount is greater
             * than `token` balance on the 'lockupContract' smart contract. If the caller's withdrawal amount
             * is more than the real balance of `token` on the 'lockupContract' smart contract, then
             * only remaining `token` balance will be transferred to the caller's address.
             */
            _tempAmount = _tempBalance;
        }

        /**
         * @dev Verifies that the caller has not deposited any `token` after withdrawal request was made.
         */
        if (_data[msg.sender][token].deposited == 0) {

            /**
             * @dev If there are no deposited tokens left, reset the unblocking time to zero.
             */
            delete _data[msg.sender][token].timestamp;

        } else {

            /**
             * @dev If there are deposited tokens left, set the time of the current block.
             */
            _data[msg.sender][token].timestamp = block.timestamp;
        }

        emit Withdrawn(msg.sender, token, _tempAmount);

        if (_tempBalance > 0) {

             /**
              * @dev If the 'lockupContract' smart contract `token` balance is greater than zero,
              * withdraw tokens to the caller's address.
              */
            lockupContract.externalTransfer(token, address(lockupContract), msg.sender, _tempAmount, 0);
        }
        return true;

    }

    // ADMIN FUNCTIONS

    /**
     * @dev Initializes configuration of a given smart contract, with a specified
     * address for the `lockupContract` smart contract.
     *
     * This value is immutable: it can only be set once.
     */
    function initialize(address lockupContract_) external onlyOwner returns (bool) {
        require(address(lockupContract) == address(0), "AbyssSafe: already initialized");
        lockupContract = IAbyssLockup(lockupContract_);
        return true;
    }

    /**
     * @dev Configurates smart contract allowing modification in the amount of
     * required Abyss to use the smart contract.
     *
     * NOTE: The price for pre-existing users will remain unchanged until
     * a new token deposit is made. This aspect has been considered to prevent
     * possibility of increase pricing for already made deposits.
     *
     * Also, this function allows disabling of deposits, both globally and for a specific token.
     */
    function setup(address token, bool tokenDisabled, bool globalDisabled, uint256 abyssRequired_) external isManager(msg.sender) returns (bool) {
        disabled = globalDisabled;
        if (token != address(this)) {
            _tokens[token].disabled = tokenDisabled;
        }
        _abyssRequired = abyssRequired_;
        return true;
    }

    /**
     * @dev Allows the `owner` to assign managers who can use the setup function.
     */
    function setManager(address manager) external onlyOwner returns (bool) {


        if (_tokens[manager].approved == false) {
            _tokens[manager].approved = true;
        } else {
            _tokens[manager].approved = false;
        }
        return true;
    }

    /**
     * @dev A function that allows the `owner` to withdraw any locked and lost tokens
     * from the smart contract.
     *
     * NOTE: Embedded in the function is verification that allows for token withdrawal
     * only if the token balance is greater than the token balance deposited on the smart contract.
     */
    function withdrawLostTokens(address token) external onlyOwner returns (bool) {
        uint256 _tempBalance1 = IERC20(address(token)).balanceOf(address(this));
        uint256 _tempAmount;

        if (_tempBalance1 > _tokens[token].deposited) {
            _tempAmount = SafeMath.sub(_tempBalance1, _tokens[token].deposited);
            SafeERC20.safeTransfer(IERC20(address(token)), msg.sender, _tempAmount);
        }
        return true;
    }

    /**
     * @dev Modifier that prohibits execution of this smart contract from `token` address
     */
    modifier isAllowed(address account, address token) {
        require(account != token, "AbyssSafe: you shall not pass!");
        _;
    }

    /**
     * @dev Modifier that allows usage only for managers chosen by the `owner`.
    */
    modifier isManager(address account) {
        require(_tokens[account].approved || account == owner(), "AbyssSafe: you shall not pass!");
        _;
    }

    event Deposited(address indexed user, address token, uint256 amount);
    event Requested(address indexed user, address token, uint256 amount);
    event CancelWithdraw(address indexed user, address token, uint256 amount);
    event Withdrawn(address indexed user, address token, uint256 amount);
}
