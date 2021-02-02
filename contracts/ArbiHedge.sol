// contracts/ArbiHedge.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ISwappable {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable
    returns (uint[] memory amounts);
}
contract ArbiHedge is ERC20 {

    using SafeMath for uint256;

    mapping(ISwappable => bool) whitelisted;
    uint256 public visibility = 1000000;

    constructor(ISwappable[] memory whitelist) ERC20("ArbiHedge ETH", "ARB") {
        for (uint i=0; i<whitelist.length; i++) {
            whitelisted[whitelist[i]] = true;
        }
    }

    function deposit() payable public {
        require(msg.value > 0, "Amount to deposit must be > 0.");
        uint256 actualValue = address(this).balance - msg.value;
        uint256 percentage = (totalSupply() * visibility) / actualValue;
        uint256 amountToMint = (msg.value * percentage) / visibility;
        require(amountToMint > 0, "Amount to mint must be > 0.");
        _mint(msg.sender, amountToMint);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "You don't own that much to withdraw.");
        uint256 percentage = (totalSupply() * visibility) / amount;
        uint256 amountToBurn = (amount * percentage) / visibility;
        require(amountToBurn > 0, "Amount to send must be greater than 0.");
        _burn(msg.sender, amount);
        this.transfer(msg.sender, amountToBurn);
    }

    function executeUniSwap(ISwappable swapAddress, uint256 amountOutMin, address[] calldata path, uint256 deadline) public returns (uint[] memory amounts) {
        require(whitelisted[swapAddress], "Address for swapping must be whitelisted.");
        uint256 before = address(this).balance;
        uint[] memory outs = swapAddress.swapExactETHForTokens(amountOutMin, path, address(this), deadline);
        require(address(this).balance > before, "ROI was not achieved.");
        return outs;
    }
}