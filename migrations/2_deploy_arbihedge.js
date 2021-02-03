const ArbiHedge = artifacts.require("ArbiHedge.sol");

module.exports = function (deployer) {
    deployer.deploy(ArbiHedge, ["0xeb0eC7a28E4B6B175806E21D9D3afE45792C5c7B"]);
};
