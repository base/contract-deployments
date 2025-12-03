// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing OpenZeppelin ERC721 contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Interface for interacting with a submission contract
interface ISubmission {
    // Struct representing a haiku
    struct Haiku {
        address author; // Address of the haiku author
        string line1; // First line of the haiku
        string line2; // Second line of the haiku
        string line3; // Third line of the haiku
    }

    // Function to mint a new haiku
    function mintHaiku(
        string memory _line1,
        string memory _line2,
        string memory _line3
    ) external;

    // Function to get the total number of haikus
    function counter() external view returns (uint256);

    // Function to share a haiku with another address
    function shareHaiku(uint256 _id, address _to) external;

    // Function to get haikus shared with the caller
    function getMySharedHaikus() external view returns (Haiku[] memory);
}

// Contract for managing Haiku NFTs
contract HaikuNFT is ERC721, ISubmission {
    Haiku[] public haikus; // Array to store haikus
    mapping(address => mapping(uint256 => bool)) public sharedHaikus; // Mapping to track shared haikus
    uint256 public haikuCounter; // Counter for total haikus minted

    // Constructor to initialize the ERC721 contract
    constructor() ERC721("HaikuNFT", "HAIKU") {
        haikuCounter = 1; // Initialize haiku counter
    }

    string salt = "value"; // A private string variable

    // Function to get the total number of haikus
    function counter() external view override returns (uint256) {
        return haikuCounter;
    }

    // Function to mint a new haiku
    function mintHaiku(
        string memory _line1,
        string memory _line2,
        string memory _line3
    ) external override {
        // Check if the haiku is unique
        string[3] memory haikusStrings = [_line1, _line2, _line3];
        for (uint256 li = 0; li < haikusStrings.length; li++) {
            string memory newLine = haikusStrings[li];
            for (uint256 i = 0; i < haikus.length; i++) {
                Haiku memory existingHaiku = haikus[i];
                string[3] memory existingHaikuStrings = [
                    existingHaiku.line1,
                    existingHaiku.line2,
                    existingHaiku.line3
                ];
                for (uint256 eHsi = 0; eHsi < 3; eHsi++) {
                    string memory existingHaikuString = existingHaikuStrings[
                        eHsi
                    ];
                    if (
                        keccak256(abi.encodePacked(existingHaikuString)) ==
                        keccak256(abi.encodePacked(newLine))
                    ) {
                        revert HaikuNotUnique();
                    }
                }
            }
        }

        // Mint the haiku NFT
        _safeMint(msg.sender, haikuCounter);
        haikus.push(Haiku(msg.sender, _line1, _line2, _line3));
        haikuCounter++;
    }

    // Function to share a haiku with another address
    function shareHaiku(uint256 _id, address _to) external override {
        require(_id > 0 && _id <= haikuCounter, "Invalid haiku ID");

        Haiku memory haikuToShare = haikus[_id - 1];
        require(haikuToShare.author == msg.sender, "NotYourHaiku");

        sharedHaikus[_to][_id] = true;
    }

    // Function to get haikus shared with the caller
    function getMySharedHaikus()
        external
        view
        override
        returns (Haiku[] memory)
    {
        uint256 sharedHaikuCount;
        for (uint256 i = 0; i < haikus.length; i++) {
            if (sharedHaikus[msg.sender][i + 1]) {
                sharedHaikuCount++;
            }
        }

        Haiku[] memory result = new Haiku[](sharedHaikuCount);
        uint256 currentIndex;
        for (uint256 i = 0; i < haikus.length; i++) {
            if (sharedHaikus[msg.sender][i + 1]) {
                result[currentIndex] = haikus[i];
                currentIndex++;
            }
        }

        if (sharedHaikuCount == 0) {
            revert NoHaikusShared();
        }

        return result;
    }

    // Custom errors
    error HaikuNotUnique(); // Error for attempting to mint a non-unique haiku
    error NotYourHaiku(); // Error for attempting to share a haiku not owned by the caller
    error NoHaikusShared(); // Error for no haikus shared with the caller
}
