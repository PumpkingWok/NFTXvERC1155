const { deployProxy } = require('@openzeppelin/truffle-upgrades') 
const { default: BigNumber } = require('bignumber.js')
const XSTORE = artifacts.require("XStore")
const XSTOREVERC1155D1 = artifacts.require("XSTOREvERC1155D1")
const NFTXV5 = artifacts.require("NFTXv5")
const NFTXVERC1155D1 = artifacts.require("NFTXvERC1155D1")
const XTOKEN = artifacts.require("XToken")
const ERC721 = artifacts.require("ERC721")
const ERC1155 = artifacts.require("ERC1155")


contract('XSTORE Deploy', (accounts) => {
    const owner = accounts[0]
    const alice = accounts[1]
    const bob = accounts[2]

    it('Test NFTXv5', async() => {
        const xStore = await XSTORE.new({from: owner})
        assert(xStore.addres !=  '')

        const nftxV5 = await deployProxy(NFTXV5, [xStore.address], {
            initializer: "initialize"
        })
        assert(nftxV5.addres !=  '')

        await xStore.transferOwnership(nftxV5.address)

        const xToken = await XTOKEN.new("Xtoken", "XTOKEN", nftxV5.address, {from: owner})
        assert(xToken.addres !=  '')

        const nft = await ERC721.new("nft.test", "NFT", {from: owner})
        assert(nft.address != '')

        await nft.safeMint(alice, 0, {from: owner})
        await nft.safeMint(alice, 1, {from: owner})
        await nft.safeMint(alice, 2, {from: owner})

        await nft.safeMint(bob, 3, {from: owner})
        await nft.safeMint(bob, 4, {from: owner})
        await nft.safeMint(bob, 5, {from: owner})


        await nftxV5.createVault(xToken.address, nft.address, false, {from: owner})

        await nftxV5.finalizeVault(0, {from: owner})

        await nftxV5.setNegateEligibility(0, false, {from: owner})
        await nftxV5.setIsEligible(0, [0, 1, 2, 3, 4, 5], true, {from: owner})

        await nft.setApprovalForAll(nftxV5.address, true, {from: alice})
        await nft.setApprovalForAll(nftxV5.address, true, {from: bob})

        await nftxV5.mint(0, [0, 1, 2], 0, {from: alice})
        await nftxV5.mint(0, [3, 4, 5], 0, {from: bob})

        await xToken.approve(nftxV5.address, BigNumber(10000000000000000000), {from: alice})
        await xToken.approve(nftxV5.address, BigNumber(10000000000000000000), {from: bob})

        await nftxV5.redeem(0, 3, {from: alice})
        await nftxV5.redeem(0, 3, {from: bob})

        for (let i = 0; i < 6; i++) {
            console.log("Owner Of tokenId#" + i + " -> " + await nft.ownerOf(i))  
        }
    })

    it('Test NFTXvERC1155', async() => {
        const xStoreVERC1155D1 = await XSTOREVERC1155D1.new({from: owner})
        assert(xStoreVERC1155D1.addres !=  '')

        const nftxVERC1155D1 = await NFTXVERC1155D1.new(xStoreVERC1155D1.address, {from: owner})
        assert(nftxVERC1155D1.addres !=  '')

        await xStoreVERC1155D1.transferOwnership(nftxVERC1155D1.address, {from: owner})

        const xToken = await XTOKEN.new("Xtoken", "XTOKEN", nftxVERC1155D1.address, {from: owner})
        assert(xToken.addres !=  '')

        const nft = await ERC1155.new("nft.uri", {from: owner})
        assert(nft.address != '')

        await nft.mint(alice, 0, 1, [], {from: owner})
        await nft.mint(alice, 1, 2, [], {from: owner})

        await nft.mint(bob, 2, 3, [], {from: owner})

        await nftxVERC1155D1.createVault(xToken.address, nft.address, {from: owner})

        await nftxVERC1155D1.finalizeVault(0, {from: owner})

        await nftxVERC1155D1.setNegateEligibility(0, false, {from: owner})
        await nftxVERC1155D1.setIsEligible(0, [0, 1, 2], true, {from: owner})

        await nft.setApprovalForAll(nftxVERC1155D1.address, true, {from: alice})
        await nft.setApprovalForAll(nftxVERC1155D1.address, true, {from: bob})

        await nftxVERC1155D1.mint(0, [0, 1], [1, 2], {from: alice})
        await nftxVERC1155D1.mint(0, [2], [3], {from: bob})

        await xToken.approve(nftxVERC1155D1.address, BigNumber(10000000000000000000), {from: alice})
        await xToken.approve(nftxVERC1155D1.address, BigNumber(10000000000000000000), {from: bob})

        await nftxVERC1155D1.redeem(0, 3, {from: alice})
        await nftxVERC1155D1.redeem(0, 3, {from: bob})

        for (let i = 0; i < 3; i++) {
            console.log("Alice -> balance of tokenId#" + i + " -> " + await nft.balanceOf(alice, i))
            console.log("Bob -> balance of tokenId#" + i + " -> " + await nft.balanceOf(bob, i))  
        }
    })
})