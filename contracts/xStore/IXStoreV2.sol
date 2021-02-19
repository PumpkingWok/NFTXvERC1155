// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./IXStore.sol";
import "../library/token/ERC1155/IERC1155.sol";

interface IXStoreV2 is IXStore {

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
        FeeParams mintFees;
        FeeParams burnFees;
        FeeParams dualFees;
        BountyParams supplierBounty;
        uint256 ethBalance;
        uint256 tokenBalance;
    }

    function nftERC1155D1(uint256 vaultId) external view returns (IERC1155);
}