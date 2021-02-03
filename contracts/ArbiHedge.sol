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

    event Invest(address investor, uint256 amount, uint256 amountIssued);
    event Withdraw(address withdrawer, uint256 amount, uint256 amountSent);
    event Swap(address swapper, address swapaddress, int[] result);

    mapping(ISwappable => bool) whitelisted;
    uint256 public visibility = 1000000;

    constructor(ISwappable[] memory whitelist) ERC20("ArbiHedge ETH", "ARB") {
        for (uint i=0; i<whitelist.length; i++) {
            whitelisted[whitelist[i]] = true;
        }
    }

    function deposit() payable public {
        require(msg.value > 0, "Amount to deposit must be > 0.");
        uint256 actualValue = address(this).balance.sub(msg.value);
        uint256 percentage = totalSupply().mul(visibility).div(actualValue);
        uint256 amountToMint = msg.value.mul(percentage).div(visibility);
        require(amountToMint > 0, "Amount to mint must be > 0.");
        _mint(msg.sender, amountToMint);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "You don't own that much to withdraw.");
        uint256 percentage = totalSupply().mul(visibility).div(amount);
        uint256 amountToSend = amount.mul(percentage).div(visibility);
        require(amountToSend > 0, "Amount to send must be greater than 0.");
        _burn(msg.sender, amount);
        this.transfer(msg.sender, amountToSend);
    }

    function executeUniSwap(ISwappable swapAddress, uint256 amountOutMin, address[] calldata path, uint256 deadline) public returns (uint[] memory amounts) {
        require(whitelisted[swapAddress], "Address for swapping must be whitelisted.");
        uint256 before = address(this).balance;
        uint[] memory outs = swapAddress.swapExactETHForTokens(amountOutMin, path, address(this), deadline);
        require(address(this).balance > before, "ROI was not achieved.");
        uint256 amountToSend = address(this).balance.sub(before);
        this.transfer(msg.sender, amountToSend);
        return outs;
    }
}