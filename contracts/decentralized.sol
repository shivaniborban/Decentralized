// Crowdfunding solidity project for GOG by Shivani Borban
pragma solidity ^0.8.20;

contract CharityDonation {
    struct Charity {
        uint256 id;
        string name;
        address payable wallet;
        uint256 totalReceived;
    }

    mapping(uint256 => Charity) public charities;
    mapping(address => uint256) public donorBalances;
    uint256 public charityCount;

    bool private locked; // 🔒 Reentrancy lock

    // ------------------------------
    //  MODIFIERS
    // ------------------------------
    modifier noReentrancy() {
        require(!locked, "Reentrancy guard");
        locked = true;
        _;
        locked = false;
    }

    modifier validCharity(uint256 _charityId) {
        require(_charityId > 0 && _charityId <= charityCount, "Invalid charity ID");
        _;
    }

    // ------------------------------
    //  REGISTER CHARITY
    // ------------------------------
    function registerCharity(string calldata _name, address payable _wallet) external {
        require(_wallet != address(0), "Invalid wallet address"); // ✅ Added check

        charityCount++;
        charities[charityCount] = Charity({
            id: charityCount,
            name: _name,
            wallet: _wallet,
            totalReceived: 0
        });
    }

    // ------------------------------
    //  DONATE FUNCTION (Reentrancy Safe)
    // ------------------------------
    function donate(uint256 _charityId) external payable noReentrancy validCharity(_charityId) {
        require(msg.value > 0, "Donation must be > 0");

        // ✅ Checks-Effects-Interactions pattern
        // 1️⃣ Checks done above
        // 2️⃣ Effects: update state first
        donorBalances[msg.sender] += msg.value;
        charities[_charityId].totalReceived += msg.value;

        // 3️⃣ Interactions: external call last
        (bool sent, ) = charities[_charityId].wallet.call{value: msg.value}("");
        require(sent, "Transfer failed");
    }

    // ------------------------------
    //  WITHDRAWAL PATTERN
    // ------------------------------
    // Instead of sending funds directly in donate(), we can let charities withdraw
    function donateSafe(uint256 _charityId) external payable validCharity(_charityId) {
        require(msg.value > 0, "Donation must be > 0");
        donorBalances[msg.sender] += msg.value;
        charities[_charityId].totalReceived += msg.value;
    }

    function withdrawDonations(uint256 _charityId) external noReentrancy validCharity(_charityId) {
        Charity storage charity = charities[_charityId];
        require(msg.sender == charity.wallet, "Only charity wallet can withdraw");

        uint256 amount = charity.totalReceived;
        require(amount > 0, "No funds to withdraw");

        charity.totalReceived = 0; // Effects
        (bool success, ) = charity.wallet.call{value: amount}(""); // Interaction
        require(success, "Withdrawal failed");
    }

    // ------------------------------
    //  VIEW FUNCTIONS
    // ------------------------------
    function getCharity(uint256 _charityId)
        external
        view
        validCharity(_charityId)
        returns (string memory, address, uint256)
    {
        Charity memory c = charities[_charityId];
        return (c.name, c.wallet, c.totalReceived);
    }
}



