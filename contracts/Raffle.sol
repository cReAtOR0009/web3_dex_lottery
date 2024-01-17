//Raffle
//Enter thr lottery paying some amount
//pick a random winner(verifiable winner)
//winner to be selected every specific minutes ->completely automated
// chainlink orcle -> randomness, automated execution (chainlink keepers)

// SPDX-License-Identifier: MIT
// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.7;


import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Raffle_notEnoughEthEntered();
error Raffle_TransferFailed();
error Raffle_Notopen();
error Raffle_UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);


contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
      /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    //State Varialbes
    uint256 private immutable i_entranceFee;
    address[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //Lottery Variables
    address private s_recentWinner;
    RaffleState private s_raffleState; 
    uint256 private s_lastTimeStamp
    uint256 private immutable i_interval


    //events
    event RaffleEntered(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
        // RaffleState raffleState
    )  VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp
        i_interval = interval
    }

    function enterRaffle() public payable {
         // require(msg.value >= i_entranceFee, "Not enough value sent");
        // require(s_raffleState == RaffleState.OPEN, "Raffle is not open");
        require(msg.value > i_entranceFee, "not enough eth ");

        if (msg.value < i_entranceFee) {
            revert Raffle_notEnoughEthEntered();
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle_Notopen()
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

        function checkUpkeep(
        bytes calldata // checkData
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = (RaffleState.OPEN == s_raffleSate);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval)
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    }

    function performUpkeep( bytes calldata /* performData */) external override {

        (bool, upkeepNeeded) = checkUpkeep("")

        if(!upkeepNeeded) {
            revert Raffle_UpKeepNotNeeded( address(this).balance, s_players.length, uint32(s_raffleState))
           
        }
        
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, // requstId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }

        emit WinnerPicked(recentWinner);
    }

    function getEntranceFes() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

     function getRaffleaState() public view returns (address) {
        return s_raffleState;
    }

     function getNumWords() public view returns (uint256) {
        return NUM_WORDS;
    }
}
