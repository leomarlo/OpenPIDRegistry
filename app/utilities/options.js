import {PROVIDER, CONTRACT, ABIS, CONTRACT_CACHE} from './web3'
import {ethers} from 'ethers';

const which_standard = document.getElementById("which-standard");

async function loadMetadataStandards(){
    const provider = new ethers.providers.JsonRpcProvider(PROVIDER.RINKEBY);

    OpenPIDContract = new ethers.Contract(
        CONTRACT.RINKEBY,
        ABIS.OPENPID_ABI,
        provider);
    
    const standards = await OpenPIDContract.registeredStandards();
    CONTRACT_CACHE.STANDARDS = standards;
    console.log(standards)
}