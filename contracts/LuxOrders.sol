pragma solidity ^0.4.24;

import '../openzeppelin-solidity-master/contracts/token/ERC721/ERC721Full.sol';
import "../openzeppelin-solidity-master/contracts/ownership/Ownable.sol";

contract LuxTokens is ERC721Full, Ownable {

  //state variables

    //tokenid index
    uint256 public orderIndex;

    //total raised in sales uint256 USD
    uint256 public totalRaised;

    //total verifiably donated to charities
    uint256 public totalDonated;

    //total number of chosen donations
    uint256 public totalChosenDonations;

    //total number of made donations
    uint256 public totalMadeDonations;

    //token mapping
    mapping (uint256 => OrderToken) orderTokens;

    //token struct
    struct OrderToken {
      uint256 saleAmount;
      string tokenURI;
      address generation;
      address owner;
    }

    //list of donation choices made by buyer (attestation on chain that buyer
    //chose a particular charity to give to)
    mapping (uint256 => ChosenDonation) public chosenDonations;
    struct ChosenDonation {
      string charityName; //name of charity buyer has chosen to give to
      uint256 amountDonated; //amount buyer would like to set aside from his purchases to charity
      bytes32 buyerHash; //hash of donor off-chain identity
    }

    //MadeDonations is a list of donations actually made
    mapping (bytes32 => MadeDonation) public madeDonations;
    struct MadeDonation {
      string charityName; //name of charity luxarity sent proceeds to
      uint256 amountDonated; //amount donated via grant to charity
      bytes32 donationProofHash; //SHA256 hash of proof of donation (in case it is tampered with)
      address donorAddress; //address of owner of contract (luxarity)
      string donationProof; //link to donation receipt
    }

    //soldTokens mapping keeping track of which tokens are sold to which buyer,
    mapping (uint256 => SaleDetails) public soldTokens;
    struct SaleDetails {
      bytes32 buyerHash; //identifier hash of off chain identifier of buyer
      bytes32 redemptionHash; //SHA256 of secret value used by buyer to redeem
      bool redeemed; //redemption status of token
      bool exists;
      uint256 cost; //cost of token in sale (USD)
    }

    //buyers mapping with buyer struct bytes32 => buyer, buyer struct {bytes32, totalBought, exists, owneraddress, totalDonated}, totalBought increments after everytime the buyer buys something and sold function is called, we check for exists and if not true we create a new buyer and add the amount they bought and increment on top of that amount in the future
    //identifier hash of off chain identifier of buyer
    mapping (bytes32 => Buyer) public buyers;
    struct Buyer {
      uint256 totalContributed; //total amount the buyer has bought in USD
      uint256 totalDonationsAllocated; //amount of donation capital allocated
      bool exists; //always true
      address buyerAddress; //address of buyer (if token has been redeemed)
    }


  //constructor for NFT token, name = Luxarity, symbol = LUX
  constructor() ERC721Full('Luxarity Order Token', 'LUX0') public {
    //tokenid index
    orderIndex = 0;
    //total capital raised uint256 USD
    totalRaised = 0;
    //total donated by luxarity (USD)
    totalDonated = 0;
    //total number of chosen donations
    totalChosenDonations = 0;
    //total number of made donations
    totalMadeDonations = 0;
  }

  //events
    event MintedToken (uint256 _tokenId, address _tokenMinter, string _tokenMetaData);
    //event when Order is sold
    event SoldToken (uint256 _tokenId, bytes32 _buyerId, uint256 _cost);
    //event when donation is chosen (bytes32, amount, charityName, donation id)
    event DonationChosen (string _charityName, bytes32 _buyerId, uint256 _amountToBeDonated);
    //event when donation is made by luxarity
    event DonationMadeToCharity (uint256 _amountDonated, string _charityName, bytes32 _proofHash, string _donationProof, bytes32 _donationMadeHash);
    //event when token is redeemed
    event RedeemedToken (uint256 _tokenId, bytes32 _buyerId, address _buyerAddress);

  //modifiers
    //check if buyer exists
    modifier onlyBuyer(bytes32 _buyerId) { require(buyers[_buyerId].exists == true); _; }

  //cuase functions

    //mint function - when Orders are sold in an order - the receipt should be tokenized
    function soldOrderToMint(string _tokenURI, uint256 _saleAmount, bytes32 _buyerID, bytes32 _redemptionHash) public onlyOwner returns (uint) {

      //1.0 check if buyer already exists
      if (!buyers[_buyerID].exists) {
        //adding new buyer to buyers mapping
        buyers[_buyerID] = Buyer(_saleAmount, 0, true, address(0));
      } else {
        //update existing buyer
        buyers[_buyerID].totalContributed += _saleAmount;
      }

      //2.0 Start process of tracking sale, order can only occur once
      //increment orderIndex
      orderIndex += 1;
      if (!soldTokens[orderIndex].exists) {
        soldTokens[orderIndex] = SaleDetails(_buyerID, _redemptionHash, false, true, _saleAmount);
        //increment total donations
        totalRaised += _saleAmount;
        //emit event that token was sold
        emit SoldToken(orderIndex, _buyerID, soldTokens[orderIndex].cost);

        //3.0 Start process of minting tokenized order

        //check if token doesn't exist yet using inherited ERC721 contract
        require(_exists(orderIndex) == true);

        //create token struct
        orderTokens[orderIndex] = OrderToken(_saleAmount, _tokenURI, msg.sender, msg.sender);

        //mint token
        _mint(msg.sender, orderIndex);

        //set metadata
        _setTokenURI(orderIndex, _tokenURI);

        //emit event
        emit MintedToken(orderIndex, msg.sender, _tokenURI);

        //return
        return orderIndex;
      }
    }

    //chooseDonation function
    function chooseDonation(bytes32 _buyerID, string _charityName, uint256 _chosenDonateAmount) public onlyBuyer(_buyerID) returns (bool) {
      //if the amount to donate is less than or equal to the amount they have left to allocate
      uint256 leftover = buyers[_buyerID].totalContributed - buyers[_buyerID].totalDonationsAllocated;
      if (leftover <= _chosenDonateAmount) {
        //increment total chosen donations
        totalChosenDonations += 1;
        //update chosenDonations mapping and then emit choseDonation event
        chosenDonations[totalChosenDonations] = ChosenDonation(_charityName, _chosenDonateAmount, _buyerID);
        //emit event on chosen donation
        emit DonationChosen(_charityName, _buyerID, _chosenDonateAmount);
        //return
        return true;
      }
      return false;
    }

    //make donation function
    function makeDonation(bytes32 _proofHash, string _proof, uint256 _madeDonationAmount, string _charityName) public onlyOwner returns (bool) {
      //donation made proof hash
      bytes32 donationMadeHash = keccak256(abi.encodePacked(_charityName, _madeDonationAmount, _proofHash, msg.sender, _proof));
      //check if donation doesn't exist yet
      require(madeDonations[donationMadeHash].donorAddress == address(0));
      //increment total made donations
      totalMadeDonations += 1;
      //total donated sum amount increased
      totalDonated += _madeDonationAmount;
      //add to made donations mapping
      madeDonations[donationMadeHash] = MadeDonation(_charityName, _madeDonationAmount, _proofHash, msg.sender, _proof);
      //emit event
      emit DonationMadeToCharity(_madeDonationAmount, _charityName, _proofHash, _proof, donationMadeHash);
      //return
      return true;
    }

    //redeem token
    function redeemOrder(bytes32 _buyerID, bytes32 _redemptionHash, address _buyerAddress, uint256 _tokenId) public onlyBuyer(_buyerID) returns (bool) {
      //make sure address is valid
      require(_buyerAddress != address(0));
      //make sure that sold Order exists to be redeemed
      require(soldTokens[_tokenId].buyerHash == _buyerID);
      //make sure redemption secret is correct
      require(soldTokens[_tokenId].redemptionHash == _redemptionHash);
      //update token struct
      orderTokens[_tokenId].owner = _buyerAddress;
      //updates salesdetails struct
      soldTokens[_tokenId].redeemed = true;
      //conduct transfer from Luxarity to address
      transferFrom(msg.sender, _buyerAddress, _tokenId);
      //emit event
      emit RedeemedToken(_tokenId, _buyerID, _buyerAddress);
      return true;
    }

    //safe redeem token
    function safeRedeemOrder(bytes32 _buyerID, bytes32 _redemptionHash, address _buyerAddress, uint256 _tokenId) public onlyBuyer(_buyerID) returns (bool) {
      //make sure address is valid
      require(_buyerAddress != address(0));
      //make sure that sold Order exists to be redeemed
      require(soldTokens[_tokenId].buyerHash == _buyerID);
      require(soldTokens[_tokenId].redemptionHash == _redemptionHash);
      //update token struct
      orderTokens[_tokenId].owner = _buyerAddress;
      //conduct transfer from Luxarity to address
      safeTransferFrom(msg.sender, _buyerAddress, _tokenId);
      //updates salesdetails struct
      soldTokens[_tokenId].redeemed = true;
      //emit event
      emit RedeemedToken(_tokenId, _buyerID, _buyerAddress);
      return true;
    }

  //call functions
    //get how much a buyer has donated in total
    function getBuyerAmount(bytes32 _buyerID) public view returns (uint256 total) {
      if (buyers[_buyerID].exists) {
        return buyers[_buyerID].totalContributed;
      }
      return 0;
		}
    //get total amount donated
    function getTotalRaised() public view returns (uint) {
      return totalRaised;
		}
    //get total specfically allocated
    function getTotalAllocatedDonations() public view returns (uint) {
      return totalChosenDonations;
		}
    //get total made donations
    function getTotalMadeDonations() public view returns (uint) {
      return totalMadeDonations;
		}

    //get boolean to see if NFT has been redeemed or not
    function getRedemption(uint _tokenId) public view returns (bool) {
      return soldTokens[_tokenId].redeemed;
		}
    //get boolean to see if NFT has been sold or not
    function getTokenSold(uint256 _tokenId) public view returns (bool) {
      return soldTokens[_tokenId].exists;
    }

    //get token ownerOf
    function getTokenOwner(uint _tokenId) public view returns (address) {
      address owner = ownerOf(_tokenId);
      return owner;
    }

    //transfer ownership of contract
    function transferContract(address newOwner) public onlyOwner {
      transferOwnership(newOwner);
    }

    //fallback
	  function() payable public { }
}
