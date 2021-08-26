// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;


import "./LCG.sol";


contract Test {
    using LCG for LCG.iterator;
    LCG.iterator public x;
    
    constructor () {
        x.iterate();
    }
}