import {Contract} from 'ethers';
import hre, {ethers} from 'hardhat';

// Deployment Helpers:
import {deploy} from '../utils/helpers';
// ABI
import {RRVPlatform} from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  await deploy<RRVPlatform>(deployer, 'RRVPlatform', ['RRV Platform', 'RRV Platform', 100], true, 'RRV Platform'); // Default 1% Platform fee per sale
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
