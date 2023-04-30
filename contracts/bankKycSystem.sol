// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface BankInterface {
    function addKycRequest(
        string memory _customerName,
        string memory _customerData
    ) external;

    function removeKycRequest(string memory _customerName) external;

    function addCustomer(
        string memory _customerName,
        string memory _customerData
    ) external;

    function viewCustomer(string memory _customerName)
        external
        view
        returns (
            string memory name,
            string memory data,
            address bank,
            bool kycStatus,
            uint256 upvotes,
            uint256 downvotes
        );

    function upvoteCustomer(string memory _customerName) external;

    function downvoteCustomer(string memory _customerName) external;

    function modifyCustomer(
        string memory _customerName,
        string memory _customerData
    ) external;

    function getBankComplaints(address _bankAddress)
        external
        view
        returns (uint256);

    function viewBankDetails(address _bankAddress)
        external
        view
        returns (
            string memory,
            address,
            string memory,
            uint256,
            bool,
            uint256
        );

    function reportBank(address _bankAddress, string memory _bankName) external;
}

interface AdminInterface {
    function addBank(
        address bankAddress,
        string memory bankName,
        string memory bankRegNo
    ) external;

    function modifyBankVotingStatus(address _bankAddress, bool _isAllowedToVote)
        external;

    function removeBank(address _bankAddress) external;
}

contract BankKycSystem is BankInterface, AdminInterface {
    address admin;
    uint256 private totalBanks;

    constructor() {
        admin = msg.sender;
        // Initialized the contract with this 5 default banks
        addBank(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "SBI", "71E1");
        addBank(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "BOB", "71E2");
        addBank(0x617F2E2fD72FD9D5503197092aC168c91465E7f2, "BOI", "71E3");
        addBank(0x17F6AD8Ef982297579C203069C1DbfFE4348c372, "BOM", "71E4");
        addBank(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678, "PNB", "71E5");
    }

    modifier isAdmin() {
        // checks whether msg.sender is admin or not
        require(msg.sender == admin, "Only admin can access");
        _;
    }
    modifier isYourCustomer(string memory _customerName) {
        require( // checks whether the user has account in the bank which is modifying the details of user
            customers[_customerName].bank == msg.sender,
            "You are not allowed"
        );
        _;
    }
    modifier isBank() {
        // checks whether msg.sender(bank) is present in the bankList of the contract or not
        require(
            banks[msg.sender].ethAddress != address(0),
            "Bank address is not registered"
        );
        _;
    }

    modifier iscorrupt() {
        // checks whether the bank is allowed to vote or not
        require(banks[msg.sender].isAllowedToVote, "Not allowed to vote");
        _;
    }

    struct Customer {
        string customerName;
        string customerData;
        address bank;
        bool kycStatus;
        uint256 upvotes;
        uint256 downvotes;
    }

    struct Bank {
        string name;
        address ethAddress;
        string regNumber;
        uint256 complaintsReported;
        bool isAllowedToVote;
        uint256 kyc_Count;
    }

    struct KycRequest {
        string customerName;
        address bank;
        string customerData;
    }

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    mapping(string => KycRequest) kycRequests;

    function addCustomer(
        // This function will add a customer to the customer list
        string memory _customerName,
        string memory _customerData
    ) external override isBank iscorrupt {
        require(
            customers[_customerName].bank == address(0),
            "Customer has already registered in this bank"
        );
        customers[_customerName].customerName = _customerName;
        customers[_customerName].customerData = _customerData;
        customers[_customerName].bank = msg.sender;
        customers[_customerName].kycStatus = false;
        customers[_customerName].upvotes = 0;
        customers[_customerName].downvotes = 0;
        banks[msg.sender].kyc_Count += 1;
    }

    function modifyCustomer(
        // This function allows a bank to modify a customer's data.
        string memory _customerName,
        string memory newCustomerDataHash
    ) external override isBank iscorrupt isYourCustomer(_customerName) {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not there in Database"
        );
        customers[_customerName].customerData = newCustomerDataHash;
    }

    function viewCustomer(
        string memory _customerName // This function allows a bank to view the details of a customer.
    )
        external
        view
        override
        isBank
        returns (
            string memory name,
            string memory data,
            address bank,
            bool kycStatus,
            uint256 upvotes,
            uint256 downvotes
        )
    {
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        return (
            customers[_customerName].customerName,
            customers[_customerName].customerData,
            customers[_customerName].bank,
            customers[_customerName].kycStatus,
            customers[_customerName].upvotes,
            customers[_customerName].downvotes
        );
    }

    function addKycRequest(
        string memory _customerName,
        string memory _customerData
    ) external override isBank iscorrupt isYourCustomer(_customerName) {
        // This function is used to add the KYC request to the requests list
        kycRequests[_customerName].customerName = _customerName;
        kycRequests[_customerName].customerData = _customerData;
        kycRequests[_customerName].bank = msg.sender;
        customers[_customerName].customerData = _customerData;
        customers[_customerName].kycStatus = true;
    }

    function removeKycRequest(string memory _customerName)
        external
        override
        // This function will remove the request from the requests list.
        isBank
        iscorrupt
        isYourCustomer(_customerName)
    {
        delete kycRequests[_customerName];
        customers[_customerName].kycStatus = false;
    }

    function upvoteCustomer(string memory _customerName)
        external
        override
        // This function allows a bank to cast an upvote for a customer.
        isBank
        iscorrupt
    {
        require(banks[msg.sender].isAllowedToVote, "You Can Not Vote");
        require(customers[_customerName].kycStatus);
        customers[_customerName].upvotes = customers[_customerName].upvotes + 1;
    }

    function downvoteCustomer(string memory _customerName)
        external
        override
        // This function allows a bank to cast a downvote for a customer.
        isBank
        iscorrupt
    {
        require(banks[msg.sender].isAllowedToVote, "You Can Not Vote");
        require(customers[_customerName].kycStatus);
        customers[_customerName].downvotes =
            customers[_customerName].downvotes +
            1;
        if (
            customers[_customerName].downvotes > (totalBanks / 3) ||
            customers[_customerName].downvotes >=
            customers[_customerName].upvotes
        ) {
            customers[_customerName].kycStatus = false;
        }
    }

    function getBankComplaints(address _bankAddress)
        external
        view
        override
        returns (
            // This function will be used to fetch bank complaints from the smart contract.
            uint256
        )
    {
        return banks[_bankAddress].complaintsReported;
    }

    function viewBankDetails(address _bankAddress)
        external
        view
        override
        returns (
            // This function is used to fetch the bank details.
            string memory,
            address,
            string memory,
            uint256,
            bool,
            uint256
        )
    {
        return (
            banks[_bankAddress].name,
            banks[_bankAddress].ethAddress,
            banks[_bankAddress].regNumber,
            banks[_bankAddress].complaintsReported,
            banks[_bankAddress].isAllowedToVote,
            banks[_bankAddress].kyc_Count
        );
    }

    function reportBank(address _bankAddress, string memory _bankName)
        external
        override
        // This function is used to report a complaint against any bank in the network.
        isBank
        iscorrupt
    {
        require(banks[_bankAddress].ethAddress != msg.sender);
        require(
            keccak256(abi.encode(banks[_bankAddress].name)) ==
                keccak256(abi.encode(_bankName)),
            "Bank name does not match"
        );
        banks[_bankAddress].complaintsReported += 1;
        if (banks[_bankAddress].complaintsReported > (totalBanks / 3)) {
            modifyBankVotingStatus(_bankAddress, false);
        }
    }

    function addBank(
        // This function is used by the admin to add a bank to the KYC Contract.
        address bankAddress,
        string memory bankName,
        string memory bankRegNo
    ) public override isAdmin {
        banks[bankAddress].name = bankName;
        banks[bankAddress].ethAddress = bankAddress;
        banks[bankAddress].regNumber = bankRegNo;
        banks[bankAddress].isAllowedToVote = true;
        banks[bankAddress].complaintsReported = 0;
        banks[bankAddress].kyc_Count = 0;
        totalBanks += 1;
    }

    function modifyBankVotingStatus(address _bankAddress, bool _isAllowedToVote)
        public
        override
        // This function can only be used by the admin to change the status of isAllowedToVote of any of the banks at any point in time.
        isAdmin
    {
        banks[_bankAddress].isAllowedToVote = _isAllowedToVote;
    }

    function removeBank(address bankAddress) external override isBank isAdmin {
        // This function is used by the admin to remove a bank from the KYC Contract.
        Bank memory bank;
        banks[bankAddress] = bank;
        delete banks[bankAddress];
        totalBanks -= 1;
    }
}
