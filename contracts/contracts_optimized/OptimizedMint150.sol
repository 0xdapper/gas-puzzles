//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import 'hardhat/console.sol';

// You may not modify this contract or the openzeppelin contracts
contract NotRareToken is ERC721 {
    mapping(address => bool) private alreadyMinted;

    uint256 private totalSupply;

    constructor() ERC721('NotRareToken', 'NRT') {}

    function mint() external {
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        alreadyMinted[msg.sender] = true;
    }
}

contract OptimizedAttacker {
    constructor(address victim) payable {
        uint256 ownerOfData;
        uint256 mintData;
        uint256 transferFromData;

        assembly {
            ownerOfData := mload(0x40)
            mstore(ownerOfData, hex'6352211e')

            mintData := add(ownerOfData, 0x24)
            mstore(mintData, hex'1249c58b')

            transferFromData := add(mintData, 0x04)
            mstore(transferFromData, hex'23b872dd')
            mstore(add(transferFromData, 0x04), address())
            mstore(add(transferFromData, 0x24), caller())

            // figure out the start token id
            let i := 1

            for {

            } lt(i, 6) {
                i := add(i, 1)
            } {
                mstore(add(ownerOfData, 0x04), i)
                let success := staticcall(
                    gas(),
                    victim,
                    ownerOfData,
                    0x24,
                    0x00,
                    0x00
                )
                if iszero(success) {
                    // revert(0x00, 0x00)
                    break
                }
            }

            let lower := i
            let upper := add(lower, 150)

            // mint one token
            let success := call(gas(), victim, 0, mintData, 0x04, 0x00, 0x00)
            // if iszero(success) {
            //     revert(0x00, 0x00)
            // }

            let transferFromDataTokenId := add(transferFromData, 0x44)

            // mint and send 149 tokens
            for {
                i := add(lower, 1)
            } lt(i, upper) {
                i := add(i, 1)
            } {
                success := call(gas(), victim, 0, mintData, 0x04, 0x00, 0x00)
                // if iszero(success) {
                //     revert(0x00, 0x00)
                // }

                mstore(transferFromDataTokenId, i)
                success := call(
                    gas(),
                    victim,
                    0,
                    transferFromData,
                    0x100,
                    0x00,
                    0x00
                )
                // if iszero(success) {
                //     revert(0x00, 0x00)
                // }
            }

            // send first token
            mstore(transferFromDataTokenId, lower)
            success := call(
                gas(),
                victim,
                0,
                transferFromData,
                0x100,
                0x00,
                0x00
            )
            // if iszero(success) {
            //     revert(0x00, 0x00)
            // }
        }
    }
}

// import {Test} from 'forge-std/Test.sol';

// contract OptimizedMintTest is Test {
//     uint256 target = 5329781;

//     function test() external {
//         NotRareToken token = new NotRareToken();
//         token.mint();
//         token.mint();
//         uint256 before = gasleft();
//         new OptimizedAttacker(address(token));
//         uint256 _after = gasleft();
//         uint256 used = before - _after;
//         emit log_uint(used);
//         if (used > target) emit log_uint(used - target);
//     }

//     function onERC721Received(
//         address _operator,
//         address _from,
//         uint256 _tokenId,
//         bytes calldata _data
//     ) external returns (bytes4) {
//         return
//             bytes4(
//                 keccak256('onERC721Received(address,address,uint256,bytes)')
//             );
//     }
// }
