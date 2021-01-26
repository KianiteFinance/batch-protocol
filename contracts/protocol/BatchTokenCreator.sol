/*
    Copyright 2020 Set Labs Inc.
    Copyright 2021 Kianite Limited.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IController } from "../interfaces/IController.sol";
import { BatchToken } from "./BatchToken.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";

/**
 * @title BatchTokenCreator
 * @author Set Protocol
 * @author Kianite Limited
 *
 * BatchTokenCreator is a smart contract used to deploy new BatchToken contracts. The BatchTokenCreator
 * is a Factory contract that is enabled by the controller to create and register new BatchTokens.
 */
contract BatchTokenCreator {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event BatchTokenCreated(address indexed _batchToken, address _manager, string _name, string _symbol);

    /* ============ State Variables ============ */

    // Instance of the controller smart contract
    IController public controller;

    /* ============ Functions ============ */

    /**
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /**
     * Creates a BatchToken smart contract and registers the BatchToken with the controller. The BatchTokens are composed
     * of positions that are instantiated as DEFAULT (positionState = 0) state.
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _units                  List of units. Each unit is the # of components per 10^18 of a BatchToken
     * @param _manager                Address of the manager
     * @param _name                   Name of the BatchToken
     * @param _symbol                 Symbol of the BatchToken
     * @return address                Address of the newly created BatchToken
     */
    function create(
        address[] memory _components,
        int256[] memory _units,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address)
    {
        require(_components.length > 0, "Must have at least 1 component");
        require(_components.length == _units.length, "Component and unit lengths must be the same");
        require(!_components.hasDuplicate(), "Components must not have a duplicate");
        require(_manager != address(0), "Manager must not be empty");

        for (uint256 i = 0; i < _components.length; i++) {
            require(_components[i] != address(0), "Component must not be null address");
            require(_units[i] > 0, "Units must be greater than 0");
        }

        // Creates a new BatchToken instance
        BatchToken batchToken = new BatchToken(
            _components,
            controller,
            _manager,
            _name,
            _symbol
        );

        // Registers Set with controller
        controller.addSet(address(batchToken));

        emit BatchTokenCreated(address(batchToken), _manager, _name, _symbol);

        return address(batchToken);
    }
}

