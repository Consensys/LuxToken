var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "tuition cabbage frog evidence artwork party game vacuum tuna dash lunch bulb";

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
      return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/3ed1418443b041519b6e0c1091c28ef2');
    },
    network_id: 4
  },
  ropsten: {
    provider: function() {
      return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/3ed1418443b041519b6e0c1091c28ef2');
    },
    network_id: 3
  },

};
