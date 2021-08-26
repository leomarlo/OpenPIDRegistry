import {namehash, getEnsAddress} from '@ensdomains/ensjs';
import {ethers} from 'ethers';
import dotenv from 'dotenv';
dotenv.config();
const provider = new ethers.providers.JsonRpcProvider(process.env.RINKEBY_URL);
const wallet_alice = new ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);

// const ens = new ENS({ provider: wallet_alice, ensAddress: ENS.getEnsAddress('1') })
let ethname = 'alberta'
let nh = namehash(ethname);
console.log(nh)
// async function getENSAddress(){
//     address = await ens.name('alberta.eth').getAddress();
//     console.log(address);
// }

// getENSAddress();