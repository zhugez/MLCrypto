pragma solidity ^0.4.13;

/*

Decentraland Buyer
========================

Buys MANA tokens from the crowdsale on your behalf.
Author: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract DecentralandBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint256 public time_bought;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;
  
  // SHA3 hash of kill switch password.
  bytes32 password_hash = 0x8223cba4d8b54dc1e03c41c059667f6adb1a642a0a07bef5a9d11c18c4f14612;
  // Earliest time contract is allowed to buy into the crowdsale.
  uint256 earliest_buy_block = 4170700;
  // The developer address.
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
  // The crowdsale address.
  address public sale = 0xA66d83716c7CFE425B44D0f7ef92dE263468fb3d;
  // The token address.
  ERC20 public token = ERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
  
  // Allows the developer or anyone with the password to claim the bounty and shut down everything except withdrawals in emergencies.
  function activate_kill_switch(string password) {
    // Only activate the kill switch if the sender is the developer or the password is correct.
    if (msg.sender != developer && sha3(password) != password_hash) throw;
    // Store the claimed bounty in a temporary variable.
    uint256 claimed_bounty = bounty;
    // Update bounty prior to sending to prevent recursive call.
    bounty = 0;
    // Irreversibly activate the kill switch.
    kill_switch = true;
    // Send the caller their bounty for activating the kill switch.
    msg.sender.transfer(claimed_bounty);
  }
  
  // Withdraws all ETH deposited or tokens purchased by the user.
  // "internal" means this function is not externally callable.
  function withdraw(address user, bool has_fee) internal {
    // If called before the ICO, cancel user's participation in the sale.
    if (!bought_tokens) {
      // Store the user's balance prior to withdrawal in a temporary variable.
      uint256 eth_to_withdraw = balances[user];
      // Update the user's balance prior to sending ETH to prevent recursive call.
      balances[user] = 0;
      // Return the user's funds.  Throws on failure to prevent loss of funds.
      user.transfer(eth_to_withdraw);
    }
    // Withdraw the user's tokens if the contract has already purchased them.
    else {
      // Retrieve current token balance of contract.
      uint256 contract_token_balance = token.balanceOf(address(this));
      // Disallow token withdrawals if there are no tokens to withdraw.
      if (contract_token_balance == 0) throw;
      // Store the user's token balance in a temporary variable.
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
      // Update the value of tokens currently held by the contract.
      contract_eth_value -= balances[user];
      // Update the user's balance prior to sending to prevent recursive call.
      balances[user] = 0;
      // No fee if the user withdraws their own funds manually.
      uint256 fee = 0;
      // 1% fee for automatic withdrawals.
      if (has_fee) {
        fee = tokens_to_withdraw / 100;
        // Send the fee to the developer.
        if(!token.transfer(developer, fee)) throw;
      }
      // Send the funds.  Throws on failure to prevent loss of funds.
      if(!token.transfer(user, tokens_to_withdraw - fee)) throw;
    }
  }
  
  // Automatically withdraws on users' behalves (less a 1% fee on tokens).
  function auto_withdraw(address user){
    // Only allow automatic withdrawals after users have had a chance to manually withdraw.
    if (!bought_tokens || now < time_bought + 1 hours) throw;
    // Withdraw the user's funds for them.
    withdraw(user, true);
  }
  
  // Allows developer to add ETH to the buy execution bounty.
  function add_to_bounty() payable {
    // Only allow the developer to contribute to the buy execution bounty.
    if (msg.sender != developer) throw;
    // Disallow adding to bounty if kill switch is active.
    if (kill_switch) throw;
    // Disallow adding to the bounty if contract has already bought the tokens.
    if (bought_tokens) throw;
    // Update bounty to include received amount.
    bounty += msg.value;
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function claim_bounty(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Short circuit to save gas if the earliest buy time hasn't been reached.
    if (block.number < earliest_buy_block) return;
    // Short circuit to save gas if kill switch is active.
    if (kill_switch) return;
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now;
    // Store the claimed bounty in a temporary variable.
    uint256 claimed_bounty = bounty;
    // Update bounty prior to sending to prevent recursive call.
    bounty = 0;
    // Record the amount of ETH sent as the contract's current value.
    contract_eth_value = this.balance - claimed_bounty;
    // Transfer all the funds (less the bounty) to the crowdsale address
    // to buy tokens.  Throws if the crowdsale hasn't started yet or has
    // already completed, preventing loss of funds.
    if(!sale.call.value(contract_eth_value)()) throw;
    // Send the caller their bounty for buying tokens for the contract.
    msg.sender.transfer(claimed_bounty);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Treat near-zero ETH transactions as withdrawal requests.
    if (msg.value <= 1 finney) {
      // No fee on manual withdrawals.
      withdraw(msg.sender, false);
    }
    // Deposit the user's funds for use in purchasing tokens.
    else {
      // Disallow deposits if kill switch is active.
      if (kill_switch) throw;
      // Only allow deposits if the contract hasn't already purchased the tokens.
      if (bought_tokens) throw;
      // Update records of deposited ETH to include the received amount.
      balances[msg.sender] += msg.value;
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Prevent sale contract from refunding ETH to avoid partial fulfillment.
    if (msg.sender == address(sale)) throw;
    // Delegate to the helper function.
    default_helper();
  }
}
