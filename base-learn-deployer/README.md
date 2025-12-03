# Base Learn Contract Deployer

This tool automates the compilation and deployment of the smart contracts for the Base Learn program.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd base-learn-deployer
    ```

2.  **Install the dependencies:**
    ```bash
    npm install
    ```

3.  **Create a `.env` file:**
    -   Copy the `.env.example` file to a new file named `.env`.
    -   Open the `.env` file and add your wallet's private key.
    ```
    PRIVATE_KEY=YOUR_PRIVATE_KEY
    BASESCAN_API_KEY= # This is no longer used by the script
    ```

## Usage

1.  **Compile the contracts:**
    ```bash
    node scripts/compile.js
    ```

2.  **Run the deployment script:**
    -   To deploy a contract, run the script with the contract's name as an argument. For example:
        ```bash
        node scripts/deploy.js BasicMath
        ```
    -   If you run the script without an argument, it will display a list of all the available contracts to deploy.

3.  **Deployment:**
    -   The script will deploy the selected contract to the Base Sepolia testnet and print its address.
    -   You can then take this address and verify it manually on BaseScan.
