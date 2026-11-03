const Web3 = require("web3");

const web3 = new Web3("http://127.0.0.1:8545");

async function main() {

    const accounts = await web3.eth.getAccounts();

    // Modified sender and receiver
    const sender = accounts[0];
    const receiver = accounts[2];

    // Modified amount
    const amount = web3.utils.toWei("2000", "ether");

    console.log("Modified Transaction");

    console.log("Sender:", sender);
    console.log("Receiver:", receiver);
    console.log("Amount: 2000 ETH");

    // Execute modified transaction
    const tx = await web3.eth.sendTransaction({

        from: sender,
        to: receiver,
        value: amount,
        gas: 21000

    });

    // Get receipt
    const receipt = await web3.eth.getTransactionReceipt(
        tx.transactionHash
    );

    console.log("\nModified Transaction Receipt");

    console.log("Transaction Hash:", receipt.transactionHash);
    console.log("Sender:", receipt.from);
    console.log("Receiver:", receipt.to);
    console.log("Block Number:", receipt.blockNumber);
    console.log("Status:", receipt.status);
    console.log("Gas Used:", receipt.gasUsed);

}

main().catch(error => {
    console.error("Transaction Failed:", error.message);
});