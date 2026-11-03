const Web3 = require("web3");

const web3 = new Web3("http://127.0.0.1:8545");

async function main() {

    const accounts = await web3.eth.getAccounts();

    const sender = accounts[0];
    const receiver = accounts[1];

    console.log("Sender:", sender);
    console.log("Receiver:", receiver);

    // Transaction amount: 1 ETH
    const amount = web3.utils.toWei("1", "ether");

    // Execute transaction
    const tx = await web3.eth.sendTransaction({

        from: sender,
        to: receiver,
        value: amount,
        gas: 21000

    });

    console.log("\nTransaction Successful!");
    console.log("Transaction Hash:", tx.transactionHash);
    console.log("Block Number:", tx.blockNumber);
    console.log("Gas Used:", tx.gasUsed);

}

main().catch(error => {
    console.error("Transaction Failed:", error.message);
});