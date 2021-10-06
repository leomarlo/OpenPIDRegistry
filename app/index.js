import {PROVIDER, CONTRACT, loginHandler, setABI} from './utilities/web3'
// import {mint} from './utilities/mint'
// import {loadMetadataStandards} from './utilities/options'


// set the ABI for the contract 
// setABI()  // NOTE:!!! Requires that the ./app/interfaces/ are kept up to date.

// handle web3 connection
const connect_btn = document.getElementById("connect-btn");
connect_btn.addEventListener("click", loginHandler);

// options

// loadMetadataStandards()

// test openpid root 0xd5b9c890771cb34a328b2fc52ac150a68d9718688e4017be40c9248441d86d44
