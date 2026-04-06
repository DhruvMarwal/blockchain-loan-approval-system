# ⛓ CrediChain — Decentralized P2P Lending Protocol

A fully decentralized peer-to-peer lending platform built on Ethereum. No banks, no middlemen — just smart contracts, MetaMask, and trustless code.

---

## 🧠 Concept

Traditional lending requires a bank as a middleman. CrediChain eliminates this by running all loan logic directly on a blockchain smart contract. Lenders and borrowers interact directly, with collateral, penalties, and repayments handled automatically by code.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏦 Loan Marketplace | Lenders compete by bidding interest rates — borrower picks the best deal |
| 🔒 Collateral System | Borrower locks ETH in the contract — auto-seized on default |
| 📊 On-Chain Credit Score | Dynamic score (300–900) based on repayment history, modeled after CIBIL |
| ⏰ Late Penalty Engine | Automatic penalty calculated per day overdue using block timestamps |
| 🌐 Pure Web3 Frontend | No backend server — MetaMask signs every transaction directly |

---

## 🏗 Tech Stack

| Layer | Technology |
|---|---|
| Smart Contract | Solidity 0.8.0 |
| Local Blockchain | Hardhat Node |
| Deployment | Hardhat Scripts |
| Testing | Hardhat + Mocha + Chai |
| Frontend | HTML + CSS + Ethers.js v5 |
| Wallet | MetaMask |

---

## 📁 Project Structure

```
credichain/
├── contracts/
│   └── P2PLending.sol        # Main smart contract
├── scripts/
│   └── deploy.js             # Deployment script
├── test/
│   └── P2PLending.test.js    # Contract tests
├── frontend/
│   └── index_web3.html       # Web3 frontend (no backend needed)
├── hardhat.config.js         # Hardhat configuration
└── package.json              # Project dependencies
```

---

## ⚙️ Setup & Run

### 1. Clone the repo
```bash
git clone https://github.com/DhruvMarwal/blockchain-loan-approval-system.git
cd blockchain-loan-approval-system
```

### 2. Install dependencies
```bash
npm install
```

### 3. Start local blockchain
```bash
npx hardhat node
```
Keep this terminal open. You'll see 20 test accounts each with 10,000 ETH.

### 4. Deploy the contract (new terminal)
```bash
npx hardhat run scripts/deploy.js --network localhost
```
Copy the deployed contract address from the output.

### 5. Update contract address in frontend
Open `frontend/index_web3.html` and update:
```javascript
const CONTRACT_ADDRESS = "your_deployed_address_here";
```

### 6. Serve the frontend
```bash
npx serve .
```
Open `http://localhost:3000/frontend/index_web3.html` in your browser.

### 7. Connect MetaMask
- Add network: `http://127.0.0.1:8545` | Chain ID: `31337`
- Import a test account using private key from step 3
- Click "Connect MetaMask" in the app

---

## 🔄 How It Works

```
1. Borrower locks ETH collateral → requests loan
2. Lenders compete → each submits an offer with their interest rate
3. Borrower accepts the best offer → ETH sent to borrower instantly
4. Borrower repays → collateral returned, lender gets principal + interest
5. Default → collateral auto-seized and sent to lender
6. Credit score updated on-chain after every loan
```

---

## 🧪 Run Tests

```bash
npx hardhat test
```

Expected output:
```
P2PLending
  ✔ Borrower can request a loan
  ✔ Lender can fund a loan
  ✔ Borrower can repay a loan

3 passing
```

---

## 📊 Credit Score Formula

Score range: **300 (Poor) → 900 (Excellent)**

```
score = 300
      + (onTimeLoans/totalLoans × 400)    # repayment ratio
      + (min(totalLoans, 10) × 10)        # history length bonus
      + (min(totalBorrowed/10ETH, 1)×100) # loan size bonus
      - (defaultedLoans × 50)             # default penalty

Clamped between 300 and 900
```

---

## ⚠️ Important Notes

- This project runs on a **local Hardhat blockchain** — no real money involved
- Test account private keys in this repo are **public Hardhat defaults** — never use them on mainnet
- Contract is not audited — for educational/portfolio purposes only

---

## 👤 Authors

- GitHub: [Dhruv Marwal](https://github.com/DhruvMarwal) , [Priyanshu Jha](https://github.com/Priyanshu0423) , [Shivang Jain](https://github.com/Xopse)
- LinkedIn: [Dhruv Marwal](https://linkedin.com/in/dhruvmarwal) , [Priyanshu Jha](https://linkedin.com/in/priyanshujha-) , [Shivang Jain](https://linkedin.com/in/shivang-jain-69602132a)
---

## 📄 License

MIT
