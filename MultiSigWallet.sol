// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 indexed amount);
    event Submit(uint256 TxID);
    event Approve(address indexed sender, uint256 indexed TxID);
    event Revoke(address indexed sender, uint256 indexed TxID);
    event Execute(uint256 indexed TxID);
    event NewOwner(address indexed LatestOwner);

    uint256 public requiredVotes;
    address[] public owners;

    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public approved;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public Transactions;

    constructor(address[] memory _owners, uint256 _requiredVotes) payable {
        require(_owners.length > 0, "Must have atleast one owner!");
        require(
            _requiredVotes > 0 && _requiredVotes <= _owners.length,
            "Invalid number of rquired votes!"
        );

        requiredVotes = _requiredVotes;

        // owners = _owners; - valid code but @dev checks for address(0)...
        for (uint256 index = 0; index < _owners.length; index++) {
            address owner = _owners[index];
            // require(!isOwner[owner], "Owner is already initialized!" ); - Happens at constructor , low odds

            require(owner != address(0), "Zero address cannot be an owner!");
            owners.push(owner);
            isOwner[owner] = true;
        }
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Function reserved for only owners!");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < Transactions.length, "Transaction doesn't Exist!");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(
            !approved[_txId][msg.sender],
            "Transaction is yet to be approved"
        );
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(
            !Transactions[_txId].executed,
            "This transaction has already been executed!"
        );
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // any of the owners to submit a txn

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (uint256 TxID) {
        Transactions.push(Transaction(_to, _value, _data, false));
        TxID = Transactions.length - 1;
        emit Submit(TxID); // we didnt need to return it again...
    }

    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function getApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            if (approved[_txId][owner]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(
            getApprovalCount(_txId) >= requiredVotes,
            "More approvals are Needed!"
        );

        Transaction storage processingTx = Transactions[_txId]; // to enable state modification

        (bool success, ) = processingTx.to.call{value: processingTx.value}(
            processingTx.data
        );
        require(success, "send fail!");
        processingTx.executed = true;
        emit Execute(_txId);
    }

    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "Transaction is not approved!");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function addOwner() external payable {
        require(msg.value == 1e18, "Not enough Eth");
        require(msg.sender != address(0), "Zero address cannot be an owner!");
        isOwner[msg.sender] = true;
        owners.push(msg.sender);
        emit NewOwner(msg.sender);
    }
}
