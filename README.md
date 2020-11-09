Abyss Finance Lockup
=========

Abyss Lockup services allow you to lock any ERC20 token with strict period of withdrawal time:

  - All ERC20 tokens supported.
  - 3, 6 and 12 months unlock time available.
  - Entirely free service if you hold Abyss Token on all steps.

Contracts
=========

Below is a list of contracts we use for this service:

<dl>
  <dt>SafeERC20, Ownable, ReentrancyGuard</dt>
  <dd>Openzepellin smart contracts. The first one allows for safe transfer and approves ERC20 tokens. The second one allows for managing ownership. The last one protects from re-entrance attacks.</dd>
</dl>

<dl>
  <dt>AbyssLockup</dt>
  <dd>A smart contract that stores tokens requested for withdrawal, as well as through which tokens are transferred from/to user and between contracts.</dd>
</dl>

<dl>
  <dt>AbyssSafe3</dt>
  <dd>The main smart contract responsible for deposits and withdrawal of tokens. 3 months lockup delay setting should be applied on deployment.</dd>
</dl>

<dl>
  <dt>AbyssSafe6</dt>
  <dd>The main smart contract responsible for deposits and withdrawal of tokens. 6 months lockup delay setting should be applied on deployment.</dd>
</dl>

<dl>
  <dt>AbyssSafe12</dt>
  <dd>The main smart contract responsible for deposits and withdrawal of tokens. 12 months lockup delay setting should be applied on deployment.</dd>
</dl>

Installation
------------

To run lockup service, pull the repository from `GitHub` and install [Homebrew](https://brew.sh), [Node.js](https://nodejs.org), [Truffle](https://www.trufflesuite.com) and [OpenZeppelin](https://openzeppelin.com).

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew install node
    npm install truffle -g
    npm install @openzeppelin/contracts
    git clone https://github.com/abyssfinance/abyss-lockup
    cd abyss-lockup

Setup your `truffle` environment, write migrations

    truffle develop
    migrate --reset

Deployment (Mainnet)
------------

Smart contracts should be deployed in such order:

1. `AbyssLockup.sol`
2. `AbyssSafe3.sol`_(0x0e8d6b471e332f140e7d9dbb99e5e3822f728da6, AbyssLockup_address, 3, 40000, 100)_
3. `AbyssSafe6.sol`_(0x0e8d6b471e332f140e7d9dbb99e5e3822f728da6, AbyssLockup_address, 6, 20000, 100)_
4. `AbyssSafe12.sol`_(0x0e8d6b471e332f140e7d9dbb99e5e3822f728da6, AbyssLockup_address, 12, 10000, 100)_
5. Call _initialize(AbyssSafe3_address, AbyssSafe6_address, AbyssSafe12_address)_ function from the `owner` on `AbyssLockup` contract.

How to Use
------------

1. Choose the ERC20 token that you want to lock.
2. Approve `AbyssLockup` contract on that token's smart contract for _115792089237316195423570985008687907853269984665640564039457584007913129639935_ amount.
3. Use _deposit()_ function on `AbyssSafe3`, `AbyssSafe6` or `AbyssSafe12` to deposit tokens.
4. Use _withdrawalRequest()_ function on `AbyssSafe3`, `AbyssSafe6` or `AbyssSafe12` to request a withdrawal.
5. Use _cancelWithdraw()_ function on `AbyssSafe3`, `AbyssSafe6` or `AbyssSafe12` to cancel the withdrawal request.
6. Use _withdraw()_ function on `AbyssSafe3`, `AbyssSafe6` or `AbyssSafe12` to withdraw tokens when lockup time passed after you had made a withdrawal request.

License
=========

MIT

Discussion
----------

For any concerns or suggestions visit us on [Telegram](https://t.me/abyssfinance) to discuss.

For security concerns, please email [security@abyss.finance](mailto:security@abyss.finance).

_© Copyright 2020, Abyss Finance_
