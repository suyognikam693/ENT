const { ethers } = require("ethers");

async function main() {

    const provider = new ethers.JsonRpcProvider(
        "http://127.0.0.1:8545"
    );

    const accounts = await provider.send(
        "eth_accounts", []
    );

    // Modified sender and receiver
    const wallet = await provider.getSigner(accounts[0]);

    const sender = accounts[0];
    const receiver = accounts[2];

    console.log("Modified Transaction");

    console.log("Sender:", sender);
    console.log("Receiver:", receiver);
    console.log("Amount: 2 ETH");

    // Execute modified transaction
    const tx = await wallet.sendTransaction({

        to: receiver,
        value: ethers.parseEther("2")

    });

    const receipt = await tx.wait();

    console.log("\nModified Transaction Receipt");

    console.log("Transaction Hash:", receipt.hash);
    console.log("Sender:", receipt.from);
    console.log("Receiver:", receipt.to);
    console.log("Block Number:", receipt.blockNumber);
    console.log("Status:", receipt.status);
    console.log("Gas Used:", receipt.gasUsed.toString());

}

main().catch(console.error);