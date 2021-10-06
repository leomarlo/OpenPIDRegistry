const hre = require("hardhat");
const ethers = require("ethers");
const fs = require('fs');

async function createABI(){
    const OpenPIDArtifact = await hre.artifacts.readArtifact("OpenPID")
    const IOpenPID = new ethers.utils.Interface(OpenPIDArtifact.abi)
    const contract_abi_object = IOpenPID.format()
    contract_abi_string = JSON.stringify(contract_abi_object, null, 4);
    contract_bytecode = OpenPIDArtifact.bytecode
    fs.writeFile('./app/interfaces/OpenPID.json', contract_abi_string, (err) => {
        if (err) {throw err}
        console.log("JSONified ABI is saved.")});
}

createABI()