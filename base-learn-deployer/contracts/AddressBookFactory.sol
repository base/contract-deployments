// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AddressBook.sol";

contract AddressBookFactory {
    string private salt = "value";

    function deploy() external returns (AddressBook) {
        // deploy AddressBook, owner = msg.sender
        AddressBook newAddressBook = new AddressBook(msg.sender);
        return newAddressBook;
    }
}
