const SmartWallet = artifacts.require("SmartWallet");

contract("SmartWallet", accounts => {
    let smartWallet;

    beforeEach(async () => {
        smartWallet = await SmartWallet.new();
    });

    it("should allow deposits", async () => {
        const depositAmount = web3.utils.toWei("1", "ether");
        await smartWallet.deposit({ value: depositAmount });
        const balance = await smartWallet.getBalance();
        assert.equal(balance.toString(), depositAmount, "Balance should be equal to the deposited amount");
    });

    it("should allow withdrawals", async () => {
        const depositAmount = web3.utils.toWei("1", "ether");
        await smartWallet.deposit({ value: depositAmount });
        await smartWallet.withdraw(depositAmount);
        const balance = await smartWallet.getBalance();
        assert.equal(balance.toString(), "0", "Balance should be zero after withdrawal");
    });

    it("should return the correct balance", async () => {
        const depositAmount = web3.utils.toWei("1", "ether");
        await smartWallet.deposit({ value: depositAmount });
        const balance = await smartWallet.getBalance();
        assert.equal(balance.toString(), depositAmount, "Balance should be equal to the deposited amount");
    });
});