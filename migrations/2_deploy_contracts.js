var LuxOrder = artifacts.require("../contracts/LuxOrders.sol");

module.exports = function(deployer) {
  deployer.deploy(LuxOrder);
};
