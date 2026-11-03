const Web3 = require("web3");

const web3 = new Web3("http://127.0.0.1:8545");

async function main() {

    const accounts = await web3.eth.getAccounts();

    // Execute transaction
    const tx = await web3.eth.sendTransaction({

        from: accounts[0],
        to: accounts[1],
        value: web3.utils.toWei("0.5", "ether"),
        gas: 21000

    });

    // Obtain transaction receipt
    const receipt = await web3.eth.getTransactionReceipt(
        tx.transactionHash
    );

    console.log("\n========== TRANSACTION RECEIPT ==========");

    console.log("Transaction Hash:", receipt.transactionHash);

    console.log("Sender:", receipt.from);

    console.log("Receiver:", receipt.to);

    console.log("Block Number:", receipt.blockNumber);

    console.log("Transaction Status:", receipt.status);

    console.log("Gas Used:", receipt.gasUsed);

    console.log("=========================================");

}

main().catch(console.error);