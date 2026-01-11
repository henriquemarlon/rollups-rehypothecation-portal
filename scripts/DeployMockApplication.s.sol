// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script} from "forge-std-1.12.0/src/Script.sol";
import {console} from "forge-std-1.12.0/src/console.sol";
import {MockApplication} from "../test/mocks/MockApplication.sol";

contract DeployMockApplication is Script {
    MockApplication public appContract;

    function run() external {
        console.log("Starting MockApplication deployment on chain ID:", block.chainid);

        vm.startBroadcast();
        console.log("Deploying MockApplication...");
        appContract = new MockApplication{salt: keccak256("1596")}();
        console.log("MockApplication deployed to:", address(appContract));
        vm.stopBroadcast();

        _saveDeploymentInfo();

        console.log("MockApplication deployment completed!");
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
            '"mockApplication":"',
            vm.toString(address(appContract)),
            '"',
            "}",
            "}}"
        );

        vm.writeJson(deploymentInfo, string.concat("./deployments/", vm.toString(block.chainid), ".json"));
    }
}
