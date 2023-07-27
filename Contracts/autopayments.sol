// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "./delegate.sol";

error AUTOPAYMENT__NOTOWNER();
error AUTOPAYMENT__NOTENOUGHFUNDS();
error AUTOPAYMENT__TXFAILED();
error AUTOPAYMENT__TIMENOTPASSED();
error AUTOPAYMENT__NOGRACEPERIOD();
error AUTOPAYMENT__NOTBUSINESSMEMBER();

contract AutoPayment {
    address private i_Owner;

    event MoneyWithdrawn(address indexed to, uint indexed amount);
    event RevertReason(string reason);

    modifier onlyOwner() {
        if (msg.sender != i_Owner) {
            revert AUTOPAYMENT__NOTOWNER();
        }
        _;
    }

    constructor() {
        i_Owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    function pullPayment(
        address payable[] calldata pushAddress
    ) external onlyOwner {
        uint len = pushAddress.length;
        for (uint256 i = 0; i < len; ) {
            DelegateAccount requestAccount = DelegateAccount(pushAddress[i]);

            try requestAccount.pushPayment() {} catch Error(
                string memory reason
            ) {
                emit RevertReason(reason);
            }
            unchecked {
                ++i;
            }
        }
    }

    // function pullPaymentAsEmployee(
    //     address payable businessAddress,
    //     address businessNFT,
    //     uint256 tokenId
    // ) external onlyOwner {
    //     BusinessNFT businessNft = BusinessNFT(businessNFT);
    //     if (!businessNft.isEmployee(address(this), tokenId)) {
    //         revert AUTOPAYMENT__NOTBUSINESSMEMBER();
    //     }

    //     DelegateBusiness requestBusiness = DelegateBusiness(businessAddress);
    //     requestBusiness.pushPayment();
    // }

    // function pullPaymentAsExecutive(
    //     address payable businessAddress,
    //     address businessNFT,
    //     uint256 tokenId
    // ) external onlyOwner {
    //     BusinessNFT businessNft = BusinessNFT(businessNFT);
    //     if (!businessNft.isExecutives(address(this), tokenId)) {
    //         revert AUTOPAYMENT__NOTBUSINESSMEMBER();
    //     }

    //     DelegateBusiness requestBusiness = DelegateBusiness(businessAddress);
    //     requestBusiness.pushPayment();
    // }

    function withdraw(
        uint256 s_amountToWithdraw,
        address payable _to
    ) external onlyOwner {
        if (address(this).balance < s_amountToWithdraw) {
            revert AUTOPAYMENT__NOTENOUGHFUNDS();
        }
        (bool success, ) = _to.call{value: s_amountToWithdraw}("");
        if (!success) {
            revert AUTOPAYMENT__TXFAILED();
        }
        emit MoneyWithdrawn(_to, s_amountToWithdraw);
    }

    function changeOwner(address newOwner) external onlyOwner {
        i_Owner = newOwner;
    }
}
