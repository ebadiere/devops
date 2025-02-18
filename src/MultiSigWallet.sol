// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract MultiSigWallet is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory _owners, uint256 _required) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of owners");

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            _grantRole(OWNER_ROLE, _owners[i]);
            _grantRole(UPGRADER_ROLE, _owners[i]);
        }

        required = _required;
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data)
        public
        whenNotPaused
        onlyRole(OWNER_ROLE)
        returns (uint256 transactionId)
    {
        require(_to != address(0), "Invalid destination address");

        transactionId = transactionCount;
        transactions[transactionId] =
            Transaction({to: _to, value: _value, data: _data, executed: false, confirmations: 0});

        transactionCount += 1;
        emit Submission(transactionId);
    }

    function confirmTransaction(uint256 _transactionId) public whenNotPaused onlyRole(OWNER_ROLE) {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.to != address(0), "Transaction does not exist");
        require(!transaction.executed, "Transaction already executed");
        require(!confirmations[_transactionId][msg.sender], "Transaction already confirmed");

        confirmations[_transactionId][msg.sender] = true;
        transaction.confirmations += 1;

        emit Confirmation(msg.sender, _transactionId);
    }

    function executeTransaction(uint256 _transactionId) public whenNotPaused onlyRole(OWNER_ROLE) nonReentrant {
        Transaction storage transaction = transactions[_transactionId];

        require(transaction.to != address(0), "Transaction does not exist");
        require(!transaction.executed, "Transaction already executed");
        require(transaction.confirmations >= required, "Not enough confirmations");

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        if (success) {
            emit Execution(_transactionId);
        } else {
            emit ExecutionFailure(_transactionId);
            transaction.executed = false;
        }
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    receive() external payable {}
}
