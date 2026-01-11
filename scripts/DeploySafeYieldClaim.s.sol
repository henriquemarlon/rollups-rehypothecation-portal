// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script} from "forge-std-1.12.0/src/Script.sol";
import {console} from "forge-std-1.12.0/src/console.sol";
import {SafeYieldClaim} from "../src/delegatecall/SafeYieldClaim.sol";

contract DeploySafeYieldClaim is Script {
    SafeYieldClaim public safeYieldClaim;

    function run() external {
        console.log("Starting SafeYieldClaim deployment on chain ID:", block.chainid);

        vm.startBroadcast();
        console.log("Deploying SafeYieldClaim...");
        safeYieldClaim = new SafeYieldClaim{salt: keccak256("1596")}();
        console.log("SafeYieldClaim deployed to:", address(safeYieldClaim));
        vm.stopBroadcast();

        _saveDeploymentInfo();

        console.log("SafeYieldClaim deployment completed!");
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
            '"safeYieldClaim":"',
            vm.toString(address(safeYieldClaim)),
            '"',
            "}",
            "}}"
        );

        vm.writeJson(deploymentInfo, string.concat("./deployments/", vm.toString(block.chainid), ".json"));
    }
}
