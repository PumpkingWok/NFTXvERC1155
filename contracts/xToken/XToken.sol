// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "../library/utils/Ownable.sol";
import "../library/utils/Context.sol";
import "../library/token/ERC20/ERC20.sol";
import "../library/token/ERC20/ERC20Burnable.sol";

contract XToken is Context, Ownable, ERC20Burnable {
    constructor(string memory name, string memory symbol, address _owner)
        public
        ERC20(name, symbol)
    {
        initOwnable();
        transferOwnership(_owner);
        _mint(msg.sender, 0);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function changeName(string memory name) public onlyOwner {
        _changeName(name);
    }

    function changeSymbol(string memory symbol) public onlyOwner {
        _changeSymbol(symbol);
    }
}
