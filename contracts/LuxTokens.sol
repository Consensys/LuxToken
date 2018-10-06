pragma solidity ^0.4.24;

import '../openzeppelin-solidity-master/contracts/token/ERC721/ERC721Full.sol';
import "../openzeppelin-solidity-master/contracts/ownership/Ownable.sol";

contract LuxTokens is ERC721Full, Ownable {

  //state variables

    //tokenid index
    uint256 public tokenIndex;

    //total raised in sales uint256 USD
    uint256 public totalRaised;

    //total verifiably donated to charities
    uint256 public totalDonated;

    //total items sold
    uint256 public totalItemsSold;

    //total number of chosen donations
    uint256 public totalChosenDonations;

    //total number of made donations
    uint256 public totalMadeDonations;

    //token mapping
    mapping (uint256 => LuxToken) luxTokens;

    //token struct
    struct LuxToken {
      bytes32 tokenHash;
      string brand;
      string size;
      string style;
      string gender;
      string tokenURI;
      address generation;
      address owner;
      bytes32 donorHash;
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
    //by luxarity after the resale of donated cloething, this exists to keep luxarity publically
    //accountable
    //identifier is keccak256(charityName, amountDonated, donationProofHash, donorAddress, donationProof)
    mapping (bytes32 => MadeDonation) public madeDonations;
    struct MadeDonation {
      string charityName; //name of charity luxarity sent proceeds to
      uint256 amountDonated; //amount donated via grant to charity
      bytes32 donationProofHash; //SHA256 hash of proof of donation (in case it is tampered with)
      address donorAddress; //address of owner of contract (luxarity)
      string donationProof; //link to donation receipt
    }

    //soldTokens mapping keeping track of which tokens are sold to which buyer,
    //this is somewhat redundant for the sake of associating a buyer's off chain identifier
    //with their actual address (when they get one), it also tracks which tokens have been
    //properly redeemed when bought (another layer on top of _tokenApprovals per say)
    //index needs to be unique so it may be possible to do SHA256(tokenId + soldId + user ID)
    mapping (uint256 => SaleDetails) public soldTokens;
    struct SaleDetails {
      bytes32 buyerHash; //identifier hash of off chain identifier of buyer
      bytes32 redemptionHash; //SHA256 of secret value used by buyer to redeem their token
      bool redeemed; //redemption status of token
      bool sold;  //always true
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

    //tracking donor contributions, identifier is SHA256(unique donor off chain identifier)
    mapping (bytes32 => Donor) public donors;
    struct Donor {
      uint256 fundsRaised; //funds raised from donated items
      bool exists; //always true
    }

  //constructor for NFT token, name = Luxarity, symbol = LUX
  constructor() ERC721Full('Luxarity Style Token', 'LUX') public {
    //tokenid index
    tokenIndex = 0;
    //total capital raised uint256 USD
    totalRaised = 0;
    //total donated by luxarity (USD)
    totalDonated = 0;
    //total items sold
    totalItemsSold = 0;
    //total number of chosen donations
    totalChosenDonations = 0;
    //total number of made donations
    totalMadeDonations = 0;
  }

  //events
    //event when NFT is minter after donation
    event DonationMadeToLuxarity (bytes32 _donorHash, uint256 _totalRaised, bool _exists);
    event MintedToken (uint256 _tokenId, address _tokenMinter, string _tokenMetaData);
    //event when item is sold
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

    //mint function
      //(1) calls internal mint function can only be called by owner
        //the to address is just going to be the luxarity address
      //(2) calls setTokenURI function to associated metadata with token
        //need to determine the standard of JSON that luxarity NFTs follow for the URI
      //(3) emits MintedToken event
    function mintItem(string _tokenURI, string _brand, string _size, string _gender, string _style, bytes32 _donorHash) public onlyOwner returns (uint) {
      //default donor if unknown is SHA256('UNKNOWN')
      //check if donor already exists, if not add new donor
      if (!donors[_donorHash].exists) {
        donors[_donorHash] = Donor(0, true);
        emit DonationMadeToLuxarity(_donorHash, 0, true);
      }

      //increment tokenIndex
      tokenIndex += 1;

      //check if token doesn't exist yet
      require(_exists(tokenIndex) == true);

      //creating token hash to check uniqueness
      bytes32 tokenHash = keccak256(abi.encodePacked(_brand, _size, _style, _gender, _tokenURI, msg.sender, msg.sender, _donorHash));

      //create token struct
      luxTokens[tokenIndex] = LuxToken(tokenHash, _brand, _size, _style, _gender, _tokenURI, msg.sender, msg.sender, _donorHash);

      //mint token
      _mint(msg.sender, tokenIndex);

      //set metadata
      _setTokenURI(tokenIndex, _tokenURI);

      //emit event
      emit MintedToken(tokenIndex, msg.sender, _tokenURI);

      //return
      return tokenIndex;
    }

    //sold function
      //(1) that sets luxarity's funding address as the approved owner of the token id
      //as an escrow before the owner redeems it off-chain by using their secret off chain PIN
      //uses approve function to do so
      //(2) updates buyers and soldtokens mappings
      //(3) emits SoldToken event
    function soldItem(bytes32 _buyerID, uint256 _itemCost, bytes32 _redemptionHash, uint256 _tokenId) public onlyOwner returns (bool) {

      //check if buyer already exists
      if (!buyers[_buyerID].exists) {
        //adding new buyer to buyers mapping
        buyers[_buyerID] = Buyer(_itemCost, 0, true, address(0));
      } else {
        //update existing buyer
        buyers[_buyerID].totalContributed += _itemCost;
      }

      //check if token has been sold by luxarity before?
      //TBD - the point here is that we want index to be unique, which means selling a token
      //for the first time from luxarity only once, but we also want a secondary market to exist.
      //to, the soldTokens mapping only tracks what luxarity has sold, not sales between secondary
      //market participants afterwards, if a token is sold twice (say we get a refund request),
      //then it simply replaces its own index values from the last time it was sold and we deduct
      //its previous cost from the totals
      if (!soldTokens[_tokenId].sold) {
        //incrementing total amount of items sold because this is a NEW sale
        totalItemsSold += 1;

        //create new struct
        soldTokens[_tokenId] = SaleDetails(_buyerID, _redemptionHash, false, true, _itemCost);
        //increment total donations
        totalRaised += _itemCost;
        //update donor mapping to track end result of donation via sale
        donors[luxTokens[_tokenId].donorHash].fundsRaised += _itemCost;
        //emit event that token was sold
        emit SoldToken(_tokenId, _buyerID, soldTokens[_tokenId].cost);
        //return
        return true;

      }
      //a token can only be sold from luxarity if it is not already sold
      return false;
    }

    //chooseDonation function
      //used when owner of NFT chooses to donate to a chosen cause
      //(1) updates chosenDonations mapping
      //(2) emits DonationChosen event
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
      //when luxarity claims to have procesed donation
      //(1) updates madeDonations mapping
      //(2) emits MadeToCharity event
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
      //when buyer wants to redeem their token out of escrow
      //(1) checks for appropiate buyerHash and redemptionHash against SaleDetails associated with //(2) if true, then calls transferFrom and transfers token ownership from luxarity to buyer Address
      //(3) updates SaleDetails address for token id indicating new owne
      //(4) emits RedeemedToken event
    function redeemItem(bytes32 _buyerID, bytes32 _redemptionHash, address _buyerAddress, uint256 _tokenId) public onlyBuyer(_buyerID) returns (bool) {
      //make sure address is valid
      require(_buyerAddress != address(0));
      //make sure that sold item exists to be redeemed
      require(soldTokens[_tokenId].buyerHash == _buyerID);
      //make sure redemption secret is correct
      require(soldTokens[_tokenId].redemptionHash == _redemptionHash);
      //update token struct
      luxTokens[_tokenId].owner = _buyerAddress;
      //updates salesdetails struct
      soldTokens[_tokenId].redeemed = true;
      //conduct transfer from Luxarity to address
      transferFrom(msg.sender, _buyerAddress, _tokenId);
      //emit event
      emit RedeemedToken(_tokenId, _buyerID, _buyerAddress);
      return true;
    }

    //safe redeem token
      //when buyer wants to redeem their token out of escrow
      //(1) checks for appropiate buyerHash and redemptionHash against SaleDetails associated with //(2) if true, then calls safeTransferFrom and transfers token ownership from luxarity to buyer Address
      //(3) updates SaleDetails address for token id indicating new owne
      //(4) emits RedeemedToken event
    function safeRedeemItem(bytes32 _buyerID, bytes32 _redemptionHash, address _buyerAddress, uint256 _tokenId) public onlyBuyer(_buyerID) returns (bool) {
      //make sure address is valid
      require(_buyerAddress != address(0));
      //make sure that sold item exists to be redeemed
      require(soldTokens[_tokenId].buyerHash == _buyerID);
      require(soldTokens[_tokenId].redemptionHash == _redemptionHash);
      //update token struct
      luxTokens[_tokenId].owner = _buyerAddress;
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
      return soldTokens[_tokenId].sold;
    }

    //get token ownerOf
    function getTokenOwner(uint _tokenId) public view returns (address) {
      address owner = ownerOf(_tokenId);
      return owner;
    }

    //get donor total amount raised through donation
    function getDonationAmount(bytes32 _donorId) public view returns (uint) {
      require(donors[_donorId].exists == true);
      return donors[_donorId].fundsRaised;
    }

    //transfer ownership of contract
    function transferContract(address newOwner) public onlyOwner {
      transferOwnership(newOwner);
    }

    //fallback
	  function() payable public { }
}
