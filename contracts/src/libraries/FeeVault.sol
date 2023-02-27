// SPDX-License-Identifier: MIT

// MIT License

// Copyright (c) 2022 Optimism
// Copyright (c) 2022 Scroll

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;

import { IL2ScrollMessenger } from "../L2/IL2ScrollMessenger.sol";
import { OwnableBase } from "./common/OwnableBase.sol";

/// @title FeeVault
/// @notice The FeeVault contract contains the basic logic for the various different vault contracts
///         used to hold fee revenue generated by the L2 system.
abstract contract FeeVault is OwnableBase {
  /// @notice Emits each time that a withdrawal occurs.
  ///
  /// @param value Amount that was withdrawn (in wei).
  /// @param to    Address that the funds were sent to.
  /// @param from  Address that triggered the withdrawal.
  event Withdrawal(uint256 value, address to, address from);

  /// @notice Minimum balance before a withdrawal can be triggered.
  uint256 public minWithdrawAmount;

  /// @notice Scroll L2 messenger address.
  address public messenger;

  /// @notice Wallet that will receive the fees on L1.
  address public recipient;

  /// @notice Total amount of wei processed by the contract.
  uint256 public totalProcessed;

  /// @param _owner               The owner of the contract.
  /// @param _recipient           Wallet that will receive the fees on L1.
  /// @param _minWithdrawalAmount Minimum balance before a withdrawal can be triggered.
  constructor(
    address _owner,
    address _recipient,
    uint256 _minWithdrawalAmount
  ) {
    _transferOwnership(_owner);

    minWithdrawAmount = _minWithdrawalAmount;
    recipient = _recipient;
  }

  /// @notice Allow the contract to receive ETH.
  receive() external payable {}

  /// @notice Triggers a withdrawal of funds to the L1 fee wallet.
  function withdraw() external {
    uint256 value = address(this).balance;

    require(value >= minWithdrawAmount, "FeeVault: withdrawal amount must be greater than minimum withdrawal amount");

    unchecked {
      totalProcessed += value;
    }

    emit Withdrawal(value, recipient, msg.sender);

    // no fee provided
    IL2ScrollMessenger(messenger).sendMessage{ value: value }(
      recipient,
      value,
      bytes(""), // no message (simple eth transfer)
      0 // _gasLimit can be zero for fee vault.
    );
  }

  /// @notice Update the address of messenger.
  /// @param _messenger The address of messenger to update.
  function updateMessenger(address _messenger) external onlyOwner {
    messenger = _messenger;
  }

  /// @notice Update the address of recipient.
  /// @param _recipient The address of recipient to update.
  function updateRecipient(address _recipient) external onlyOwner {
    recipient = _recipient;
  }

  /// @notice Update the minimum withdraw amount.
  /// @param _minWithdrawAmount The minimum withdraw amount to update.
  function updateMinWithdrawAmount(uint256 _minWithdrawAmount) external onlyOwner {
    minWithdrawAmount = _minWithdrawAmount;
  }
}
