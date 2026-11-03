const Web3 = require("web3");

const web3 = new Web3("http://127.0.0.1:8545");

async function main() {
    // Check RPC connection
    const connected = await web3.eth.net.isListening();

    console.log("Connected to Ganache:", connected);

    // Get network ID
    const networkId = await web3.eth.net.getId();
    console.log("Network ID:", networkId);

    // Get available accounts
    const accounts = await web3.eth.getAccounts();

    console.log("\nAvailable Accounts and Balances:");

    for (let i = 0; i < accounts.length; i++) {
        const balance = await web3.eth.getBalance(accounts[i]);

        console.log("\nAccount:", i);
        console.log("Address:", accounts[i]);
        console.log(
            "Balance:",
            web3.utils.fromWei(balance, "ether"),
            "ETH"
        );
    }
}

main().catch(error => {
    console.error("Error:", error.message);
});