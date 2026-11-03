const { ethers } = require("ethers");

async function main() {

    const provider = new ethers.JsonRpcProvider(
        "http://127.0.0.1:8545"
    );

    const accounts = await provider.send(
        "eth_accounts", []
    );

    const wallet = await provider.getSigner(accounts[0]);

    // Execute transaction
    const tx = await wallet.sendTransaction({

        to: accounts[1],
        value: ethers.parseEther("0.5")

    });

    // Wait for transaction confirmation
    const receipt = await tx.wait();

    console.log("\n========== TRANSACTION RECEIPT ==========");

    console.log("Transaction Hash:", receipt.hash);
    console.log("Sender:", receipt.from);
    console.log("Receiver:", receipt.to);
    console.log("Block Number:", receipt.blockNumber);
    console.log("Status:", receipt.status);
    console.log("Gas Used:", receipt.gasUsed.toString());

    console.log("=========================================");

}

main().catch(console.error);