import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer, tokenOwner} = await getNamedAccounts();

  await deploy('PFNFT', {
    from: deployer,
    args: ["Royal Test",
    "RYL", 
    "ipfs://Qmb2vyKLB7eRgnjhs4PVhD1jRNpmLmdBCNcikfeJwT188g/", 
    "ipfs://QmWFbcEmC9PFaWWjDvincjacEm32pak8vT272Zwy98pMkV/1.json",
    ["0xe2b8651bF50913057fF47FC4f02A8e12146083B8","0xe2b8651bF50913057fF47FC4f02A8e12146083B8"]],
    log: true,
  });

  
  await deployments.execute('PFNFT', {
    from: deployer,
    log: true
  },
  'setOnlyWhitelisted', false
  )



  
};
export default func;
func.tags = ['PFNFT'];
