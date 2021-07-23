const HDWalletProvider = require("@truffle/hdwallet-provider");
const web3 = require("web3");
require('dotenv').config()
const NFT_CONTRACT_ABI = require('../abi.json')
const argv = require('minimist')(process.argv.slice(2));
const fs = require('fs')

async function main() {
  try {
    const configs = JSON.parse(fs.readFileSync('./deployed/' + argv._ + '.json').toString())
    const provider = new HDWalletProvider(
      configs.proxy_mnemonic,
      configs.provider
    );
    const web3Instance = new web3(provider);
    const nftContract = new web3Instance.eth.Contract(
      NFT_CONTRACT_ABI,
      configs.contract_address,
      { gasLimit: "10000000" }
    );
    console.log('CONTRACT ADDRESS IS:', configs.contract_address)
    const owner = await nftContract.methods.owner().call();
    console.log('OWNER IS:', owner)
    const name = await nftContract.methods.name().call();
    const symbol = await nftContract.methods.symbol().call();
    console.log('|* NFT DETAILS *|')
    console.log('>', name, symbol, '<');
    console.log('--')
    const approved = await nftContract.methods.isApprovedForAll(configs.owner_address, configs.proxy_address).call();
    console.log('Is proxy approved: ' + approved)
    let ended = false
    let i = 0;
    try {
      while (!ended) {
        const owner = await nftContract.methods.ownerOf(i).call();
        const uri = await nftContract.methods.tokenURI(i).call();
        console.log('TOKENID: ' + i + ' - ' + uri, 'OWNER IS', owner)
        i++
      }
    } catch (e) {
      ended = true
    }
    process.exit();
  } catch (e) {
    console.log(e.message)
    process.exit();
  }
}

if (argv._ !== undefined) {
  main();
} else {
  console.log('Provide a deployed contract first.')
}