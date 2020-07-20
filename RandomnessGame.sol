pragma solidity ^0.5.0;

import "https://github.com/starkware-libs/veedo/blob/master/contracts/BeaconContract.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c4bb7b7bb9f09534bf010f6bf6f0d85bf2bf1caa/contracts/math/SafeMath.sol";

contract randomnessGame {
    
    address veedoBeaconAddress;
    
    uint8 public guessOne; // Make private for end
    uint8 public guessTwo; // Make private for end
    uint public targetNumber; // not public after testing, put inside playGame()
    
    bool public hasFirstGuess = false;
    bool public hasSecondGuess = false;
    
    address payable public playerOne;
    address payable public playerTwo;
    address public winningAddress;
    bool activeGame = false;
    
    event addedPlayer(address _player);
    event winningsDispersed(address _winner, uint _winnings);
    
    function setBeaconContractAddress(address _address) private {
        veedoBeaconAddress = _address;
    }
    
    // 1. Create contract and enter VeeDo Beacon contract
    // address to call its random function
    constructor(address _veedoBeaconAddress) public {
        setBeaconContractAddress(_veedoBeaconAddress);
    }
    
    // 2. Player will check if there a submitted
    // game with funds in it.
    function isGameActive() public view returns(bool) {
        return activeGame;
    }
    
    // Make private and view at end. Only public for testing
    function getRandomNumber() public /*private view*/ returns(uint) {
        BeaconContract veedoBeacon = BeaconContract(veedoBeaconAddress);
        (uint latestBlockNumber, bytes32 registeredRandomness) = veedoBeacon.getLatestRandomness();
        uint randomNumber = uint(registeredRandomness);
        // if greater than 100, divide by uint(getLatestRandomness)
        targetNumber = uint8(randomNumber * now); // Pass it on to return
        //return randomNumber;
    }
    
    function resetGame() private {
        guessOne = 0;
        guessTwo = 0;
        playerOne = address(0);
        playerTwo = address(0);
        hasFirstGuess = false;
        hasSecondGuess = false;
        activeGame = false;
    }
    
    // 3. If game is inactive, submit funds and
    // a number between 0 - 255.
    function playGame(uint8 _guess) public payable returns(string memory) {
        // 3a. Verify 0.02 ether have been sent
        // (0.1 ether for testing only)
        require(msg.value == 0.1 ether);
        
        // 3b. Confirm the guess is valid (0-255)
        require(_guess < 256);
        
        // 3c. Submit guess as valid for second player
        // if first player has guessed already
        if(guessOne > 0) {
            guessTwo = _guess;
            playerTwo = msg.sender;
            hasSecondGuess = true;
            activeGame = true;
            emit addedPlayer(msg.sender);
            // 3d. After both guesses have been
            // submitted, calculate the
            // target number.
            // targetNumber = getRandomNumber();  Keep line for final version
        // If guess one has not been declared,
        // set equal to function argument.
        } else {
            guessOne = _guess;
            playerOne = msg.sender;
            hasFirstGuess = true;
            activeGame = true;
            emit addedPlayer(msg.sender);
        }
        
        // 3e. Compare the guesses to the
        // target number, decide the winner
        // and disperse the winnings.
        if(hasFirstGuess == true && hasSecondGuess == true) {
            if(
                (targetNumber - guessOne) < (targetNumber - guessTwo) ||
                (guessOne - targetNumber) < (guessTwo - targetNumber) ||
                (targetNumber - guessOne) < (guessTwo - targetNumber) ||
                (guessOne - targetNumber) < (targetNumber - guessTwo)
                /*
                (SafeMath.sub(targetNumber, guessOne)) < (SafeMath.sub(targetNumber, guessTwo)) ||
                (SafeMath.sub(guessOne, targetNumber)) < (SafeMath.sub(guessTwo, targetNumber)) ||
                (SafeMath.sub(targetNumber, guessOne)) < (SafeMath.sub(guessTwo, guessTwo)) ||
                (SafeMath.sub(guessOne, targetNumber)) < (SafeMath.sub(targetNumber, guessTwo))
                */
            ) {
                emit winningsDispersed(playerOne, address(this).balance);
                winningAddress = playerOne;
                playerOne.transfer(address(this).balance);
                // resetGame();
            } else if (
                (targetNumber - guessTwo) < (targetNumber - guessOne) ||
                (guessTwo - targetNumber) < (guessOne - targetNumber) ||
                (targetNumber - guessTwo) < (guessOne - targetNumber) ||
                (guessTwo - targetNumber) < (targetNumber - guessOne)
                /*
                (SafeMath.sub(targetNumber, guessTwo)) < (SafeMath.sub(targetNumber, guessOne)) ||
                (SafeMath.sub(guessTwo, targetNumber)) < (SafeMath.sub(guessOne, targetNumber)) ||
                (SafeMath.sub(targetNumber, guessTwo)) < (SafeMath.sub(guessOne, targetNumber)) ||
                (SafeMath.sub(guessTwo, targetNumber)) < (SafeMath.sub(targetNumber, guessOne))
                */
            ) {
                emit winningsDispersed(playerTwo, address(this).balance);
                winningAddress = playerTwo;
                playerTwo.transfer(address(this).balance);
                // resetGame();
            } else {
                playerOne.transfer((address(this).balance) / 2);
                playerTwo.transfer((address(this).balance) / 2);
                // resetGame();
            }
        } else {
            return "Not enough players.";
        }
    }
    
    function withdrawFunds() public {
        msg.sender.transfer(address(this).balance);
    }
    
}