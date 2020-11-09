/**
        .NMMMMMMMo          :MMMMN`
        hMMMMMMMMM-         :MMMMN`
       +MMMMmdMMMMd`        :MMMMN`
      .NMMMM:`mMMMMo        :MMMMN`-+syhys+-    -ooooo.        -oooo+`   ./oyhhhyo/.        `:osyhhys+-
      hMMMMs  /MMMMM-       :MMMMMmMMMMMMMMMm/   yMMMMd`      .NMMMMo  :dMMMMMMMMMMMd:    .yMMMMMMMMMMMm+
     +MMMMm`   hMMMMd`      :MMMMMMMmyyhNMMMMMy  `hMMMMd`    `dMMMMs  :MMMMMdysydMMMMM:  `mMMMMmysyhNMMMMs
    .NMMMM/    .NMMMMo      :MMMMMd-     /NMMMM+  `dMMMMh`   hMMMMh   oMMMMN/-.  /ssss/  .MMMMMo-.` -sssss
    hMMMMMMMMMMMMMMMMM-     :MMMMM.       oMMMMd   `dMMMMy  sMMMMd`   .mMMMMMMMMNmhs:     yMMMMMMMMNmds/`
   +MMMMMMMMMMMMMMMMMMd`    :MMMMN`       /MMMMm`   .mMMMMs+MMMMm.     `+hNMMMMMMMMMMm-    :ymMMMMMMMMMMNo
  .NMMMMhsssssssssNMMMMo    :MMMMM:       yMMMMh     .mMMMMMMMMN-    `.....`.-:+odMMMMm` .....`.-:/ohMMMMM:
  hMMMMd          oMMMMM-   :MMMMMN+`   .yMMMMM:      .mMMMMMMM:     .MMMMM+`    /MMMMN. hMMMMh.    .mMMMM+
 +MMMMN-          `dMMMMd`  :MMMMMMMMNmNMMMMMN/        -NMMMMM+       +MMMMMNmmmNMMMMMo  -mMMMMMNmmNMMMMMd`
.NMMMMo            -MMMMMo  :MMMMNhNMMMMMMMNs.         .NMMMMs         -yNMMMMMMMMMNy:    `omMMMMMMMMMMd+`
.-----              ------  `----- `-/+++/.           `dMMMMy             .:/++++:.          `-/++++/-`
                                                      yMMMMd`
.ooooooooooooooooooo.  odddds                        oMMMMm.
/MMMMMMMMMMMMMMMMMMM:  yMMMMd                       -ddddd-
/MMMMMMMMMMMMMMMMMMM:  oddddy
/MMMMM:`````````````
/MMMMM-                ommmmy    /mmmmh/hmMMMMNds.        :ydNMMMMNmh+.      hmmmm+odNMMMMNh+`        -ohNMMMMNmh+`       `+ymNMMMMNho.
/MMMMM:```````````     sMMMMh    +MMMMMMMMMMMMMMMMo     -mMMMMMMMMMMMMNo     mMMMMMMMMMMMMMMMm-     .hMMMMMMMMMMMMNo    `sMMMMMMMMMMMMMh.
/MMMMMMMMMMMMMMMM+     sMMMMh    +MMMMMMdo//+dMMMMM/    mMMMMh:..-+NMMMM/    mMMMMMNy+//sNMMMMm    :NMMMMd+:::sNMMMMo  `dMMMMd/-../hMMMMm.
/MMMMMMMMMMMMMMMM+     sMMMMh    +MMMMM+      dMMMMy    ::+yhssssssmMMMMs    mMMMMm.     -MMMMM-  `mMMMMs      -oooo+  oMMMMMhyyyyyyNMMMMs
/MMMMMs++++++++++-     sMMMMh    +MMMMm`      yMMMMy    /dMMMMMMMMMMMMMMy    mMMMMo      `MMMMM:  -MMMMM.              dMMMMMMMMMMMMMMMMMd
/MMMMM-                sMMMMh    +MMMMm`      yMMMMy   sMMMMNyooooodMMMMy    mMMMMo      `MMMMM:  .MMMMM.              dMMMMhoooooooooooo/
/MMMMM-                sMMMMh    +MMMMm`      yMMMMy  .NMMMM:     `dMMMMy    mMMMMo      `MMMMM:   mMMMMy      -hhhhy` +MMMMm`      /++++:
/MMMMM-                sMMMMh    +MMMMm`      yMMMMy  `mMMMMd/--:omMMMMMy    mMMMMo      `MMMMM:   -NMMMMmo/:/sNMMMMo   hMMMMNs/::+hMMMMN:
/MMMMM-                sMMMMh    +MMMMm`      yMMMMy   -mMMMMMMMMMMMMMMMy    mMMMMo      `MMMMM:    .hMMMMMMMMMMMMN+     oNMMMMMMMMMMMMm:
/MMMMM-                sMMMMh    +MMMMm`      yMMMMy    `/ymMMMMNhooMMMMy    mMMMMo      `MMMMM:      .+hmMMMMNmy/`       `/ydNMMMMNd*/

// Abyss.Finance Lockup Service

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

    address public safeContract3;
    address public safeContract6;
    address public safeContract12;

    mapping (address => uint256) private _deposits;

    // VIEW FUNCTIONS

    /**
     * @dev Returns amount requested for the `token` withdrawal
     * on all `safeContract` smart contracts.
     */
    function deposited(address token) external view returns (uint256) {
        return _deposits[token];
    }

    // ACTION FUNCTIONS

    /**
     * @dev See {IAbyssLockup-externalTransfer}.
     */
    function externalTransfer(address token, address sender, address recipient, uint256 amount) external onlyContract(msg.sender) returns (bool) {
        if (sender == address(this)) {
            _deposits[token] = SafeMath.sub(_deposits[token], amount);
            IERC20(address(token)).safeTransfer(recipient, amount);
        } else {
            if (recipient == address(this)) {
                _deposits[token] = SafeMath.add(_deposits[token], amount);
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
