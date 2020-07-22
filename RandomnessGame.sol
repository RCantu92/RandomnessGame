// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "https://github.com/starkware-libs/veedo/blob/master/contracts/BeaconContract.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c4bb7b7bb9f09534bf010f6bf6f0d85bf2bf1caa/contracts/math/SafeMath.sol";

/**
 * @title Randomness Game
 * @notice Contract to play the game. Game requires
 * two players to try to guess a random number between
 * 0-255. Whoever is closest, wins the total price of entry
 * of both players.
 */
contract RandomnessGame {
    
    address veedoBeaconAddress;
    address owner;
    
    uint8 public guessOne; // Make private for end
    uint8 public guessTwo; // Make private for end
    uint public targetNumber; // Make private for end
    
    bool hasFirstGuess = false;
    bool hasSecondGuess = false;
    
    address payable public playerOne; // Make private for end
    address payable public playerTwo; // Make private for end
    address public winningAddress;
    
    bool public isGameActive = false;
    bool public tieGame = false;
    
    uint public coolDownTime; // Make private for end
    uint public blockNow = block.number; // Delete. For testing only.
    
    event addedPlayer(address _player);
    event winningsDispersed(address _winner, uint _winnings);
    
    // Modifier not needed after demo
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @notice Constructor function that will take the beacon address
     *  and call setBeaconContractAddress() to set it to the variable.
     * It will also set the creator of the contract as the owner.
     * @param _veedoBeaconAddress address of the VeeDo beacon that
     * will provide randomness.
     */
    constructor(address _veedoBeaconAddress) public {
        setBeaconContractAddress(_veedoBeaconAddress);
        owner = msg.sender; // delete after demo
    }
    
    /**
     * @notice Fallback function that returns funds sent to
     * it on accident.
     */
    function () external payable {
        msg.sender.transfer(msg.value);
    }
    
    /**
     * @notice Function that resets the game by
     * clearing all relevant variables.
     */
    function resetGame() public /*private*/ onlyOwner() /*delete modifier*/ {
        guessOne = 0;
        guessTwo = 0;
        targetNumber = 0;
        hasFirstGuess = false;
        hasSecondGuess = false;
        playerOne = address(0);
        playerTwo = address(0);
        winningAddress = address(0);
        isGameActive = false;
        tieGame = false;
        blockNow = block.number; // Delete. For testing only.
    }
    
    /**
     * @notice Function called to play the game. Game requires
     * two players to try to guess a random number between
     * 0-255. Whoever is closest, wins the total price of entry
     * of all players.
     * @param _guess a uint8 guess to try to be the closest
     * to a randomly generated number.
     */
    function playGame(uint8 _guess) public payable {
        // Verifying that 240 blocks has passed since
        // the last randomly generated number.
        require(
            block.number > (coolDownTime + 240),
            "Not enough time has passed to play again."
        );
        
        // Verify 0.1 ether have been sent.
        // (0.1 ether for testing only,
        // 0.02 ether will be the normal amount)
        require(msg.value == 0.1 ether);
        
        // Confirm the guess is valid (0-255)
        require(_guess < 256);
        
        // Submit guess as valid for second player
        // if first player has guessed already.
        if (hasFirstGuess == true) {
            guessTwo = _guess;
            playerTwo = msg.sender;
            hasSecondGuess = true;
            isGameActive = true;
            emit addedPlayer(msg.sender);
            // After both guesses have been
            // submitted, calculate the target number.
            targetNumber = getRandomNumber();
        // If guess one has not been declared,
        // set equal to function argument.
        } else {
            guessOne = _guess;
            playerOne = msg.sender;
            hasFirstGuess = true;
            isGameActive = true;
            emit addedPlayer(msg.sender);
        }
        
        // Compare the guesses to the
        // target number, decide the winner
        // and disperse the winnings.
        if (
            hasFirstGuess == true && hasSecondGuess == true
        ) {
            if (
                guessOne == guessTwo
            ) {
                tieGame = true;
                playerOne.transfer((address(this).balance) / 2);
                playerTwo.transfer((address(this).balance) / 2);
            } else if (
                (guessOne < targetNumber) &&
                (guessTwo < targetNumber)
            ) {
                if (
                    (SafeMath.sub(targetNumber, guessOne)) <
                    (SafeMath.sub(targetNumber, guessTwo))
                ) {
                    awardWinner(playerOne);
                } else if (
                    (SafeMath.sub(targetNumber, guessTwo)) <
                    (SafeMath.sub(targetNumber, guessOne))
                ) {
                    awardWinner(playerTwo);
                }
            } else if (
                (guessOne > targetNumber) &&
                (guessTwo > targetNumber)
            ) {
                if (
                    (SafeMath.sub(guessOne, targetNumber)) <
                    (SafeMath.sub(guessTwo, targetNumber))
                ) {
                    awardWinner(playerOne);
                } else if (
                    (SafeMath.sub(guessTwo, targetNumber)) <
                    (SafeMath.sub(guessOne, targetNumber))
                ) {
                    awardWinner(playerTwo);
                }
            } else if (
                (guessOne > targetNumber) &&
                (guessTwo < targetNumber)
            ) {
                if (
                    (SafeMath.sub(guessOne, targetNumber)) <
                    (SafeMath.sub(targetNumber, guessTwo))
                ) {
                    awardWinner(playerOne);
                } else if (
                    (SafeMath.sub(targetNumber, guessTwo)) <
                    (SafeMath.sub(guessOne, targetNumber))
                ) {
                    awardWinner(playerTwo);
                }
            } else if (
                (guessOne < targetNumber) &&
                (guessTwo > targetNumber)
            ) {
                if (
                    (SafeMath.sub(targetNumber, guessOne)) <
                    (SafeMath.sub(guessTwo, targetNumber))
                ) {
                    awardWinner(playerOne);
                } else if (
                    (SafeMath.sub(guessTwo, targetNumber)) <
                    (SafeMath.sub(targetNumber, guessOne))
                ) {
                    awardWinner(playerTwo);
                }
            }
            
            // resetGame();
            
            // Calling and setting the value of the latest 
            // block to provide a random number to begin
            // a cool down period until the next pulse.
            BeaconContract veedoBeacon = BeaconContract(veedoBeaconAddress);
            (uint latestBlockNumber, bytes32 registeredRandomness) = veedoBeacon.getLatestRandomness();
            coolDownTime = latestBlockNumber;
        }
    }
    
    // @notice Function to withdraw funds in case game
    // doesn't work as expected. Only for testing.
    function withdrawFunds() public {
        msg.sender.transfer(address(this).balance);
    }
    
    /*
     * @notice Setter function that adds randomness beacon
     * address to previously declared address variable
     * @param _address address of the beacon that
     * will provide randomness.
     */
    function setBeaconContractAddress(address _address) private {
        veedoBeaconAddress = _address;
    }
    
    /**
     * @notice Function that sends out funds to
     * winning address.
     * @param _player address of the winning
     * player to receive funds.
     */
    function awardWinner(address payable _player) private {
        emit winningsDispersed(_player, address(this).balance);
        winningAddress = _player;
        _player.transfer(address(this).balance);
    }
    
    /**
     * @notice Function called to generate new randon number
     * from beacon contract, that will then be converted
     * into a uint8.
     * @return uint the randomly generated number.
     */
    function getRandomNumber() private view returns(uint) {
        BeaconContract veedoBeacon = BeaconContract(veedoBeaconAddress);
        (uint latestBlockNumber, bytes32 registeredRandomness) = veedoBeacon.getLatestRandomness();
        uint randomNumber = uint(registeredRandomness);
        randomNumber = uint8(randomNumber);
        return randomNumber;
    }
}