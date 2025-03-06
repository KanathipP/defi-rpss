// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS {
    enum GameState {
        IDLE,
        COMMIT,
        REVEAL
    }


    GameState public gameState = GameState.IDLE;
    CommitReveal public commitReveal = new CommitReveal();
    TimeUnit public timeUnit = new TimeUnit();

    uint8 public player_count = 0;
    uint8 public reward = 0;

    address[] public allowed_players = [
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
        ];
    address[] public players;

    mapping(address => bool) public player_committed;
    mapping(address => bool) public player_revealed;

    uint8 public player_committed_count = 0;
    uint8 public player_revealed_count = 0;

    uint _commitDeadline;
    uint _revealDeadline;

    mapping(address => uint8) public player_choice;

    

    function _resetGame() private {
        gameState = GameState.IDLE;
        player_count = 0;
        reward = 0;
        player_committed_count = 0;
        player_revealed_count = 0;

        delete players;
        
        for (uint i = 0; i < players.length; i++) {
            player_committed[players[i]] = false;
            player_revealed[players[i]] = false;
            player_choice[players[i]] = 0;
        }
    }


    function isAllowed(address player) internal view returns (bool) {
        for (uint i = 0; i < allowed_players.length; i++) {
            if (allowed_players[i] == player) {
                return true;
            }
        }
        return false;
    }

    function joinGame() public payable {
        require(gameState == GameState.IDLE, "[RPS]::Not in the idle state, can't join");

        require(player_count < 2, "[RPS]::Game is full");
        require(msg.value == 1 ether, "[RPS]::Need 1 ether to play");

        address player_address = msg.sender;
        require(isAllowed(player_address), "[RPS]::Player not allowed");
        if (player_count == 1)
            require(
                players[0] != player_address,
                "[RPS]::Can't play against yourself!"
            );

        player_count += 1;
        players.push(player_address);
        reward += 1;

        if (player_count == 2) {
            gameState = GameState.COMMIT;
            _commitDeadline = block.timestamp + 300;
            timeUnit.setStartTime();
        }

    }

    /*
    @params paddedData : paddedData is a 32 bytes padded data from this python code
        https://colab.research.google.com/drive/1cPqxOqzJ-brL05pd0WRAwwwK0Zzx-Rnl?usp=sharing
    */

    function commit(bytes32 paddedData) public {
        require(gameState == GameState.COMMIT , "[RPS]::Not in the commit state , can't play");
        require(players[0] == msg.sender || players[1] == msg.sender, "[RPS]::you are not the player");
        require(!player_committed[msg.sender], "[RPS]::Player already played");

        //Check the padded data
        uint8 choice = uint8(paddedData[31]);
        require (choice <= 4, "[RPS]::Wrong input , padded data have to end with 0, 1, 2, 3 or 4");

        bytes32 hashedData = commitReveal.getHash(paddedData);

        commitReveal.commit(msg.sender,hashedData);

        player_committed[msg.sender] = true;
        player_committed_count += 1;

        if (player_committed_count == 2) {
            gameState = GameState.REVEAL;
            _revealDeadline = block.timestamp + 300;
            timeUnit.setStartTime();
        }
    }

    function reveal(bytes32 paddedData) public {
        require(gameState == GameState.REVEAL, "[RPS]::Not in the reveal state,every player have to commit");
        require(players[0] == msg.sender || players[1] == msg.sender, "[RPS]::you are not the player");
        require(player_revealed[msg.sender] == false, "[RPS]::Already revealed");
        uint8 choice = uint8(paddedData[31]);
        require (choice <= 4, "[RPS]::Wrong input , padded data have to end with 0, 1, 2, 3 or 4");

        commitReveal.reveal(msg.sender, paddedData);

        player_choice[msg.sender] = choice;
        player_revealed[msg.sender] = true;
        player_revealed_count += 1;
        if (player_revealed_count == 2) {
            _checkWinnerAndPay();
             _resetGame();
        }
  }

  function abort() public {
    require(players.length > 0, "[RPS]::No active game");
    require(players[0] == msg.sender || (players.length > 1 && players[1] == msg.sender), "[RPS]::You are not a player");

    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);

    if (gameState == GameState.IDLE) {
        account0.transfer(reward);
        _resetGame();
    }

    else if (gameState == GameState.COMMIT) {
        require(timeUnit.elapsedSeconds() >= _commitDeadline, "[RPS]::Commit deadline has not passed");
        require(player_committed[msg.sender], "[RPS]::You have to commit if you want to abort the game");
            if (player_committed[players[0]] && !player_committed[players[1]]) {
            account0.transfer((reward*3)/5);  
            account1.transfer((reward*2)/5); 
        } 
        else if (!player_committed[players[0]] && player_committed[players[1]]) {
            account1.transfer((reward*3)/5); 
            account0.transfer((reward*2)/5);  
        } 
        }
    
    else if (gameState == GameState.REVEAL) {
        require(timeUnit.elapsedSeconds() >= _revealDeadline, "[RPS]::Reveal deadline has not passed");
        require(player_revealed[msg.sender], "[RPS]::You have to reveal if you want to abort the game");
        if (player_revealed[players[0]] && !player_revealed[players[1]]) {
            account0.transfer(reward);  // Player 0 Reveal คนเดียว → ได้ 100%
        } 
        else if (!player_revealed[players[0]] && player_revealed[players[1]]) {
            account1.transfer(reward);  // Player 1 Reveal คนเดียว → ได้ 100%
        } 

        _resetGame();
    } 
}

   function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3)%5 == p1Choice ) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
