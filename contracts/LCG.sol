// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

library LCG {
    struct iterator {
        uint x;
    }
    
    function iterate (iterator storage i) external {
        i.x = i.x + 1;
    }
}