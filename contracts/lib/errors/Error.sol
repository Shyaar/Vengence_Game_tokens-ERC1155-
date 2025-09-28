// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

library Error {
    error NotAdmin();
    error AccountIdsMismatch();
    error InvalidOwnerAddress();
    error TransferToZeroAddress();
    error NotApprovedOrSender();
    error InsufficientBalance();
    error ReceiverRejectedTransfer();
    error IdsAmountsMismatch();
    error URINotAllowed();
    error MissingURI();
    error InvalidBatmanAmount();
    error BatmanNFTAlreadyExists();
}
