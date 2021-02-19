// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./XStore.sol";
import "../library/token/ERC1155/IERC1155.sol";
import "../library/utils/Ownable.sol";
import "../library/utils/SafeMath.sol";
import "../library/token/ERC20/SafeERC20.sol";
import "../library/utils/EnumerableSet.sol";

contract XStoreVERC1155D1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct VaultERC1155D1 {
        address xTokenAddress;
        address nftAddress;
        address manager;
        IXToken xToken;
        IERC1155 nft;
        EnumerableSet.UintSet holdings;
        EnumerableSet.UintSet reserves;
        mapping(uint256 => address) requester;
        mapping(uint256 => bool) isEligible;
        mapping(uint256 => bool) shouldReserve;
        bool allowMintRequests;
        bool flipEligOnRedeem;
        bool negateEligibility;
        bool isFinalized;
        bool isClosed;
        uint256 tokenBalance;
    }

    VaultERC1155D1[] internal vaults;
    uint256 public randNonce;

    constructor() public {
        initOwnable();
    }

    event NewVaultAdded(uint256 vaultId);
    event XTokenAddressSet(uint256 indexed vaultId, address token);
    event NftAddressSet(uint256 indexed vaultId, address asset);
    event XTokenSet(uint256 indexed vaultId);
    event NftSet(uint256 indexed vaultId);
    event ManagerSet(uint256 indexed vaultId, address manager);
    event IsFinalizedSet(uint256 indexed vaultId, bool _isFinalized);
    event IsEligibleSet(uint256 indexed vaultId, uint256 id, bool _bool);
    event NegateEligibilitySet(uint256 indexed vaultId, bool _bool);
    //event ReservesAdded(uint256 indexed vaultId, uint256 id);
    event RandNonceSet(uint256 _randNonce);
    event HoldingsRemoved(uint256 indexed vaultId, uint256 id);



    function _getVault(uint256 vaultId) internal view returns (VaultERC1155D1 storage) {
        require(vaultId < vaults.length, "Invalid vaultId");
        return vaults[vaultId];
    }

    function vaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    function xTokenAddress(uint256 vaultId) public view returns (address) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.xTokenAddress;
    }

    function nftAddress(uint256 vaultId) public view returns (address) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.nftAddress;
    }

    function xToken(uint256 vaultId) public view returns (IXToken) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.xToken;
    }

    function manager(uint256 vaultId) public view returns (address) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.manager;
    }

    function nftERC1155D1(uint256 vaultId) external view returns (IERC1155) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.nft;
    }

    function setXTokenAddress(uint256 vaultId, address _xTokenAddress)
        public
        onlyOwner
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.xTokenAddress = _xTokenAddress;
        emit XTokenAddressSet(vaultId, _xTokenAddress);
    }

    function setNftAddress(uint256 vaultId, address _nft) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.nftAddress = _nft;
        emit NftAddressSet(vaultId, _nft);
    }

    function setManager(uint256 vaultId, address _manager) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.manager = _manager;
        emit ManagerSet(vaultId, _manager);
    }

    function setXToken(uint256 vaultId) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.xToken = IXToken(vault.xTokenAddress);
        emit XTokenSet(vaultId);
    }

    function setNft(uint256 vaultId) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.nft = IERC1155(vault.nftAddress);
        emit NftSet(vaultId);
    }   

    function addNewVault() public onlyOwner returns (uint256) {
        VaultERC1155D1 memory newVault;
        vaults.push(newVault);
        uint256 vaultId = vaults.length.sub(1);
        emit NewVaultAdded(vaultId);
        return vaultId;
    }

    function isFinalized(uint256 vaultId) public view returns (bool) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.isFinalized;
    }

    function setIsFinalized(uint256 vaultId, bool _isFinalized)
        public
        onlyOwner
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.isFinalized = _isFinalized;
        emit IsFinalizedSet(vaultId, _isFinalized);
    }

    function setIsEligible(uint256 vaultId, uint256 id, bool _bool)
        public
        onlyOwner
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.isEligible[id] = _bool;
        emit IsEligibleSet(vaultId, id, _bool);
    }

    function setNegateEligibility(uint256 vaultId, bool negateElig)
        public
        onlyOwner
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.negateEligibility = negateElig;
        emit NegateEligibilitySet(vaultId, negateElig);
    }

    function holdingsLength(uint256 vaultId) public view returns (uint256) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.holdings.length();
    }

    /*function reservesLength(uint256 vaultId) public view returns (uint256) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.holdings.length();
    }*/

    function isEligible(uint256 vaultId, uint256 id)
        public
        view
        returns (bool)
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.isEligible[id];
    }

    function negateEligibility(uint256 vaultId) public view returns (bool) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.negateEligibility;
    }

    /*function shouldReserve(uint256 vaultId, uint256 id)
        public
        view
        returns (bool)
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.shouldReserve[id];
    }*/

    /*function reservesAdd(uint256 vaultId, uint256 elem) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.reserves.add(elem);
        emit ReservesAdded(vaultId, elem);
    }*/

    function holdingsAdd(uint256 vaultId, uint256 elem) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.holdings.add(elem);
        //emit HoldingsAdded(vaultId, elem, amount);
    }

    function holdingsAt(uint256 vaultId, uint256 index)
        public
        view
        returns (uint256)
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.holdings.at(index);
    }

    function holdingsContains(uint256 vaultId, uint256 elem)
        public
        view
        returns (bool)
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.holdings.contains(elem);
    }

    /*function reservesAt(uint256 vaultId, uint256 index)
        public
        view
        returns (uint256)
    {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.holdings.at(index);
    }*/

    function setRandNonce(uint256 _randNonce) public onlyOwner {
        randNonce = _randNonce;
        emit RandNonceSet(_randNonce);
    }

    function flipEligOnRedeem(uint256 vaultId) public view returns (bool) {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        return vault.flipEligOnRedeem;
    }

    function holdingsRemove(uint256 vaultId, uint256 elem) public onlyOwner {
        VaultERC1155D1 storage vault = _getVault(vaultId);
        vault.holdings.remove(elem);
        emit HoldingsRemoved(vaultId, elem);
    }
}
