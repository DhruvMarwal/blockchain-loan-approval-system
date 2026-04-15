// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PLending {

    // ════════════════════════════════════════
    // ENUMS
    // ════════════════════════════════════════

    enum LoanStatus {
        PENDING,    // waiting for offers
        ACTIVE,     // funded, money sent to borrower
        REPAID,     // fully repaid
        DEFAULTED,  // borrower defaulted
        CANCELLED   // cancelled before funding
    }

    // ════════════════════════════════════════
    // STRUCTS
    // ════════════════════════════════════════

    struct Loan {
        uint256 id;
        address borrower;
        address lender;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 collateral;
        uint256 startTime;
        uint256 repaidAmount;
        bytes32 purpose;
        LoanStatus status;
    }

    struct Offer {
        address lender;
        uint256 interestRate;
        uint256 amount;
        bool accepted;
        bool refunded;
    }

    struct CreditProfile {
        uint256 totalLoans;
        uint256 onTimeLoans;
        uint256 lateLoans;
        uint256 defaultedLoans;
        uint256 totalAmountBorrowed;
    }

    // ════════════════════════════════════════
    // STATE VARIABLES
    // ════════════════════════════════════════

    address public owner;
    uint256 public loanCounter;
    uint256 public constant LATE_PENALTY_RATE = 2;
    uint256 public constant GRACE_PERIOD = 1 days;

    // ════════════════════════════════════════
    // MAPPINGS
    // ════════════════════════════════════════

    mapping(uint256 => Loan) public loans;
    mapping(uint256 => uint256) public offerCount;
    mapping(uint256 => mapping(uint256 => Offer)) public loanOffers;
    mapping(address => CreditProfile) public creditProfiles;

    // ════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════

    event LoanRequested(uint256 loanId, address borrower, uint256 amount);
    event OfferMade(uint256 loanId, address lender, uint256 rate);
    event OfferAccepted(uint256 loanId, address lender, uint256 rate);
    event LoanRepaid(uint256 loanId, address borrower);

    // ════════════════════════════════════════
    // MODIFIERS
    // ════════════════════════════════════════

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier loanExists(uint256 loanId) {
        require(loanId > 0 && loanId <= loanCounter, "Loan does not exist");
        _;
    }

    // ════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════

    constructor() {
        owner = msg.sender;
    }

    // ════════════════════════════════════════
    // REQUEST LOAN
    // ════════════════════════════════════════

    function requestLoan(
        uint256 amount,
        uint256 durationInDays,
        bytes32 purpose
    ) external payable {
        require(amount > 0, "Amount must be > 0");
        require(durationInDays >= 1 && durationInDays <= 365, "Duration 1-365 days");
        require(msg.value > 0, "Must lock collateral");
        require(msg.value <= amount, "Collateral cannot exceed loan amount");

        loanCounter++;

        loans[loanCounter] = Loan({
            id: loanCounter,
            borrower: msg.sender,
            lender: address(0),
            amount: amount,
            interestRate: 0,
            duration: durationInDays * 1 days,
            collateral: msg.value,
            startTime: 0,
            repaidAmount: 0,
            purpose: purpose,
            status: LoanStatus.PENDING
        });

        creditProfiles[msg.sender].totalLoans++;
        creditProfiles[msg.sender].totalAmountBorrowed += amount;

        emit LoanRequested(loanCounter, msg.sender, amount);
    }

    // ════════════════════════════════════════
    // MAKE OFFER
    // ════════════════════════════════════════

    function makeOffer(
        uint256 loanId,
        uint256 interestRate
    ) external payable loanExists(loanId) {
        Loan storage loan = loans[loanId];

        require(loan.status == LoanStatus.PENDING, "Loan not open");
        require(msg.sender != loan.borrower, "Borrower cannot offer");
        require(interestRate >= 1 && interestRate <= 100, "Rate 1-100%");
        require(msg.value == loan.amount, "Must send exact loan amount");

        uint256 index = offerCount[loanId];
        loanOffers[loanId][index] = Offer({
            lender: msg.sender,
            interestRate: interestRate,
            amount: msg.value,
            accepted: false,
            refunded: false
        });
        offerCount[loanId]++;

        emit OfferMade(loanId, msg.sender, interestRate);
    }

    // ════════════════════════════════════════
    // ACCEPT OFFER
    // ════════════════════════════════════════

    function acceptOffer(
        uint256 loanId,
        uint256 offerIndex
    ) external loanExists(loanId) {
        Loan storage loan = loans[loanId];
        require(msg.sender == loan.borrower, "Only borrower can accept");
        require(loan.status == LoanStatus.PENDING, "Loan not pending");

        Offer storage offer = loanOffers[loanId][offerIndex];
        require(!offer.accepted, "Already accepted");
        require(!offer.refunded, "Offer was cancelled");

        offer.accepted = true;
        loan.lender = offer.lender;
        loan.interestRate = offer.interestRate;
        loan.status = LoanStatus.ACTIVE;
        loan.startTime = block.timestamp;

        (bool sent,) = payable(loan.borrower).call{value: offer.amount}("");
        require(sent, "Transfer failed");

        emit OfferAccepted(loanId, offer.lender, offer.interestRate);
    }

    // ════════════════════════════════════════
    // CANCEL OFFER
    // ════════════════════════════════════════

    function cancelOffer(
        uint256 loanId,
        uint256 offerIndex
    ) external loanExists(loanId) {
        Offer storage offer = loanOffers[loanId][offerIndex];
        require(msg.sender == offer.lender, "Not your offer");
        require(!offer.accepted, "Already accepted");
        require(!offer.refunded, "Already refunded");

        offer.refunded = true;
        (bool sent,) = payable(msg.sender).call{value: offer.amount}("");
        require(sent, "Transfer failed");
    }

    // ════════════════════════════════════════
    // CALCULATE TOTAL DUE
    // ════════════════════════════════════════

    function calculateTotalDue(uint256 loanId)
        public view loanExists(loanId)
        returns (uint256 principal, uint256 interest, uint256 penalty, uint256 total)
    {
        Loan memory loan = loans[loanId];
        require(loan.status == LoanStatus.ACTIVE, "Loan not active");

        principal = loan.amount;
        interest = (loan.amount * loan.interestRate) / 100;
        penalty = 0;

        uint256 deadline = loan.startTime + loan.duration;
        if (block.timestamp > deadline + GRACE_PERIOD) {
            uint256 daysLate = (block.timestamp - deadline) / 1 days;
            penalty = (loan.amount * LATE_PENALTY_RATE * daysLate) / 100;
        }

        total = principal + interest + penalty;
    }

    // ════════════════════════════════════════
    // REPAY LOAN
    // ════════════════════════════════════════

    function repayLoan(uint256 loanId) external payable loanExists(loanId) {
        Loan storage loan = loans[loanId];
        require(loan.status == LoanStatus.ACTIVE, "Loan not active");
        require(msg.sender == loan.borrower, "Only borrower can repay");

        (,,,uint256 totalDue) = calculateTotalDue(loanId);
        require(msg.value == totalDue, "Incorrect repayment amount");

        uint256 deadline = loan.startTime + loan.duration;
        bool onTime = block.timestamp <= deadline + GRACE_PERIOD;

        loan.repaidAmount = msg.value;
        loan.status = LoanStatus.REPAID;

        if (onTime) {
            creditProfiles[loan.borrower].onTimeLoans++;
        } else {
            creditProfiles[loan.borrower].lateLoans++;
        }

        uint256 col = loan.collateral;
        loan.collateral = 0;
        (bool colSent,) = payable(loan.borrower).call{value: col}("");
        require(colSent, "Collateral return failed");

        (bool repSent,) = payable(loan.lender).call{value: msg.value}("");
        require(repSent, "Repayment failed");

        emit LoanRepaid(loanId, loan.borrower);
    }

    // ════════════════════════════════════════
    // CREDIT SCORE
    // ════════════════════════════════════════

    function getCreditScore(address user) public view returns (uint256) {
        CreditProfile memory p = creditProfiles[user];

        if (p.totalLoans == 0) return 600;

        uint256 onTimeRatio = (p.onTimeLoans * 100) / p.totalLoans;
        uint256 comp1 = (onTimeRatio * 400) / 100;
        uint256 comp2 = p.defaultedLoans * 50;
        uint256 comp3 = p.totalLoans >= 10 ? 100 : p.totalLoans * 10;
        uint256 comp4 = p.totalAmountBorrowed >= 10 ether ? 100 :
                        (p.totalAmountBorrowed * 100) / 10 ether;

        uint256 score = 300 + comp1 + comp3 + comp4;
        score = score > comp2 ? score - comp2 : 300;
        if (score > 900) score = 900;
        if (score < 300) score = 300;

        return score;
    }

    // ════════════════════════════════════════
    // VIEW FUNCTIONS
    // ════════════════════════════════════════

    function getLoan(uint256 loanId)
        external view loanExists(loanId)
        returns (Loan memory) {
        return loans[loanId];
    }

    function getOffers(uint256 loanId)
        external view loanExists(loanId)
        returns (Offer[] memory) {
        uint256 count = offerCount[loanId];
        Offer[] memory offers = new Offer[](count);
        for (uint256 i = 0; i < count; i++) {
            offers[i] = loanOffers[loanId][i];
        }
        return offers;
    }

    function getLoanCount() external view returns (uint256) {
        return loanCounter;
    }

    // ════════════════════════════════════════
    // PAGINATED LOAN FETCH
    // Fetches `count` loans starting from `startId`.
    // Safe — bounded by caller, no unbounded array risk.
    // e.g. getLoansPage(1, 10) → loans 1..10
    // ════════════════════════════════════════

    function getLoansPage(uint256 startId, uint256 count)
        external view
        returns (Loan[] memory)
    {
        require(startId >= 1, "startId must be >= 1");
        uint256 endId = startId + count - 1;
        if (endId > loanCounter) endId = loanCounter;

        uint256 resultCount = endId >= startId ? endId - startId + 1 : 0;
        Loan[] memory page = new Loan[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            page[i] = loans[startId + i];
        }
        return page;
    }
}
