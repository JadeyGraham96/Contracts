// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LandToken is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public nextTokenId;
    mapping(uint256 => mapping(address => uint256)) public tokenShares;
    mapping(uint256 => uint256) public totalShares;
    mapping(uint256 => address[]) public shareholders;

    event SharesTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);

    constructor() ERC721("LandToken", "LAND") {}

    function mint(address to, uint256 initialShares) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _mint(to, tokenId);
        tokenShares[tokenId][to] = initialShares;
        totalShares[tokenId] = initialShares;
        shareholders[tokenId].push(to);
        nextTokenId = nextTokenId.add(1);
    }

    function transferShares(uint256 tokenId, address from, address to, uint256 amount) external {
        require(msg.sender == from, "Only the token holder can transfer shares");
        require(tokenShares[tokenId][from] >= amount, "Insufficient shares");

        tokenShares[tokenId][from] = tokenShares[tokenId][from].sub(amount);
        tokenShares[tokenId][to] = tokenShares[tokenId][to].add(amount);

        if (tokenShares[tokenId][from] == 0) {
            removeShareholder(tokenId, from);
        }

        if (tokenShares[tokenId][to] == amount) {
            addShareholder(tokenId, to);
        }

        emit SharesTransferred(tokenId, from, to, amount);
    }

    function addShareholder(uint256 tokenId, address shareholder) internal {
        if (!isShareholder(tokenId, shareholder)) {
            shareholders[tokenId].push(shareholder);
        }
    }

    function removeShareholder(uint256 tokenId, address shareholder) internal {
        if (isShareholder(tokenId, shareholder)) {
            for (uint256 i = 0; i < shareholders[tokenId].length; i++) {
                if (shareholders[tokenId][i] == shareholder) {
                    shareholders[tokenId][i] = shareholders[tokenId][shareholders[tokenId].length - 1];
                    shareholders[tokenId].pop();
                    break;
                }
            }
        }
    }

    function isShareholder(uint256 tokenId, address shareholder) internal view returns (bool) {
        for (uint256 i = 0; i < shareholders[tokenId].length; i++) {
            if (shareholders[tokenId][i] == shareholder) {
                return true;
            }
        }
        return false;
    }

    function balanceOfShares(uint256 tokenId, address account) external view returns (uint256) {
        return tokenShares[tokenId][account];
    }

    function totalSharesOf(uint256 tokenId) external view returns (uint256) {
        return totalShares[tokenId];
    }

    function getShareholders(uint256 tokenId) external view returns (address[] memory) {
        return shareholders[tokenId];
    }
}
