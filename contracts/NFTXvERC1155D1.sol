// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./library/utils/Pausable.sol";
import "./xToken/IXToken.sol";
import "./library/token/ERC1155/IERC1155.sol";
import "./library/utils/ReentrancyGuard.sol";
import "./library/token/ERC1155/ERC1155Holder.sol";
import "./xStore/IXStoreV2.sol";
import "./library/token/ERC20/SafeERC20.sol";

contract NFTXvERC1155D1 is Pausable, ReentrancyGuard, ERC1155Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewVault(uint256 indexed vaultId, address sender);
    event Redeem(uint256 indexed vaultId, uint256[] nftIds, uint256[] amounts, address sender);
    event Mint(uint256 vaultId, uint256[] nftIds, uint256[] amounts, address sender);
    event HoldingsAdded(uint256 vaultId, uint256 elem, uint256 amount);

    IXStoreV2 public store;

    constructor(address storeAddress) public {
        initOwnable();
        initReentrancyGuard();
        store = IXStoreV2(storeAddress);
    }

    function onlyPrivileged(uint256 vaultId) internal view {
        if (store.isFinalized(vaultId)) {
            require(msg.sender == owner(), "Not owner");
        } else {
            require(msg.sender == store.manager(vaultId), "Not manager");
        }
    }

    function isEligible(uint256 vaultId, uint256 nftId)
        public
        view
        virtual
        returns (bool)
    {
        return
            store.negateEligibility(vaultId)
                ? !store.isEligible(vaultId, nftId)
                : store.isEligible(vaultId, nftId);
    }

    function vaultSize(uint256 vaultId) public view virtual returns (uint256) {
        return
            store.holdingsLength(vaultId).add(store.reservesLength(vaultId));
    }

    function _getPseudoRand(uint256 modulus)
        internal
        virtual
        returns (uint256)
    {
        store.setRandNonce(store.randNonce().add(1));
        return
            uint256(
                keccak256(abi.encodePacked(now, msg.sender, store.randNonce()))
            ) %
            modulus;
    }

    function createVault(
        address _xTokenAddress,
        address _assetAddress
    ) public virtual nonReentrant returns (uint256) {
        onlyOwnerIfPaused(0);
        IXToken xToken = IXToken(_xTokenAddress);
        require(xToken.owner() == address(this), "Wrong owner");
        uint256 vaultId = store.addNewVault();
        store.setXTokenAddress(vaultId, _xTokenAddress);

        store.setXToken(vaultId);
        store.setNftAddress(vaultId, _assetAddress);
        store.setNft(vaultId);
        store.setManager(vaultId, msg.sender);
        emit NewVault(vaultId, msg.sender);
        return vaultId;
    }

    function _mint(uint256 vaultId, uint256[] memory nftIds, uint256[] memory amounts)
        internal
        virtual
        returns(uint256)
    {
        uint256 totalAmount;
        uint256[] memory nftStoreBalances = new uint256[](nftIds.length);
        for (uint256 i = 0; i < nftIds.length; i++) {
            require(isEligible(vaultId, nftIds[i]), "Not eligible");
            nftStoreBalances[i] = store.nftERC1155D1(vaultId).balanceOf(address(this), nftIds[i]);
        }
        store.nftERC1155D1(vaultId).safeBatchTransferFrom(msg.sender, address(this), nftIds, amounts, '');
        for (uint256 i = 0; i < nftIds.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
            uint256 nftId = nftIds[i];
            require(
                store.nftERC1155D1(vaultId).balanceOf(address(this), nftIds[i]) == nftStoreBalances[i].add(amounts[i]),
                "Not received the correct amount"
            );
            if (!store.holdingsContains(vaultId, nftId)) {
                store.holdingsAdd(vaultId, nftId); 
            }           
            emit HoldingsAdded(vaultId, nftId, amounts[i]);
        }
        return totalAmount;
    }

    function _redeem(uint256 vaultId, uint256 numNFTs)
        internal
        virtual
    {
        for (uint256 i = 0; i < numNFTs; i++) {
            uint256[] memory nftIds = new uint256[](1);
            require(store.holdingsLength(vaultId) > 0);
            uint256 rand = _getPseudoRand(store.holdingsLength(vaultId));
            nftIds[0] = store.holdingsAt(vaultId, rand);
            _redeemHelper(vaultId, nftIds);
            uint256[] memory test;
            emit Redeem(vaultId, nftIds, test, msg.sender);
        }
    }

    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds
    ) internal virtual {
        store.xToken(vaultId).burnFrom(
            msg.sender,
            nftIds.length.mul(10**18)
        );
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(store.holdingsContains(vaultId, nftId), "NFT not in vault");
            if (store.flipEligOnRedeem(vaultId)) {
                bool isElig = store.isEligible(vaultId, nftId);
                store.setIsEligible(vaultId, nftId, !isElig);
            }
            store.nftERC1155D1(vaultId).safeTransferFrom(
                address(this),
                msg.sender,
                nftId,
                1,
                ''
            );
            if (store.nftERC1155D1(vaultId).balanceOf(address(this), nftId) == 0) {
                store.holdingsRemove(vaultId, nftId);
            }
        }
    }

    function mint(uint256 vaultId, uint256[] memory nftIds, uint256[] memory amounts) public payable virtual nonReentrant {
        onlyOwnerIfPaused(1);
        require(nftIds.length == amounts.length, "Different length");
        uint256 total = _mint(vaultId, nftIds, amounts);
        store.xToken(vaultId).mint(msg.sender, total.mul(10**18));
        emit Mint(vaultId, nftIds, amounts, msg.sender);
    }

    function _getTotalNFTAmount(uint256[] memory amounts) internal pure returns(uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < amounts.length; i.add(1)) {
            totalAmount = totalAmount.add(amounts[i]);
        }
        return totalAmount;
    }

    function redeem(uint256 vaultId, uint256 amount)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(2);
        _redeem(vaultId, amount);
    }

    function setIsEligible(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            store.setIsEligible(vaultId, nftIds[i], _boolean);
        }
    }

    function setNegateEligibility(uint256 vaultId, bool shouldNegate)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        require(
            store
                .holdingsLength(vaultId) ==
                0,
            "Vault not empty"
        );
        store.setNegateEligibility(vaultId, shouldNegate);
    }

    function finalizeVault(uint256 vaultId) public virtual {
        onlyPrivileged(vaultId);
        if (!store.isFinalized(vaultId)) {
            store.setIsFinalized(vaultId, true);
        }
    }
}
