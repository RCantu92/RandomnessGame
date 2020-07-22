# Randomness Guessing Game

Game that requires two players to correctly guess a randomly generated number between 0-255. Whoever is closest to the random number, wins the pot, which consists of the player’s entry fee.

Because the randomness is generated every 240 blocks, there is a cool down time implemented to wait for the next random number to be generated.

## Process, Explained:

A player would check to see if the game is active by calling isGameActive(). If false, that player is player one and submits a guess between 0-255. Afterwards, when a second player submits a guess between 0-255, the veedo beacon is called and a random number between 0-255 is generated. Then the logic in the game checks to see which of the two guesses is closest to the randomly generated number. It would then automatically disperse the winnings to the correct player.

In the case the players guess the same number, they would be returned their entry fee.

## Technical, Explained:

The main technical aspect is how the random number is generated, which is provided from the VeeDo beacon. The function getLatestRandomness() is called, and the resulting bytes is converted into a uint, which in turn is converted into a uint8 to convert it to its final target number.

## License:

2020 Roberto Cantu MIT License.