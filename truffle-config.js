var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  solc: {
		optimizer: {
			enabled: true,
			runs: 200
		}
	},
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/');
      },
      network_id: 3,
      gas: 6712388,
      gasPrice: 1000000000,
    },
    main: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/');
      },
      network_id: 1
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/');
      },
      network_id: 4,
      gas: 4600000,
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://kovan.infura.io/');
      },
      network_id: 42
    },
  }
};
