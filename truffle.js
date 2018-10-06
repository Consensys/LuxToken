var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  development: {
    host: "127.0.0.1",
    port: 8545,
    network_id: "*" // Match any network id
  },
  rinkeby: {
    provider: function() {
      return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/');
    },
    network_id: 4
  },
  ropsten: {
    provider: function() {
      return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/');
    },
    network_id: 3
  },

};
