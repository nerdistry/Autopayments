// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "./delegate.sol";
import "./DelegateBusiness.sol";

error AUTOPAYMENTBUSINESS__NOTOWNER();
error AUTOPAYMENTBUSINESS__NOTENOUGHFUNDS();
error AUTOPAYMENTBUSINESS__TXFAILED();
error AUTOPAYMENTBUSINESS__TIMENOTPASSED();
error AUTOPAYMENTBUSINESS__NOGRACEPERIOD();

contract AutopaymentBusiness {
    address private i_owner;
    uint256 private i_gracePeriod;
    uint256 private immutable i_discountTime;
    uint256 private s_amount;
    uint256 private s_period;
    uint256 private s_amountForBuss;
    uint256 private s_periodForBuss;

    event RequestSent(
        address indexed payee,
        address indexed payer,
        uint256 indexed amount,
        uint period
    );

    event GracePeriod(
        address indexed payee,
        address indexed payer,
        bool indexed status
    );

    event MoneyWithdrawn(address indexed to, uint indexed amount);

    modifier onlyBusiness() {
        if (msg.sender != i_owner) {
            revert AUTOPAYMENTBUSINESS__NOTOWNER();
        }
        _;
    }

    address[] private s_notEnoughFundsAddresses;

    constructor(
        uint256 gracePeriod,
        uint256 discountTime,
        uint amount,
        uint period,
        uint256 amountBuss,
        uint256 periodBuss
    ) {
        i_owner = msg.sender; //business owner
        i_gracePeriod = gracePeriod;
        i_discountTime = discountTime;
        s_amount = amount;
        s_period = period;
        s_amountForBuss = amountBuss;
        s_periodForBuss = periodBuss;
    }

    receive() external payable {}

    fallback() external payable {}

    function requestPermissionUsers(
        address payable _from
    ) external onlyBusiness {
        DelegateAccount requestAccount = DelegateAccount(_from);
        requestAccount.createPermissionBusiness(
            payable(address(this)),
            s_period,
            i_discountTime,
            s_amount
        );
        emit RequestSent(address(this), _from, s_amount, s_period);
    }

    function requestPermissionBusiness(
        address payable _from
    ) external onlyBusiness {
        DelegateBusiness requestBusiness = DelegateBusiness(_from);
        requestBusiness.createPermissionBusiness(
            payable(address(this)),
            s_periodForBuss,
            i_discountTime,
            s_amountForBuss
        );
        emit RequestSent(address(this), _from, s_amount, s_period);
    }

    function pullPayment(
        address payable[] calldata pushAddress
    ) external onlyBusiness {
        uint len = pushAddress.length;
        for (uint256 i = 0; i < len; ) {
            DelegateAccount requestAccount = DelegateAccount(pushAddress[i]);
            requestAccount.pushPayment();
            if (i == len - 1) {
                i = 0;
            } else {
                unchecked {
                    ++i;
                }
            }
        }
    }

    function pullPaymentBusinesses(
        address payable[] calldata pushAddress
    ) external onlyBusiness {
        uint len = pushAddress.length;
        bool isIncremented;
        bool shouldContinue = true;
        for (uint256 i = 0; i < len; ) {
            DelegateBusiness requestBusiness = DelegateBusiness(pushAddress[i]);
            try requestBusiness.pushPayment() {
                isIncremented = false;
            } catch Error(string memory reason) {
                if (
                    keccak256(bytes(reason)) ==
                    keccak256(bytes("DELEGATEACCOUNT__NOTENOUGHFUNDS"))
                ) {
                    s_notEnoughFundsAddresses.push(pushAddress[i]);
                    //remove from array.
                    isIncremented = true;
                } else if (
                    keccak256(bytes(reason)) ==
                    keccak256(bytes("DELEGATEACCOUNT__TIMENOTREACHED"))
                ) {
                    //we need to get the time.
                    //and then break so as to continue later.
                    //then continue from that time.
                    shouldContinue = false;
                } else if (
                    keccak256(bytes(reason)) ==
                    keccak256(bytes("DELEGATEACCOUNT__TXFAILED"))
                ) {
                    s_notEnoughFundsAddresses.push(pushAddress[i]);
                    //remove from array
                    isIncremented = true;
                }
            }

            if (i == len - 1) {
                i = 0;
            } else {
                unchecked {
                    !isIncremented ? ++i : ++i;
                }
            }
        }
    }

    function checkGracePeriod(
        address payable[] calldata payers
    ) external onlyBusiness {
        //for businesses(autocredit) and business subscribers.
        uint payment;
        bool situation;
        address notPayed;

        if (i_gracePeriod <= 0) {
            revert AUTOPAYMENTBUSINESS__NOGRACEPERIOD();
        }

        if (s_period + i_gracePeriod < s_period) {
            revert AUTOPAYMENTBUSINESS__TIMENOTPASSED();
        }
        uint len = payers.length;

        for (uint256 i = 0; i < len; ) {
            if (payment <= /*amount supposed to pay. */ payment) {
                situation = false;
                notPayed = payers[i];
            }
            unchecked {
                ++i;
            }
        }

        emit GracePeriod(address(this), notPayed, situation);
    }

    //grace for businesses.

    function withdraw(
        uint256 s_amountToWithdraw,
        address payable _to
    ) external onlyBusiness {
        if (address(this).balance < s_amountToWithdraw) {
            revert AUTOPAYMENTBUSINESS__NOTENOUGHFUNDS();
        }
        (bool success, ) = _to.call{value: s_amountToWithdraw}("");
        if (!success) {
            revert AUTOPAYMENTBUSINESS__TXFAILED();
        }
        emit MoneyWithdrawn(_to, s_amountToWithdraw);
    }

    function changeBusiness(address newOwner) external onlyBusiness {
        i_owner = newOwner;
    }

    function changeAmount(uint256 newAmount) external onlyBusiness {
        s_amount = newAmount;
    }

    function changeAmountForBusiness(uint256 newAmount) external onlyBusiness {
        s_amountForBuss = newAmount;
    }

    function changePeriod(uint256 newPeriod) external onlyBusiness {
        s_period = newPeriod;
    }

    function changePeriodForBusiness(uint256 newPeriod) external onlyBusiness {
        s_periodForBuss = newPeriod;
    }

    function changeGracePeriod(uint256 newGracePeriod) external onlyBusiness {
        i_gracePeriod = newGracePeriod;
    }
}
