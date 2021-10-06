import Web3Modal from "web3modal";
import {ethers} from 'ethers';
import dotenv from 'dotenv'
import fs from 'fs'
// dotenv.config({path: "../.env"})
dotenv.config()

const connect_btn = document.getElementById("connect-btn")



const ABIS = {
  OPENPID_ABI: '',
  OPENPID_BYTECODE: ''
}

const PROVIDER = {
  INDUCED: null,
  RINKEBY: process.env.RINKEBY_URL,
}

const CONTRACT = {
    RINKEBY: "0xec56874889f6bfB46C408557B489c39cfBA38a5C"
}

const CONTRACT_CACHE = {
    STANDARDS: null
}


const providerOptions = {};

const web3Modal = new Web3Modal({
  network: "mainnet",
  cacheProvider: true,
  providerOptions
});

// connect to a web3 external provider
async function connect() {
  const externalProvider = await web3Modal.connect();
  return new ethers.providers.Web3Provider(externalProvider);
}

function setABI(){
    let OPENPID_ABI_RAW = fs.readFileSync('./interfaces/OpenPID.json');
    ABIS.OPENPID_ABI = JSON.parse(OPENPID_ABI_RAW);
}





// clear all the user information entries 
// (when contract information is added, those should also be cleared)
function reset(){
  PROVIDER.INDUCED = null
}




// when clicked an odd number of times, it logs the user into the web3 provider
// otherwise it logs the user out.
async function loginHandler () {
  if (connect_btn.innerHTML=='Logout'){
    web3Modal.clearCachedProvider();
    reset()
    connect_btn.innerHTML='Connect to Web3'
  } else {
    console.log('Connecting to web3')
    let provider = await connect();
    let signer = provider.getSigner(0);
    let address = await signer.getAddress();
    PROVIDER.INDUCED = provider
    console.log('address is', address)
    const rawBalance = await provider.getBalance(address);
    const balance = Math.round(ethers.utils.formatEther(rawBalance) * 10000) / 10000;

    connect_btn.innerHTML='Logout'
  }
}

module.exports = {
    reset,
    loginHandler,
    setABI,
    PROVIDER,
    CONTRACT,
    CONTRACT_CACHE
}