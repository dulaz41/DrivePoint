// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract MerchantBackend is ERC20, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    event CreatedToken(address tAddress);
    event MintedToken(uint256 tokenId);
    event Response(int256 response);
    event CarBorrowed(address borrower, uint256 borrowedAt);
    event CarReturned(address borrower, uint256 borrowedAt);

    uint256 public totalSupply;
    address public tokenAddress;
    uint256 public lockupAmount = 100000000000;
    Counters.Counter private tokenIdCounter;
    uint256 private constant BORROWING_PERIOD = 1 hours; // Can be modified to desired period

    constructor(uint256 _totalSupply) ERC20("Reputation Tokens", "REP") payable {
        owner = msg.sender;
        totalSupply = _totalSupply; //1000
    }

    function createNFT(string memory name, string memory symbol)
    IERC721(name, symbol)
        external
        payable
        onlyOwner
    {
       
    }

    function mintNFT(address token, bytes[] memory metadata)
        external
        onlyOwner
    {
        ERC20(token).mint(metadata);
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        emit MintedToken(tokenId);
    }

    function borrowing(address nftAddress, uint256 tokenId) external payable {
        require(msg.value == lockupAmount, "Incorrect amount");

        uint256 borrowedAt = block.timestamp;
        uint256 returnBy = borrowedAt + BORROWING_PERIOD;

        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        emit CarBorrowed(msg.sender, borrowedAt);
    }

    function returning(address nftAddress, uint256 tokenId) external payable {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        payable(msg.sender).transfer(lockupAmount);
        emit CarReturned(msg.sender, block.timestamp);
    }

    function scoring(address receiver, uint256 amount) external onlyOwner {
        require(amount <= 5, "Only can allocate up to 5 REP tokens");
        IERC20(tokenAddress).transfer(receiver, amount);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 borrowedAt;
        uint256 returnBy;
        (borrowedAt, returnBy) = abi.decode(checkData, (uint256, uint256));

        // Check if the current time has exceeded the returnBy time
        if (block.timestamp > returnBy) {
            upkeepNeeded = true;
            performData = abi.encode(borrowedAt, returnBy);
        } else {
            upkeepNeeded = false;
            performData = "";
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 borrowedAt;
        uint256 returnBy;
        (borrowedAt, returnBy) = abi.decode(performData, (uint256, uint256));

        // Perform the necessary actions when upkeep is needed
        // For example, handle the situation when the returnBy time has passed
        // In this case, you can revert the transaction or take appropriate actions
        revert("Car not returned within the borrowing period");
    }
}

