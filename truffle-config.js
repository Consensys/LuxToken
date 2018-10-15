var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "again hammer monster useless nose close gloom loyal labor often aunt mass";

module.exports = {
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
        return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/dafcac3faf174e009483337759967f85');
      },
      network_id: '3',
      gas: 4600000,
      gasPrice: 1100000000,
    },
    main: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/v3/dafcac3faf174e009483337759967f85');
      },
      network_id: '1'
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/v3/dafcac3faf174e009483337759967f85');
      },
      network_id: '4',
      gas: 4600000,
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(mnemonic, 'https://kovan.infura.io/v3/dafcac3faf174e009483337759967f85');
      },
      network_id: '42'
    },
  }
};
