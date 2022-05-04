
import { deployContract, getDeployedAddressInt } from '../helpers'

async function main() {
  const contractName = 'DesiegeModuleController'

  // Collect params
  const arbiter = getDeployedAddressInt("DesiegeArbiter");

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiter])
}

main().then(e => console.error(e))