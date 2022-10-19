from brownie import CSAMM, MobiCoin, NinaCoin, interface, accounts, web3
import pytest


def test_deploy_tokens():
    zero_address = "0x0000000000000000000000000000000000000000"
    deployer = accounts[0]
    user = accounts[1]
    user1 = accounts[2]
    user2 = accounts[3]
    user3 = accounts[4]
    Lp2 = accounts[5]

    get_thousand = web3.toWei(1000, "ether")
    get_hundred = web3.toWei(100, "ether")
    get_fifty = web3.toWei(50, "ether")
    mobi_coin = MobiCoin.deploy(get_thousand, {"from": deployer})
    nina_coin = NinaCoin.deploy(get_thousand, {"from": deployer})

    mobi_coin_interface = interface.IERC20(mobi_coin.address)
    nina_coin_interface = interface.IERC20(nina_coin.address)

    mobi_coin_interface.mintMore(get_thousand, {"from": user})
    nina_coin_interface.mintMore(get_thousand, {"from": user})

    mobi_coin_interface.mintMore(get_hundred, {"from": user1})
    nina_coin_interface.mintMore(get_hundred, {"from": user1})

    mobi_coin_interface.mintMore(get_hundred, {"from": user2})
    nina_coin_interface.mintMore(get_hundred, {"from": user2})

    mobi_coin_interface.mintMore(get_fifty, {"from": user3})
    nina_coin_interface.mintMore(get_fifty, {"from": user3})

    mobi_coin_interface.mintMore(get_fifty, {"from": Lp2})
    nina_coin_interface.mintMore(get_fifty, {"from": Lp2})

    print(
        f"Deployer Token balance is: {web3.fromWei(mobi_coin.balanceOf(deployer.address), 'ether')} {mobi_coin.symbol()}, {web3.fromWei(nina_coin.balanceOf(deployer.address), 'ether')} {nina_coin.symbol()} "
    )

    print(
        "User Token balance is: ",
        web3.fromWei(mobi_coin_interface.balanceOf(user.address), "ether"),
        mobi_coin_interface.symbol(),
        ",",
        web3.fromWei(nina_coin_interface.balanceOf(user.address), "ether"),
        nina_coin_interface.symbol(),
    )

    return (
        deployer,
        user,
        mobi_coin,
        nina_coin,
        get_thousand,
        get_hundred,
        get_fifty,
        zero_address,
        user1,
        user2,
        user3,
        Lp2,
    )


def test_csamm():
    (
        deployer,
        user,
        mobi_coin,
        nina_coin,
        get_thousand,
        get_hundred,
        get_fifty,
        zero_address,
        user1,
        user2,
        user3,
        Lp2,
    ) = test_deploy_tokens()

    csamm_contract = CSAMM.deploy(
        mobi_coin.address, nina_coin.address, {"from": deployer}
    )
    assert csamm_contract.reserve0() == 0
    assert csamm_contract.reserve1() == 0
    assert csamm_contract.TotalSupply() == 0

    print("State variables are okay!")
    print("Adding Liquidity!!")
    tx1 = mobi_coin.approve(csamm_contract.address, get_thousand, {"from": deployer})
    tx2 = nina_coin.approve(csamm_contract.address, get_thousand, {"from": deployer})

    tx1a = mobi_coin.approve(csamm_contract.address, get_hundred, {"from": user})
    tx2a = nina_coin.approve(csamm_contract.address, get_hundred, {"from": user})

    mobi_coin.approve(csamm_contract.address, get_hundred, {"from": user1})
    nina_coin.approve(csamm_contract.address, get_hundred, {"from": user1})

    mobi_coin.approve(csamm_contract.address, get_hundred, {"from": user2})
    nina_coin.approve(csamm_contract.address, get_hundred, {"from": user2})

    mobi_coin.approve(csamm_contract.address, get_fifty, {"from": user3})
    nina_coin.approve(csamm_contract.address, get_fifty, {"from": user3})

    mobi_coin.approve(csamm_contract.address, get_fifty, {"from": Lp2})
    nina_coin.approve(csamm_contract.address, get_fifty, {"from": Lp2})
    # tx1.info()

    # tx2.info()
    print("Approve success for deployer!")
    tx3 = csamm_contract.addLiquidity(get_thousand, get_thousand, {"from": deployer})
    lp2tx = csamm_contract.addLiquidity(get_fifty, get_fifty, {"from": Lp2})
    print("Logging add liquidity events...")
    print(tx3.events["AddLiquidity"])
    print(lp2tx.events["AddLiquidity"])
    print(tx3.events["Mint"])

    print("logging reserves")
    print(f"The pool reserve balances are : {csamm_contract.getReserves()}")
    print(f"The total supply of shares = {csamm_contract.TotalSupply()}")
    shares_deployer = csamm_contract.balanceOf(deployer.address)
    shares_lp2 = csamm_contract.balanceOf(Lp2.address)
    print(f"The deployer/ LP1 total shares is = {shares_deployer} ")
    print(f"The LP2 total shares is = {shares_lp2} ")

    # tx3.info()
    # print(web3.fromWei(csamm_contract.balanceOf(deployer.address), "ether"))

    tx4 = csamm_contract.swap(mobi_coin.address, get_hundred, {"from": user})
    csamm_contract.swap(mobi_coin.address, get_hundred, {"from": user1})
    csamm_contract.swap(nina_coin.address, get_hundred, {"from": user2})
    txninacoin = csamm_contract.swap(nina_coin.address, get_fifty, {"from": user3})
    print("tx's complete!")
    tx4.info()
    txninacoin.info()

    print("logging reserves")
    print(f"The pool reserve balances are : {csamm_contract.getReserves()}")

    tx5 = csamm_contract.removeLiquidity(shares_deployer, {"from": deployer})
    tx5.info()
    print("logging reserves")
    print(f"The pool reserve balances are : {csamm_contract.getReserves()}")

    csamm_contract.removeLiquidity(shares_lp2, {"from": Lp2})
    print("logging reserves")
    print(f"The pool reserve balances are : {csamm_contract.getReserves()}")
