# LuxToken & LuxOrder

The following repository hosts the codebase for the tokenized item and tokenized order smart contracts for Luxarity. LUXARITY is a social venture with the vision to inspire a conscious living for all. Its mission is to build a community that shares the values of Responsibility, Awareness & Wonder by selling curated pre-loved luxury goods, collaborating with strategic partners, and giving all the benefits back to the community through grants.

The repository has two token models that are fit to two different check out processes: 

1. **Tokenized Orders:** If the checkout process **uses non-unique, categorical SKU#s,** where an item of a certain style and price is put into a broader category,  then it is best to tokenize orders to transparently track the sale-to-donate supply chain. This means that each order is represented as a token. The token is an attestation that someone bought something and contributed to a good cause faciliated by Luxarity. Such tokenized orders are non-fungible ‘assets,’ but do not represent flexible value, as order token can only be transfered to someone else if all items that make up that order are trasnferred as well. 

2. **Tokenized Items:** If the checkout process **uses unique SKU#s for each item,**  then it is best to tokenize items to transparently track the donate-to-donate supply chain. This supply chain includes the moment at which a donor gives the item to Luxarity to be resold and raise grant money - providing a transparent supply chain for both the item’s orginal donor and its buyer. This means that each item is represented as a token. Such tokens are non-fungible, as every item is unique (even though it may be the same brand and style and price). Tokenized items can be transacted much more fluidly than tokenized orders, given an order can have any number of items as apart of it. 

## Luxarity Donation Supply Chain 
![Donation Supply Chain](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/DonationSupplyChain.png)

1. First, philanthropists donate their luxary clothing items to Luxarity. Such items will be resold to raise capital to fund the grants that Luxarity provides to social enterprises and nonprofits. A SHA256 hash of the donor's email (or any other unique, off-chain identifier) is added to a list of donor psuedo-identites to track the lifecycle of the donated item (from donation, to resale, etc.). We do this in order to attribute resale amounts back to the original donors of those items.  

2. Second, the items are tokenized, each given their own unique SKU# (or NFT Token ID). These SKU#s will be scanned during checkout when consumers come to buy the items. 

3. Once an item is sold, the proceeds are tracked on-chain and associated with the original donor of that item (or token). The buyer's off-chain identity (SHA256(email)) is also added to a buyers list, in order to track buyer contributions psuedo-anonymously (and, thus begin the buyer side donation supply chain).

4. Next, each buyer determines which charities they want their sale proceeds to go from a determined list of beneficiary partners that Luarity is working with. Each charity choice and amount is tracked on chain (solidifying yet another point in the donation supply chain where the buyer chooses where proceeds should go to). 

5. Finally, after buyers have chosen where they want to send their proceeds, and all items have been sold, Luxarity is then obliged to create the grants from the funds raised, and, proportionally, divide and disburse the grants to each of the charity organizations (based on the total amount chosen to go to each organization by the buyers). Luxarity must confirm their grant disbursements by adding an IPFS link to their donation receipt on chain, as well as the amount provided to each charity, and the charity's name. The transaction serves as an attestation to resposible use of the funds (which should be a 1-1 allocation from orginal item donor all the way to the grant served to the charity)  


## Tokenized Orders vs. Tokenized Items
If we compare these two methods of tokenization, we can reveal the pros and cons of each, and thus, assess their longer term viability as mechanisms for donation transparency. As we can see, donation transparency of tokenized items is a much more sustainable model, but the checkout process is more difficult to set up.  

![Tokenized Asset Comparison](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/TokenAssetComparison.png)

Note, that setting up a sales process is more difficult because it requires to tag every item with a unique SKU#, rather than a categorical SKU# that provides multiple, similar items, with the same id. 

## Secondary & Derrivative Markets of Resold, Donated Goods  
TBD

### Tokenized Item Smart Contract Variables & Functions  
Based on the touchpoints that we need to track to provide full transparency within the donation supply chain, what data needs to be stored on chain? The following is a proposal of what we need to track: 

![Item Touchpoints](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/ItemTouchpoints.png)

Actions comprise of variables that track important actions across the donation supply chain, like a consumer choosing which charity she wants her money to go to, Luxarity making a formal grant disbursement, and a sale ocurring.

![Item Actions](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/ItemActions.png)

Assets are comprised of variables that have an innate value (non-fungible assets) that need to be tracked on chain. 

![Item Tokens](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/ItemTokens.png)

Identities are comprised of variables that track psudoanonymous identities of buyers and donors. 

![Item Identities](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/TokenIdentities.png)

Assets are comprised of variables that have an innate value (non-fungible assets) that need to be tracked on chain. 

![Item Actions](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/TokenActions.png)


### Tokenized Order Smart Contract Variables & Functions 
Based on the touchpoints that we need to track to provide full transparency within the donation supply chain, what data needs to be stored on chain? The following is a proposal of what we need to track: 

![Order Touchpoints](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/OrderTouchpoints.png)

Actions comprise of variables that track important actions across the donation supply chain, like a consumer choosing which charity she wants her money to go to, Luxarity making a formal grant disbursement, and a sale ocurring.

![Order Actions](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/OrderActions.png)

Assets are comprised of variables that have an innate value (non-fungible assets) that need to be tracked on chain. 

![Order Tokens](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/OrderTokens.png)

Identities are comprised of variables that track psudoanonymous identities of buyers and donors. 

![Order Identities](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/OrderIdentities.png)

Assets are comprised of variables that have an innate value (non-fungible assets) that need to be tracked on chain. 

![Item Actions](https://github.com/ConsenSys/LuxToken/blob/master/ReadMeImgs/TokenActions.png)

# LuxOrder Test Contracts & Resources
- Test Contract on Rinkeby After Testing (v1): 0xfd2A3ED81b259156DBA0b8FAd149010e6662C8F4
