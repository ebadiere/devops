// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockGnosisSafe {
    event SafeSetup(
        address indexed initiator,
        address[] owners,
        uint256 threshold,
        address to,
        bytes data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    );

    event ExecutionSuccess(bytes32 txHash);

    function setup(
        address[] calldata owners,
        uint256 threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        emit SafeSetup(
            msg.sender,
            owners,
            threshold,
            to,
            data,
            fallbackHandler,
            paymentToken,
            payment,
            paymentReceiver
        );
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    ) external payable returns (bool) {
        emit ExecutionSuccess(keccak256(data));
        return true;
    }
}
