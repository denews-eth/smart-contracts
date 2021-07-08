const argv = require('minimist')(process.argv.slice(2));
const fs = require('fs')
const child_process = require('child_process')

async function deploy() {
    try {
        const configs = JSON.parse(fs.readFileSync('./deployed/' + argv._ + '.json').toString())
        if (
            configs.network !== undefined &&
            configs.proxy_address !== undefined &&
            configs.proxy_mnemonic !== undefined &&
            configs.owner_address !== undefined &&
            configs.contract !== undefined &&
            configs.contract.name !== undefined &&
            configs.contract.ticker !== undefined &&
            configs.contract.description !== undefined &&
            configs.provider !== undefined
        ) {

            console.log('Removing existing build..')
            child_process.execSync('sudo rm -rf build')

            console.log('Deploying contract..')
            let out = child_process.execSync('sudo PROVIDER="' + configs.provider + '" MNEMONIC="' + configs.proxy_mnemonic + '" DESCRIPTION="' + configs.contract.description + '" TICKER="' + configs.contract.ticker + '" NAME="' + configs.contract.name + '" PROXY="' + configs.proxy_address + '" OWNER="' + configs.owner_address + '" truffle deploy --network ' + configs.network + ' --reset', { stdio: 'inherit' })

            // Extracting address
            out = out.toString()
            let head = out.split('CONTRACT ADDRESS IS*||*')
            let foot = head[1].split('*||*')
            const address = foot[0]

            console.log('Extrating ABI..')
            child_process.execSync('sudo npm run extract-abi')
            console.log('--')

            console.log('Deployed address is: ' + address)
            configs.contract_address = address
            console.log('Saving address in config file..')
            fs.writeFileSync('./deployed/' + argv._ + '.json', JSON.stringify(configs, null, 4))
            console.log('--')

            console.log('All done, exiting!')
            process.exit();
        } else {
            console.log('Config file missing.')
        }
    } catch (e) {
        console.log(e.message)
        process.exit()
    }
}

if (argv._ !== undefined) {
    deploy();
} else {
    console.log('Provide a config first.')
}