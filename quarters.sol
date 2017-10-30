pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public price;
    uint256 public tranche;
    address public creator;
    
    uint256 public outstandingQuarters;
    uint256 public baseRate = 1;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event TrancheIncrease(uint256 tranche, uint256 price, uint256 etherPool, uint256 outstandingQuarters);
    event MegaEarnings(uint256 tranche, uint256 etherPool, uint256 outstandingQuarters, uint256 baseRate);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 initialPrice,
        uint256 firstTranche
    ) public {
        totalSupply = initialSupply;  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        price = initialPrice;                                    // initial price
        tranche = firstTranche;                                  // number of Quarters to be sold before increasing price
        creator = msg.sender;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }  
    
    function buy() payable public {
        uint256 nq = msg.value*300/price/1000000000000000;    // 300 is a placeholder for the Ether/USD exchange rate
        if (nq>tranche){
            nq=tranche;
        }
        totalSupply = totalSupply + nq;
        balanceOf[msg.sender] = balanceOf[msg.sender] + nq;
        outstandingQuarters+=nq;
        baseRate = this.balance/(outstandingQuarters+1);
        if (totalSupply>tranche) {
            tranche = 2*tranche;   // magic number: tranche size
            price = price * 3 /2;   // magic number: price increase number
            TrancheIncrease( tranche,  price,  this.balance, outstandingQuarters);
        }
        creator.transfer(msg.value/10);
    }
    
   // what happens when totalSupply reaches maximum --> let the totalSupply, tranche & price increase rate be settable by the creator

   // what happens if price gets too low?

   // creating the economic flow in the ethereum
   // gaming community -- token for the games, dice game, 

    function withdraw(uint256 _value) public {
    // ** check if developer
        uint256 n = _value;
        if (n>balanceOf[msg.sender]) {      // can only request to redeem Quarters that you have
            n = balanceOf[msg.sender];
        }
        balanceOf[msg.sender] -= n;
        uint256 earnings = n*baseRate; 
        uint256 rate = 25;          // else, rate for micro developer
        if (n*20>tranche) {       // size of mega developer
            rate = 150;           // rate for mega developer
        } else if (n*100>tranche) {   // size & rate for large developer
            rate = 90;
        } else if (n*2000>tranche) {  // size and rate for medium developer
            rate = 75;
        } else if (n*50000>tranche){  // size and rate for small developer
            rate=50;
        }
        if (rate*earnings/100>this.balance) {
            earnings = this.balance;
        } else {
            earnings = rate*earnings/100;
        }
        outstandingQuarters -= n;        // update the outstanding Quarters
        baseRate = (this.balance-earnings)/(outstandingQuarters+1);
        if (rate==150) {
            MegaEarnings(tranche, this.balance, outstandingQuarters, baseRate);
        }
        msg.sender.transfer( earnings );  // get your earnings!
    }

 } 
