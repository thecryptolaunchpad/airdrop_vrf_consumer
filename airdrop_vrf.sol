// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 	0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
  

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 500000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 number_of_winners;

  address[] public contestants;
  uint256 announcement_date;
  //uint[] public shuffled;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  
  event Shuffled(uint[] indexed result);


     //airdrop campaign struct 
    struct AirDropCampaign {
      string contestName;
      uint32 numberOfWinners;
      address[]  contestants_addresses;
      uint256[]  winners;
      uint256 announcementDate;
      bool contestDone;
    }



  AirDropCampaign[] public airdropCampaigns;
  


  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    // Simulate whitelisting of 5 addresses
    // contestants.push(0x9Bab5eC53FFB74444b785fe6707651FD8E862E13);
    // contestants.push(0xC7939725901002c25e66aC11A170385B484D342c);
    // contestants.push(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
    // contestants.push(0x6168499c0cFfCaCD319c818142124B7A15E857ab);
    // contestants.push(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
  }
  
  function shuffle(
        uint size, 
        uint entropy
    ) 
    private  
    pure
    returns (
        uint[] memory
    ) {
        uint[] memory result = new uint[](size); 
        
        // Initialize array.
        for (uint i = 0; i < size; i++) {
           result[i] = i + 1;
        }
        
        // Set the initial randomness based on the provided entropy.
        bytes32 random = keccak256(abi.encodePacked(entropy));
        
        // Set the last item of the array which will be swapped.
        uint last_item = size - 1;
        
        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint selected_item = uint(random) % last_item;
            
            // Swap items `selected_item <> last_item`.
            uint aux = result[last_item];
            result[last_item] = result[selected_item];
            result[selected_item] = aux;
            
            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            last_item--;
            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }
        
        return result;
    }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    emit Shuffled(shuffle(contestants.length - 1, s_randomWords[0]));
  }
  

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

    function isContestant(uint contestIndex, address contestant )  public view returns (bool)  {
    require(contestIndex < airdropCampaigns.length , "Out of bounds");
     bool result = false;
      uint length = airdropCampaigns[contestIndex].contestants_addresses.length;
        for (uint i = 0; i<length; i++){
            if(airdropCampaigns[contestIndex].contestants_addresses[i] == contestant){
                result=true;
               break;
            }
        }
      return result;
  }

  function removeContestant(uint contestIndex, address contestant) external onlyOwner {
    require(contestIndex < airdropCampaigns.length , "Out of bounds");
    uint length = airdropCampaigns[contestIndex].contestants_addresses.length;
   address[] storage  addressesOfThisContest =  airdropCampaigns[contestIndex].contestants_addresses;
      for (uint i = 0; i<length; i++){
         if( addressesOfThisContest[i]== contestant){
            for (uint j = i; j<addressesOfThisContest.length-1; j++){
                addressesOfThisContest[j] = addressesOfThisContest[j+1];
            }
          addressesOfThisContest.pop();
          airdropCampaigns[contestIndex].contestants_addresses = addressesOfThisContest;
         }
      }

  }

  function addContestant(uint contestIndex, address contestant_address) external onlyOwner {
    require(airdropCampaigns[contestIndex].contestDone ==false , "Contest Ended");
    require(contestIndex < airdropCampaigns.length, "Out of bounds");
    bool doesListContainElement = false;
    address[] memory list = airdropCampaigns[contestIndex].contestants_addresses;
    for (uint i=0; i < list.length; i++) {
      if (contestant_address == list[i]) {
          doesListContainElement = true;
          break;
      }
    }
    require(doesListContainElement == false, "Cotestant already registered for this contest");
    airdropCampaigns[contestIndex].contestants_addresses.push(contestant_address);
  }

    //Configure Contestants and number of winners and Name Of Airdrop Campaign, AnnouncementDate
  function configureNewAirdrop(string memory name_of_contest,uint32 winners_count,address[] memory  contestant_address_array, uint256 date_of_announcement) external onlyOwner {
    AirDropCampaign memory campaign;
    campaign.contestName = name_of_contest;
    campaign.numberOfWinners = winners_count;
    campaign.contestants_addresses = contestant_address_array;
    campaign.contestDone =false;
    campaign.announcementDate = date_of_announcement;
    airdropCampaigns.push(campaign);
  }

  // Assumes the subscription is funded sufficiently.
  function drawContest(uint contestIndex) external onlyOwner {
    require(airdropCampaigns[contestIndex].contestDone ==false , "Already Drawn");
     require(contestIndex < airdropCampaigns.length , "Out of bounds");
    contestants =  airdropCampaigns[contestIndex].contestants_addresses;
  // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      airdropCampaigns[contestIndex].numberOfWinners
    );
    airdropCampaigns[contestIndex].contestDone =true;
  }

  function updateWinners(uint contestIndex) public  onlyOwner{
    airdropCampaigns[contestIndex].winners = s_randomWords ;
    delete contestants;
  }

  function removeAirDropCampaign(uint contestIndex) external onlyOwner {
     require(contestIndex < airdropCampaigns.length , "Out of bounds");
    for (uint i = contestIndex; i<airdropCampaigns.length-1; i++){
          airdropCampaigns[i] = airdropCampaigns[i+1];
      }
    delete airdropCampaigns[airdropCampaigns.length-1];
    airdropCampaigns.pop;
  }

   function getWinnersOfAContest(uint contestIndex) external view returns( uint256[] memory) {
    return airdropCampaigns[contestIndex].winners;
   }

     function getContestantsOfAContest(uint contestIndex) external view returns( address[] memory) {
     return  airdropCampaigns[contestIndex].contestants_addresses;
   }

}

