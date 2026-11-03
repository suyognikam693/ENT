const { ethers } = require("ethers");

async function main() {

    // Connect to Ganache
    const provider = new ethers.JsonRpcProvider(
        "http://127.0.0.1:8545"
    );

    console.log("Connected to Ganache");

    // Get network information
    const network = await provider.getNetwork();
    console.log("Network ID:", network.chainId.toString());

    // Get accounts
    const accounts = await provider.send(
        "eth_accounts", []
    );

    console.log("\nAvailable Accounts and Balances:");

    for (let i = 0; i < accounts.length; i++) {

        const balance = await provider.getBalance(accounts[i]);

        console.log("\nAccount:", i);
        console.log("Address:", accounts[i]);
        console.log(
            "Balance:",
            ethers.formatEther(balance),
            "ETH"
        );
    }
}

main().catch(console.error);