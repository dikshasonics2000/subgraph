// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {

    uint256 public fee; // the amount of fees to  send with the request

    bytes32 public keyHash;//     // ID of public key against which randomness is generated

    address[] public players;// total number of players and their address
    uint8 maxPlayers;// max number of players
    bool public gameStarted;// variable to indicate whether the game has started or not
    uint256 entryFee;// the entry fee given by eeach individual player
    uint256 public gameId;// current gameID 

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);

    event PlayerJoined(uint256 gameId, address player);

    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint256 vrfFree) VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFree;
        gameStarted = false;
    }

    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!gameStarted, "Game is already running");
        
        delete players;
        maxPlayers = _maxPlayers;
        gameStarted = true;
        entryFee = _entryFee;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);
            }


    function joinGame() public payable {
        require(gameStarted, "Game has not been started yet");
        require(msg.value == entryFee, "Value sent is not equal to entryFee");
        require(players.length < maxPlayers, "Game is full");

        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);

        if(players.length == maxPlayers) {
            getRandomWinner();
        }
    }

    function  fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {
        //We want the ether in between the range of max players so we will do mod in it.
        uint256 winnerIndex = randomness % players.length;

        address winner = players[winnerIndex];
        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "did not send the ether");

        emit GameEnded(gameId, winner, requestId);

        gameStarted = false;
    }

    function getRandomWinner() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    receive() external payable {}

    fallback() external payable {}
    }
    /*vrfCoordinator which is the address of the VRFCoordinator contract


linkToken is the address of the link token which is the token in which the chainlink takes its payment

vrfFee is the amount of link token that will be needed to send a randomness request

vrfKeyHash which is the ID of the public key against
 which randomness is generated. This value is 
 responsible for generating an unique Id for our randomneses request called as requestId*/