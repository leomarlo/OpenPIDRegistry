// const ethers = require("ethers");
const hre = require("hardhat");
const fs = require("fs");
require('dotenv').config()


async function deploy(provider_url){

    // set API_URL for get-requests in the contract
    const provider = new hre.ethers.providers.JsonRpcProvider(provider_url);
    const wallet_alice = new hre.ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);


    let contract_info = new Object()
    openPIDArtifact = await hre.artifacts.readArtifact("OpenPID")
    const IOpenPID = new hre.ethers.utils.Interface(openPIDArtifact.abi)
    contract_info.abi = IOpenPID.format()
    const contract_abi = JSON.stringify(contract_info.abi, null, 4);
    contract_info.bytecode = openPIDArtifact.bytecode

    // write JSON string to a file
    fs.writeFile('./openPID_abi.json', contract_abi, (err) => {
        if (err) {throw err}
        console.log("JSONified ABI is saved.")});

    // create contract object
    const deployFactory = await hre.ethers.getContractFactory(
        contract_info.abi,
        contract_info.bytecode,
        wallet_alice);

    // deploy Mochacle contract
    const tx = await deployFactory.deploy();
    await tx.deployed();
    contract_info.address = tx.address;
    contract_info.current_network = wallet_alice.provider.network.name
    console.log('The contract address is:', contract_info.address)
    console.log('The network name is:', contract_info.current_network)

    // save contract address to file
    fs.writeFileSync('./contract_address_' + contract_info.current_network + '.txt', contract_info.address)

   
}



// KOVAN OR RINKEBY
let network_name = hre.network.name
console.log('hre.network', hre.network)
let url = ''
if (network_name=='kovan'){
    url = process.env.KOVAN_URL
} else if (network_name=='rinkeby'){ 
    url = process.env.RINKEBY_URL
} else {
    console.log('Unknown network!')
}

// deploy(url)
//    .then(()=>{console.log("successful")})
//    .catch(console.log)

// console.log(Object.keys(hre))

async function getABI(provider_url) {

    openPIDArtifact = await hre.artifacts.readArtifact("OpenPID");

    // console.log(openPIDArtifact.bytecode)

    const IOpenPID = new hre.ethers.utils.Interface(openPIDArtifact.abi)
    let contract_abi_raw = IOpenPID.format()
    const contract_abi = JSON.stringify(contract_abi_raw, null, 4);
    console.log(contract_abi_raw) 

    const provider = new hre.ethers.providers.JsonRpcProvider(provider_url);
    const wallet_alice = new hre.ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);

    try {
        const deployFactory = await hre.ethers.getContractFactory(
            contract_abi_raw,
            openPIDArtifact.bytecode,
            wallet_alice);
    } catch (e) {
        console.log(e)
    }
}

provider_url = process.env.KOVAN_URL

try {
    getABI(provider_url)
} catch (err) {
    console.log(err)
}


// error can be resolved when reading this thing:
// https://github.com/ethereum/solidity/issues/10983