pragma solidity ^0.8.8;

import {Script} from "forge-std-1.12.0/src/Script.sol";
import {console} from "forge-std-1.12.0/src/console.sol";
import {IInputBox} from "cartesi-rollups-contracts-2.1.1/src/inputs/IInputBox.sol";
import {ERC20ReHypothecationPortal} from "../src/ERC20ReHypothecationPortal.sol";

contract DeployERC20ReHypothecationPortal is Script {
    ERC20ReHypothecationPortal public portal;

    function run() external {
        console.log("Starting ERC20ReHypothecationPortal deployment on chain ID:", block.chainid);

        address inputBox = vm.parseAddress(vm.prompt("InputBox address"));
        address initialOwner = vm.parseAddress(vm.prompt("Initial owner address"));

        vm.startBroadcast();
        console.log("Deploying ERC20ReHypothecationPortal...");
        portal = new ERC20ReHypothecationPortal{salt: keccak256("1596")}(
            IInputBox(inputBox),
            initialOwner
        );
        console.log("ERC20ReHypothecationPortal deployed to:", address(portal));
        vm.stopBroadcast();

        _saveDeploymentInfo();

        console.log("ERC20ReHypothecationPortal deployment completed!");
    }

    function _saveDeploymentInfo() internal {
        string memory deploymentInfo = string.concat(
            '{"deployer":{',
            '"chainId":',
            vm.toString(block.chainid),
            ",",
            '"timestamp":',
            vm.toString(block.timestamp),
            ",",
            '"contracts":{',
            '"erc20ReHypothecationPortal":"',
            vm.toString(address(portal)),
            '"',
            "}",
            "}}"
        );

        vm.writeJson(deploymentInfo, string.concat("./deployments/", vm.toString(block.chainid), ".json"));
    }
}
