// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

error DELEGATEBUSINESS__NOTAUTHORIZED();
error DELEGATEBUSINESS__NOTOWNER();
error DELEGATEBUSINESS__NOTENOUGHFUNDS();
error DELEGATEBUSINESS__TXFAILED();
error DELEGATEBUSINESS__TIMENOTREACHED();
error DELEGATEBUSINESS__NOACCEPTANCENEEDED();
error DELEGATEBUSINESS__CANNOTREQUEST();
error DELEGATEBUSINESS__NOTBUSINESS();
error DELEGATEBUSINESS__NOTENOUGHPROCEEDS();

contract DelegateBusiness {
    mapping(address => Permission) private i_authorized;
    mapping(address => uint256) private i_pensionProceeds;
    uint256 private s_percentagePension;
    address private i_owner;
    bool i_getRequest;
    // BusinessContract businessAccount;

    event PushedPayment(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    event EmployeeAdded(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    event ExecutiveAdded(
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

    modifier onlyAuthorized(address payable caller) {
        if (!i_authorized[caller].status) {
            revert DELEGATEBUSINESS__NOTAUTHORIZED();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert DELEGATEBUSINESS__NOTOWNER();
        }
        _;
    }

    modifier isRequestAccepted() {
        if (!i_getRequest) {
            revert DELEGATEBUSINESS__CANNOTREQUEST();
        }
        _;
    }

    // modifier onlyBusiness(address payable businessAddress) {
    //     BusinessContract business = BusinessContract(businessAddress);
    //     if (!business.isAuthorized(businessAddress)) {
    //         revert DELEGATEBUSINESS__NOTBUSINESS();
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

    constructor(/*address payable businessAddress*/ uint256 percentage) {
        i_owner = msg.sender; //should be business owner.
        // businessAccount = BusinessContract(businessAddress);
        i_getRequest = true;
        s_percentagePension = percentage;
    }

    receive() external payable {}

    fallback() external payable {}

    function createPermissionEmployee(
        address payable _from,
        uint256 _period,
        uint256 _startPeriod,
        uint256 _amount
    ) external onlyOwner {
        uint pension = ((_amount * s_percentagePension) / 100);
        i_authorized[_from].startPeriod = _startPeriod;
        i_authorized[_from].amount = s_percentagePension > 0
            ? _amount - pension
            : _amount;
        i_authorized[_from].period = _period;
        i_authorized[_from].status = false;
        i_pensionProceeds[_from] = s_percentagePension > 0 ? pension : 0;
        i_authorized[_from].txCount = 0;
        emit EmployeeAdded(_from, address(this), _amount, _period);
    }

    function createPermissionBusiness(
        address payable _from,
        uint256 _period,
        uint256 _startPeriod,
        uint256 _amount
    ) external isRequestAccepted /**onlyBusiness(payable(msg.sender))*/ {
        i_authorized[_from].startPeriod = _startPeriod;
        i_authorized[_from].amount = _amount;
        i_authorized[_from].period = _period;
        i_authorized[_from].status = false;
        i_authorized[_from].txCount = 0;
    }

    function createPermissionExecutive(
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
        emit ExecutiveAdded(_from, address(this), _amount, _period);
    }

    function acceptRequest(address payable _to) external onlyOwner {
        // address isRequesterUnauthorized = businessAccount.getUnauthorized(_to);
        // if (isRequesterUnauthorized == _to) {
        //     revert DELEGATEBUSINESS__NOTAUTHORIZED();
        // }

        if (i_authorized[_to].amount > 0 && i_authorized[_to].status) {
            revert DELEGATEBUSINESS__NOACCEPTANCENEEDED();
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
            revert DELEGATEBUSINESS__TIMENOTREACHED();
        }

        if (block.timestamp < i_authorized[msg.sender].startPeriod) {
            revert DELEGATEBUSINESS__TIMENOTREACHED();
        }

        if (i_authorized[msg.sender].amount > address(this).balance) {
            revert DELEGATEBUSINESS__NOTENOUGHFUNDS();
        }

        i_authorized[msg.sender].startPeriod = block.timestamp;
        ++i_authorized[msg.sender].txCount;

        (bool success, ) = payable(msg.sender).call{
            value: i_authorized[msg.sender].amount
        }("");
        if (!success) {
            revert DELEGATEBUSINESS__TXFAILED();
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
            revert DELEGATEBUSINESS__NOTENOUGHFUNDS();
        }
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert DELEGATEBUSINESS__TXFAILED();
        }
        emit Withdrew(_to, _amount);
    }

    function sendPensionProceeds(
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        if (i_pensionProceeds[_to] < _amount) {
            revert DELEGATEBUSINESS__NOTENOUGHPROCEEDS();
        }

        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert DELEGATEBUSINESS__TXFAILED();
        }
    }

    function dontGetRequests() external onlyOwner {
        i_getRequest = false;
    }

    function getRequests() external onlyOwner {
        i_getRequest = true;
    }

    function changePensionProceeds(uint256 newPercentage) external onlyOwner {
        s_percentagePension = newPercentage;
    }

    function removePermission(address removeAuthorized) external onlyOwner {
        i_authorized[removeAuthorized].status = false;
    }

    function changeOwner(address newOwner) external onlyOwner {
        i_owner = newOwner;
    }
}
