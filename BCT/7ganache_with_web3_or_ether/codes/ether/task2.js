const { ethers } = require("ethers");

async function main() {

    const provider = new ethers.JsonRpcProvider(
        "http://127.0.0.1:8545"
    );

    // Get Ganache accounts
    const accounts = await provider.send(
        "eth_accounts", []
    );

    const sender = accounts[0];
    const receiver = accounts[1];

    // Connect sender wallet
    const wallet = await provider.getSigner(sender);

    console.log("Sender:", sender);
    console.log("Receiver:", receiver);

    // Transfer 1 ETH
    const tx = await wallet.sendTransaction({

        to: receiver,
        value: ethers.parseEther("1")

    });

    console.log("\nTransaction submitted!");
    console.log("Transaction Hash:", tx.hash);

    // Wait for confirmation
    const receipt = await tx.wait();

    console.log("Block Number:", receipt.blockNumber);
    console.log("Gas Used:", receipt.gasUsed.toString());

}

main().catch(console.error);