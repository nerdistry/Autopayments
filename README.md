## Solution To Autopayments.

# The following is a thesis on how autopayments may work on EVM compatible chains.

_Other ideas are welcome or edits and solutions to the issues highlighted below._

I have used hardhat as the development tool kit.

First transfer the project to your local machine:

```shell
git init
git clone https://github.com/21fahm/Autopayments.git
```

Try running some of the following tasks:

```shell
npm install --save-dev hardhat
npm install --save-dev @nomicfoundation/hardhat-toolbox
```

Confirm all is okay by running

```shell
npx hardhat compile
```

Should see an output of: "Compiled 1 Solidity file successfully"

_Or you can use the development kit of your choice😁_

### Contracts

We have 4 contracts:

- Autopayments.sol - This is managed by a user.
- AutopaymentsBusiness.sol - This is managed by the business
- DelegateBusiness.sol - This is managed by Business
- Delegate.sol - This is managed by user.

Now in Autopayments contracts we have a function called "requestPermission"
this is called by the owner of the contract to request permission to pull
payments from Delegate contracts. When they call this function it is added
to the mapping "mapping(address => Permission) private i_authorized;" awaiting users
approval.

_Think of these like how it happens today. You take your visa card go to merchants website_
_enter your details and you will be debited every month._

ONLY owners of delegate accounts should be able to accept this request. If accepted the
autopayments contracts will be allowed to PULL payments using the pullPayment function
from the delegate contracts which have pushFunction that allow only authorized autopayment
function to pull payment.

_Think of this as how you share your CVV with the merchants. That proofs to the bank account that_
_even though the merchants does not have the passcode to you bank avcount they are authorized to_
_pull payment from the account._

# Advantage

I can note some advantages to this system from the traditional way of using visa in that:

- You don't share some CVV that can be compromised and attacker can pull money from your card and send
  to their account. Even if they are able to compromise tha business contract they cannot pull payment
  form the account until time has passes and cannot pull amount greater that what has been accepted by
  the delegate accounts.🤯
- Business don't get to increase prices the way they want. This is a contract and it is immutable. If
  business want to increase price users have to agree for them to more funds from the account.
- We have grace period that businesses and users are given if they don't have funds in their accounts to
  settle payments immediately.
- Business get to handle the autopayment system same as users. No intermidiary that can lock up funds
  or be compromised. (May seem like a vulnerability but users have MPC security)

  # Issues

  The following are some issues that will make the system inadequate:

  - (The pull payment takes an array)- Lets say that the autopayments contracts have been pulling
    payment and reached point [i] where the time has not reached or the account doesn't have enough
    to settle payment. It will stop because that also means that from that point going forward also
    the time has not reached. (If one doesn't have amount we can push into an array that will go to
    the grace period and remove them from the array being iterated). Businesses can take the time left for
    valid pulling payments and call the function when the time reached but remember that the previous addresses
    time limits are also continuing. TIME DOESN'T STOP. (You can say we push the confirmed address to another array and then use another function to deal with these addresses but that just means more gas and looks SHIT!).
    _Is the array parameter an issue? Is there a better way?_
  - Issue 2 is that we cannot pull tokens. Example stablecoins which many people may prefer. This can easily
    be solved by having extra push and createRequest function that deal with tokens. Some things we will
    add to the struct is ERC20 Address and the amount not to be in wei.
    _Still is there a better way of doing these?_
    _Short answer may be no. Because of the difference in transfer between tokens and coins._
  - Business need to know if one has made payment so they can decide if they will realease service or not.
    We can solve by mapping an address to (address, bool and time) where address is the payer, bool is if
    they have paid and time is the next time they will pay.
    _Other ideas are welcome_

  ## Some What solutions.

  - So i thought of some solutions. As you can see in the autopayments contracts we have try and catch this will
    help us now whats the reason of revert with the ERROR keyword. This also allows the function to now revert which is what we want. Issue you ask, the way i have set it up is when it reaches n - 1(where n is the length of the array) it changes [i] to 0. So its a loop that never ends. This may not be an issue in languages like JS but in solidity🤔 GAS!!! Especially if business decides to deploy on ETH whoo they will pay a tone of gas and will not be profitable for the business. Solution will be not to do what i do, and to just let the function to end. Take the time left for the address at position [0] and business to call function after that time has reached. NO! Well that may work but lets think of a company like apple. It has hundred billion users. Lets say they use ethereum. This array is too long for it to iterate because ethereum as it is not scalable. Remember again GAS! It may work i am not saying it won't but gas will be expensive and if the autopayments happen daily will it break? We can solve this by using scalable EVM compatible chains like polygon or HBAR and saying that ETH should focus on scalability(They are by the way). But i will bring back the question, is there another way so that we can avoid arrays? Or should we only go with weekly, monthly and yearly autopayments for ETH😆. NO! I am sure we can come up with something better.
  - I mentioned that we can loop through fast and take they issues that are their and deal with them or if they go successfully we say hey nice! But this array will be too long. Ethereum will take time to reach the 100 billion position. Time for the previous address is still elapsing. WHAT DO WE DO! (Again we can push to another array depend on another function to handle this but that just means we will have a billion functions(Not literally😆))

## Remarks

The system is great. But the issues mentioned will not make the system adequate especially for ETH.
UTXO blockchains like Litecoin and Bitcoin have timelocked transactions that can be set up. That is payment will be sent if and only if a certain time has reached. But require user iteraction. So we will not dwell with this until we launch. Bitcoin's script language is also shit. No offence.
Lemme also mention this we need to think about private autpayments. We could have easily set up the above system in users accounts or business. I decided to separate them for some level of privacy but lets agree that it is still not ultimate privacy. We need to think about stealth address but the issue right now is that we cannot prove address x has made payment because address x will send money to business stealth address y and business real address is z.(Right now we still require user to share their address so that business can be sure that user or business has made payment so as to release service) Maybe some ZK tricks can help.
Also we will use Account abstraction instead of EOA that have to initiate transactions.
