const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("P2PLending", function () {
  let contract, owner, borrower, lender;

  beforeEach(async function () {
    // get fake wallets from Hardhat
    [owner, borrower, lender] = await ethers.getSigners();

    // deploy fresh contract before each test
    const P2PLending = await ethers.getContractFactory("P2PLending");
    contract = await P2PLending.deploy();
  });

  it("Borrower can request a loan", async function () {
    const amount = ethers.parseEther("1.0"); // 1 ETH

    await contract.connect(borrower).requestLoan(
      amount, 10, 30, "Need money for business"
    );

    const loan = await contract.getLoan(1);
    console.log("Loan created by:", loan.borrower);
    console.log("Amount:", ethers.formatEther(loan.amount), "ETH");
    console.log("Interest:", loan.interestRate.toString(), "%");
    console.log("Status:", loan.status.toString(), "(0 = PENDING)");

    expect(loan.borrower).to.equal(borrower.address);
    expect(loan.amount).to.equal(amount);
  });

  it("Lender can fund a loan", async function () {
    const amount = ethers.parseEther("1.0");

    await contract.connect(borrower).requestLoan(
      amount, 10, 30, "Need money for business"
    );

    await contract.connect(lender).fundLoan(1, {
      value: ethers.parseEther("1.0")
    });

    const loan = await contract.getLoan(1);
    console.log("Loan status:", loan.status.toString(), "(2 = ACTIVE)");

    expect(loan.status).to.equal(1); // ACTIVE
  });

  it("Borrower can repay a loan", async function () {
    const amount = ethers.parseEther("1.0");

    await contract.connect(borrower).requestLoan(
      amount, 10, 30, "Need money for business"
    );

    await contract.connect(lender).fundLoan(1, {
      value: ethers.parseEther("1.0")
    });

    // repay principal + 10% interest = 1.1 ETH
    await contract.connect(borrower).repayLoan(1, {
      value: ethers.parseEther("1.1")
    });

    const loan = await contract.getLoan(1);
    console.log("Loan status:", loan.status.toString(), "(3 = REPAID)");

    expect(loan.status).to.equal(2); // REPAID
  });
});