//import smart contract
const LuxOrders = artifacts.require('../contracts/LuxOrders.sol')
//import assert statement to check conditons
const assert = require('assert')

let contractInstance

contract('LuxOrders', (accounts) => {
  //The beforeEach function will be executed before each test
  //and inside it we are just deploying a new LuxOrders contract
  //with the method deployed() .
  beforeEach(async () => {
    contractInstance = await LuxOrders.deployed()
  })

  //testing soldOrderToMint function
  it('soldOrderToMint Test: Should create a new order token, create a new buyer, increment totalRaised, and return a token id', async () => {
      //creating hash variables
      const preBuyerID = 'test@gmail.com'
      const preRedemptionHash = 'test@gmail.com1'
      //create new order token after sale is registered
      await contractInstance.soldOrderToMint("https://ipfs.io/ipfs/QmV9tSDx9UiPeWExXEeH6aoDvmihvx6jD5eLb4jbTaKGps", 2000, preBuyerID, preRedemptionHash, 123)

      //check the buyers mapping contributed should be 2000
      const buyerId = await web3.sha3(web3.toHex(preBuyerID), {encoding:"hex"})
      const newBuyer = await contractInstance.buyers(buyerId)
      const newBuyerContributed = newBuyer[0]
      assert.equal(newBuyerContributed, 2000, 'The total contributed amount of the new buyer is not correct')

      //check the buyers mapping donation allocation should be 0
      const newBuyerDonationAllocation = newBuyer[1]
      assert.equal(newBuyerDonationAllocation, 0, 'The total donated allocation of the new buyer is not correct')

      //check the buyer exists
      const newBuyerExists = newBuyer[2]
      assert.equal(newBuyerExists, true, 'The exists status of the new buyer is not correct')

      //check the totalRaised state variable for increment, should be TotalRaised = 2000
      const totalRaised = await contractInstance.totalRaised()
      assert.equal(totalRaised, 2000, 'The total contributed amount is not correct')

      //check the orderIndex state variable for increment
      const orderIndex = await contractInstance.orderIndex()
      assert.equal(orderIndex, 1, 'The order index is not correct')

      //check the token struct for all set variables: saleAmount
      const orderToken = await contractInstance.orderTokens(1)
      const saleAmount = orderToken[0]
      assert.equal(saleAmount, 2000, 'The order token sale amount is not correct')

      //check the token struct for correct order number
      const orderNumber = orderToken[1]
      assert.equal(orderNumber, 123, 'The order token sale amount is not correct')

      //check the token struct for all set variables: tokenURI
      const tokenURI = orderToken[2]
      assert.equal(tokenURI, "https://ipfs.io/ipfs/QmV9tSDx9UiPeWExXEeH6aoDvmihvx6jD5eLb4jbTaKGps", 'The order token URI is not correct')

      //check the token struct for all set variables: redeemed
      const tokenRedeemed = orderToken[5]
      assert.equal(tokenRedeemed, false, 'The order token redemption status is not correct')

      //check the token struct for all set variables: buyer hash
      const tokenBuyerHash = orderToken[6]
      assert.equal(tokenBuyerHash, web3.sha3(web3.toHex(preBuyerID), {encoding:"hex"}), 'The order token buyer hash is not correct')

      //check the token struct for all set variables: buyer hash
      const tokenRedemptionHash = orderToken[7]
      assert.equal(tokenRedemptionHash, web3.sha3(web3.toHex(preRedemptionHash), {encoding:"hex"}), 'The order token redemption hash is not correct')

      //check the token struct for all set variables: tokenExists
      const tokenExists = orderToken[8]
      assert.equal(tokenExists, true, 'The order token exists is not correct')

   })

   //testing chooseDonation function
   it('chooseDonation Test: Should update charity list, emit donation event, and return bool', async () => {

     //check the buyers mapping contributed should be 2000
     const preBuyerID = 'test@gmail.com'
     const buyerId = await web3.sha3(web3.toHex(preBuyerID), {encoding:"hex"})
     const newBuyer = await contractInstance.buyers(buyerId)
     const newBuyerContributed = newBuyer[0]
     assert.equal(newBuyerContributed, 2000, 'The total contributed amount of the new buyer is not correct')

     //check the buyers mapping donation allocated = 0
     const newBuyerAllocated = newBuyer[1]
     assert.equal(newBuyerAllocated, 0, 'The total donation allocation amount of the new buyer is not correct')

     //make donation allocation choice #1
     await contractInstance.chooseDonation(preBuyerID, 'Black Girls Code', 1000, 123, 1)

     //check new buyer allocation amount
     const updatedBuyer = await contractInstance.buyers(buyerId)
     const newAllocation = updatedBuyer[1]
     assert.equal(newAllocation, 1000, 'The donation allocation for the buyer is incorrect')

     //check for chooseDonation struct with 1000 in it
     const choosenDonation = await contractInstance.choseDonations(123)
     const charityName = choosenDonation[0]
     assert.equal(charityName, 'Black Girls Code', 'The charity name in the chosenDonation struct is incorrect')

     const amountAllocated = choosenDonation[1]
     assert.equal(amountAllocated, 1000, 'The donation allocation on the chosenDonation struct is incorrect')

     const buyerHash = choosenDonation[2]
     assert.equal(buyerHash, buyerId, 'The donation buyer hash on the chosenDonation struct is incorrect')

     //check charity mapping - should be new charity  - charity name
     const charityId = await web3.sha3(web3.toHex('Black Girls Code'), {encoding:"hex"})
     const newCharity = await contractInstance.charities(charityId)
     const charityNameII = newCharity[0]
     assert.equal(charityNameII, 'Black Girls Code', 'The charity name is incorrect')

     //check charity mapping - should be new charity  - amountChosenToDonate
     const charityChosenAmount = newCharity[1]
     assert.equal(charityChosenAmount, 1000, 'The charity chosen allocation amount is incorrect')

     //check charity mapping - should be new charity  - amountDonated
     const charityDonatedAmount = newCharity[2]
     assert.equal(charityDonatedAmount, 0, 'The charity donated amount is incorrect')

     //check charity mapping - should be new charity  - amountDonated
     const charityExists = newCharity[3]
     assert.equal(charityExists, true, 'The charity exists status is incorrect')

     //check totalChosenDonations
     const totalChosenDonations = await contractInstance.totalChosenDonations()
     assert.equal(totalChosenDonations, 1, 'totalChosenDonations is incorrect')

     //check totalChosenDonatedAmount
     const totalChosenDonatedAmount = await contractInstance.totalChosenDonatedAmount()
     assert.equal(totalChosenDonatedAmount, 1000, 'totalChosenDonatedAmount is incorrect')

   })

   //testing redeemOrder function
   it('redeemOrder Test: Update token buyer address, update token redemption status, transfer ERC721 token to new address, emit redeem event', async () => {

     //call redeem order
     const preBuyerID = 'test@gmail.com'
     const preRedemptionHash = 'test@gmail.com1'
     await contractInstance.redeemOrder(preBuyerID, preRedemptionHash, accounts[1], 1)

     //check update order token struct: buyer address
     const newOrderToken = await contractInstance.orderTokens(1)
     const ownerAddress = newOrderToken[4]
     assert.equal(ownerAddress, accounts[1], 'Owner of order token is incorrect')

     //check update order token struct: redemption status
     const redemptionStatus = newOrderToken[5]
     assert.equal(redemptionStatus, true, 'Redemption status of order token is incorrect')

     //call get token owner
     const tokenOwner = await contractInstance.getTokenOwner(1)
     assert.equal(tokenOwner, accounts[1], 'Owner of order token is incorrect - ERC721 root check')

   })

   //testing makeDonation function
   it('makeDonation Test: Update madeDonations list, increment totalMadeDonations, increment totalDonated, and emit DonationMadeToCharity', async () => {

     //call makeDonation
     const preProofHash = 'Proof that Luxarity donated allocated proceeds to Black Girls Code for a total of $1000'
     await contractInstance.makeDonation(preProofHash, 'https://www.proof.com', 1000, 'Black Girls Code')

     //check totalMadeDonations += 1;
     const totalMadeDonations = await contractInstance.totalMadeDonations()
     assert.equal(totalMadeDonations, 1, 'totalMadeDonations is incorrect')

     //check totalDonated
     const totalDonated = await contractInstance.totalDonated()
     assert.equal(totalDonated, 1000, 'totalDonated is incorrect')

     //check new struct in made donations mapping: _charityName
     const madeDonationHash = await web3.sha3(web3.toHex(preProofHash), {encoding:"hex"})
     const newMadeDonation = await contractInstance.madeDonations(madeDonationHash)
     const mdCharityName = newMadeDonation[0]
     assert.equal(mdCharityName, 'Black Girls Code', 'Charity name in made donation struct is incorrect')

     //check new struct in made donations mapping: _proofURL
     const mdProofUrl = newMadeDonation[1]
     assert.equal(mdProofUrl, 'https://www.proof.com', 'Proof URL in made donation struct is incorrect')

     //check new struct in made donations mapping: _madeDonationAmount
     const mdDonationAmount = newMadeDonation[2]
     assert.equal(mdDonationAmount, 1000, 'Made donation amount in made donation struct is incorrect')

     //check new struct in made donations mapping: address
     const mdSender = newMadeDonation[3]
     assert.equal(mdSender , accounts[0], 'Sender in made donation struct is incorrect')

   })

   //testing call functions
   it('Call Function Test: call for buyer amount information, call for redemption status information, call for token sold information, and call for token owner information', async () => {

     //get redemption status of token 1 = should be true
     const preBuyerID = 'test@gmail.com'
     const buyerId = await web3.sha3(web3.toHex(preBuyerID), {encoding:"hex"})
     const tokenStatus = await contractInstance.getRedemption(1)
     assert.equal(tokenStatus, true, 'Token redemption status is incorrect')

     //get buyer amount -> should be 2000
     const tokenBuyerAmount = await contractInstance.getBuyerAmount(preBuyerID)
     assert.equal(tokenBuyerAmount, 2000, 'Token buyer amount is incorrect')

     //get token owner
     const tokenOwner = await contractInstance.getTokenOwner(1)
     assert.equal(tokenOwner, accounts[1], 'Token owner is incorrect')


   })

})
