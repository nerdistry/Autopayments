// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

error DELEGATEACCOUNT__NOTAUTHORIZED();
error DELEGATEACCOUNT__NOTOWNER();
error DELEGATEACCOUNT__NOTENOUGHFUNDS();
error DELEGATEACCOUNT__TXFAILED();
error DELEGATEACCOUNT__TIMENOTREACHED(
    uint256 timeNow,
    uint256 startTime,
    uint256 period
);
error DELEGATEACCOUNT__NOACCEPTANCENEEDED();
error DELEGATEACCOUNT__NOTBUSINESSUSER();
error DELEGATEACCOUNT__NOTACCOUNTUSER();
error DELEGATEACCOUNT__CANNOTREQUEST();

contract DelegateAccount {
    address private i_owner;
    mapping(address => Permission) private i_authorized;
    bool i_getRequest;

    event PushedPayment(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    event AcceptDelegate(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    event Withdrew(address indexed _to, uint256 indexed _amount);
    event FamilySet(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    modifier onlyAuthorized(address payable caller) {
        if (!i_authorized[caller].status) {
            revert DELEGATEACCOUNT__NOTAUTHORIZED();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert DELEGATEACCOUNT__NOTOWNER();
        }
        _;
    }

    modifier isRequestAccepted() {
        if (!i_getRequest) {
            revert DELEGATEACCOUNT__CANNOTREQUEST();
        }
        _;
    }

    // modifier onlyBusinesses(address payable business) {
    //     BusinessContract businessContract = BusinessContract(business);
    //     if (!businessContract.isAuthorized(business)) {
    //         revert DELEGATEACCOUNT__NOTBUSINESSUSER();
    //     }
    //     _;
    // }

    struct Permission {
        uint256 startPeriod;
        uint256 period;
        uint256 amount;
        bool status;
        uint256 txCount;
    }

    constructor() /**address payable accountAddress*/ {
        i_owner = msg.sender; //should be account owner.
        // account = Account(accountAddress);
        i_getRequest = true;
    }

    receive() external payable {}

    fallback() external payable {}

    function createPermissionFAF(
        address payable _from,
        uint256 _period,
        uint256 _startPeriod,
        uint256 _amount
    ) external onlyOwner {
        i_authorized[_from].startPeriod = _startPeriod;
        i_authorized[_from].amount = _amount;
        i_authorized[_from].period = _period;
        i_authorized[_from].status = false;
        i_authorized[_from].txCount = 0;
        emit FamilySet(_from, address(this), _amount, _period);
    }

    function createPermissionBusiness(
        address payable _from,
        uint256 _period,
        uint256 _startPeriod,
        uint256 _amount
    ) external /**onlyBusinesses(payable(msg.sender))*/ isRequestAccepted {
        i_authorized[_from].startPeriod = _startPeriod;
        i_authorized[_from].amount = _amount;
        i_authorized[_from].period = _period;
        i_authorized[_from].status = false;
        i_authorized[_from].txCount = 0;
    }

    function acceptRequest(address payable _to) external onlyOwner {
        // address isRequesterUnauthorized = account.getUnauthorized(_to);
        // if (isRequesterUnauthorized == _to) {
        //     revert DELEGATEACCOUNT__NOTAUTHORIZED();
        // }

        if (i_authorized[_to].amount > 0 && i_authorized[_to].status) {
            revert DELEGATEACCOUNT__NOACCEPTANCENEEDED();
        }

        i_authorized[_to].startPeriod += block.timestamp;
        i_authorized[_to].status = true;
        emit AcceptDelegate(
            _to,
            address(this),
            i_authorized[_to].amount,
            i_authorized[_to].period
        );
    }

    function pushPayment() external onlyAuthorized(payable(msg.sender)) {
        if (
            i_authorized[msg.sender].txCount > 0 &&
            block.timestamp < i_authorized[msg.sender].startPeriod &&
            block.timestamp <
            i_authorized[msg.sender].startPeriod +
                i_authorized[msg.sender].period
        ) {
            revert DELEGATEACCOUNT__TIMENOTREACHED(
                block.timestamp,
                i_authorized[msg.sender].startPeriod,
                i_authorized[msg.sender].period
            );
        }

        if (block.timestamp < i_authorized[msg.sender].startPeriod) {
            revert DELEGATEACCOUNT__TIMENOTREACHED(
                block.timestamp,
                i_authorized[msg.sender].startPeriod,
                i_authorized[msg.sender].period
            );
        }

        if (i_authorized[msg.sender].amount > address(this).balance) {
            revert DELEGATEACCOUNT__NOTENOUGHFUNDS();
        }
        i_authorized[msg.sender].startPeriod = block.timestamp;
        ++i_authorized[msg.sender].txCount;
        (bool success, ) = payable(msg.sender).call{
            value: i_authorized[msg.sender].amount
        }("");
        if (!success) {
            revert DELEGATEACCOUNT__TXFAILED();
        }
        emit PushedPayment(
            msg.sender,
            address(this),
            i_authorized[msg.sender].amount,
            i_authorized[msg.sender].period
        );
    }

    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        if (address(this).balance < _amount) {
            revert DELEGATEACCOUNT__NOTENOUGHFUNDS();
        }
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert DELEGATEACCOUNT__TXFAILED();
        }
        emit Withdrew(_to, _amount);
    }

    function dontGetRequests() external onlyOwner {
        i_getRequest = false;
    }

    function getRequests() external onlyOwner {
        i_getRequest = true;
    }

    function removePermission(address removeAuthorized) external onlyOwner {
        i_authorized[removeAuthorized].status = false;
    }

    function changeOwner(address newOwner) external onlyOwner {
        i_owner = newOwner;
    }
}
