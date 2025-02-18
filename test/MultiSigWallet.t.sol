// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public implementation;
    MultiSigWallet public wallet;
    address[] public owners;
    uint256 public required = 2;

    address public owner1 = address(1);
    address public owner2 = address(2);
    address public owner3 = address(3);
    address public nonOwner = address(4);

    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);

    function setUp() public {
        // Setup owners
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);

        // Deploy implementation
        implementation = new MultiSigWallet();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(MultiSigWallet.initialize.selector, owners, required);

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        wallet = MultiSigWallet(payable(address(proxy)));
    }

    function testInitialization() public {
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), owner1));
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), owner2));
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), owner3));
        assertEq(wallet.required(), required);
    }

    function testSubmitTransaction() public {
        vm.startPrank(owner1);

        address to = address(0x123);
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.expectEmit(true, false, false, true);
        emit Submission(0);

        uint256 txId = wallet.submitTransaction(to, value, data);
        assertEq(txId, 0);

        (address txTo, uint256 txValue, bytes memory txData, bool executed, uint256 confirmations) =
            wallet.transactions(txId);

        assertEq(txTo, to);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertFalse(executed);
        assertEq(confirmations, 0);

        vm.stopPrank();
    }

    function testConfirmTransaction() public {
        vm.startPrank(owner1);
        uint256 txId = wallet.submitTransaction(address(0x123), 1 ether, "");
        vm.stopPrank();

        vm.startPrank(owner2);
        vm.expectEmit(true, true, false, true);
        emit Confirmation(owner2, txId);

        wallet.confirmTransaction(txId);

        (,,,, uint256 confirmations) = wallet.transactions(txId);
        assertEq(confirmations, 1);
        assertTrue(wallet.confirmations(txId, owner2));

        vm.stopPrank();
    }

    function testExecuteTransaction() public {
        address payable to = payable(address(0x123));
        uint256 value = 1 ether;

        // Fund the wallet
        vm.deal(address(wallet), 2 ether);

        // Submit transaction
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(to, value, "");

        // Confirm from owner1 and owner2
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);

        uint256 initialBalance = to.balance;

        // Execute
        vm.prank(owner1);
        vm.expectEmit(true, false, false, true);
        emit Execution(txId);

        wallet.executeTransaction(txId);

        // Verify execution
        (,,, bool executed,) = wallet.transactions(txId);
        assertTrue(executed);
        assertEq(to.balance - initialBalance, value);
    }

    function test_RevertWhen_NonOwnerSubmits() public {
        vm.prank(nonOwner);
        wallet.submitTransaction(address(0x123), 1 ether, "");
    }

    function test_RevertWhen_DoubleConfirmation() public {
        vm.startPrank(owner1);
        uint256 txId = wallet.submitTransaction(address(0x123), 1 ether, "");
        wallet.confirmTransaction(txId);
        wallet.confirmTransaction(txId); // Should revert
        vm.stopPrank();
    }

    function test_RevertWhen_ExecutingWithoutEnoughConfirmations() public {
        vm.startPrank(owner1);
        uint256 txId = wallet.submitTransaction(address(0x123), 1 ether, "");
        wallet.confirmTransaction(txId);
        wallet.executeTransaction(txId); // Should revert - only 1 confirmation
        vm.stopPrank();
    }

    function testPause() public {
        vm.startPrank(owner1);
        wallet.pause();
        assertTrue(wallet.paused());
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.startPrank(owner1);
        wallet.pause();
        assertTrue(wallet.paused());
        wallet.unpause();
        assertFalse(wallet.paused());
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerPause() public {
        vm.prank(nonOwner);
        wallet.pause();
    }

    function test_RevertWhen_SubmittingWhilePaused() public {
        // First pause the contract
        vm.prank(owner1);
        wallet.pause();
        
        // Try to submit a transaction while paused
        vm.prank(owner2);
        wallet.submitTransaction(address(0x123), 1 ether, "");
    }

    function test_RevertWhen_ConfirmingWhilePaused() public {
        // Submit a transaction
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(0x123), 1 ether, "");
        
        // Pause the contract
        vm.prank(owner1);
        wallet.pause();
        
        // Try to confirm while paused
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
    }

    function test_RevertWhen_ExecutingWhilePaused() public {
        // Fund the wallet
        vm.deal(address(wallet), 2 ether);
        
        // Submit and confirm a transaction
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(0x123), 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txId);
        vm.prank(owner2);
        wallet.confirmTransaction(txId);
        
        // Pause the contract
        vm.prank(owner1);
        wallet.pause();
        
        // Try to execute while paused
        vm.prank(owner1);
        wallet.executeTransaction(txId);
    }
}
