#!/usr/bin/env python3

# Continuously monitor the impermanent loss incurred for a position in Uniswap V3
# And if there is a loss, we need to exit the position
# We can use the Uniswap V3's subgraph to know a position's details like tokens, price at the time of providing liquidity, etc. We will also know the current tick in the pool.
# When the loss crosses a threshold (like say 50%), we need to trigger the recovery process.

# The recovery process is to exit the position and provide liquidity again in the same range. This will reset the price at which we provided liquidity and we will be able to start the process again.

# We can use the Uniswap V3 SDK to exit the position and provide liquidity again.

# We need to deploy a simple smart contract that wraps around Uniswap V3's LP exiting function and trigger this function when the above monitoring logic is executed. The output of this should result in the wallet having the LP tokens back with the position fuly exited.


# The smart contract should also have a function that wraps around Uniswap V3's LP providing function and trigger this function when the above monitoring logic is executed. The output of this should result in the wallet having the LP tokens back with the position fuly exited.

from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport
import math
import sys

# Constants
# The address of the Uniswap V3 subgraph
SUBGRAPH_URL = "https://api.thegraph.com/subgraphs/name/ianlapham/uniswap-v3"

# The address of the Uniswap V3 LP token
UNISWAP_V3_LP_TOKEN_ADDRESS = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984"

# The address of the Uniswap V3 factory
UNISWAP_V3_FACTORY_ADDRESS = "0x1F984"

# The address of the Uniswap V3 router
UNISWAP_V3_ROUTER_ADDRESS = "0xE592"

# The address of the Uniswap V3 pool
UNISWAP_V3_POOL_ADDRESS = "0x8ad599"

# The address of the Uniswap V3 position
UNISWAP_V3_POSITION_ADDRESS = "0x8ad599"

# The address of the Uniswap V3 position manager
UNISWAP_V3_POSITION_MANAGER_ADDRESS = "0xC36442"

# The address of the Uniswap V3 NFT position manager
UNISWAP_V3_NFT_POSITION_MANAGER_ADDRESS = "0xC36442"

# The address of the Uniswap V3 swap router
UNISWAP_V3_SWAP_ROUTER_ADDRESS = "0xE592"

# The address of the Uniswap V3 multicall
UNISWAP_V3_MULTICALL_ADDRESS = "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696"


POSITION_ID = "2"

# The address of the wallet that holds the LP tokens
WALLET_ADDRESS = "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8"

# if passed in command line, use an alternative pool ID
if len(sys.argv) > 1:
    POSITION_ID = sys.argv[1]

# The address of the smart contract that wraps around Uniswap V3's LP exiting function
UNISWAP_V3_LP_EXITING_FUNCTION_ADDRESS = "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8"


TICK_BASE = 1.0001

position_query = """query get_position($position_id: ID!) {
  positions(where: {id: $position_id}) {
    liquidity
    tickLower { tickIdx }
    tickUpper { tickIdx }
    pool { id }
    token0 {
      symbol
      decimals
    }
    token1 {
      symbol
      decimals
    }
  }
}"""


# return the tick and the sqrt of the current price

def get_current_tick_and_sqrt_price():
	transport = RequestsHTTPTransport(url=SUBGRAPH_URL, use_json=True)
	client = Client(transport=transport, fetch_schema_from_transport=True)
	query = gql(position_query)
	params = {"position_id": POSITION_ID}
	result = client.execute(query, variable_values=params)
	print(result)
	print(result["positions"][0]["tickLower"]["tickIdx"])

	# The tick is the difference between the current price and the price at which we provided liquidity

	# The current price is the sqrt of the current tick
	current_tick = result["positions"][0]["tickUpper"]["tickIdx"] - result["positions"][0]["tickLower"]["tickIdx"]
	
def tick_to_price(tick):
	return math.pow(TICK_BASE, tick)

def price_to_tick(price):
	return math.log(price, TICK_BASE)


client=Client(transport=RequestsHTTPTransport(url=SUBGRAPH_URL, use_json=True), fetch_schema_from_transport=True)


# get position info

query = gql
params = {"position_id": POSITION_ID}
result = client.execute(query, variable_values=params)
print(result)

# get current tick and sqrt price

current_tick = result["positions"][0]["tickUpper"]["tickIdx"] - result["positions"][0]["tickLower"]["tickIdx"]
print(current_tick)

# get current price

current_price = tick_to_price(current_tick)
print(current_price)

# get price at which we provided liquidity

price_at_which_we_provided_liquidity = tick_to_price(result["positions"][0]["tickLower"]["tickIdx"])

# get the loss

loss = (current_price - price_at_which_we_provided_liquidity) / price_at_which_we_provided_liquidity

# if the loss is greater than 50%, we need to trigger the recovery process

if loss > 0.5:
	print("Loss is greater than 50%, we need to trigger the recovery process")
else:
	print("Loss is less than 50%, we don't need to trigger the recovery process")


# print info about the position

print("Position ID: " + POSITION_ID)

print("Pool ID: " + result["positions"][0]["pool"]["id"])

print("Token 0: " + result["positions"][0]["token0"]["symbol"])

print("Token 1: " + result["positions"][0]["token1"]["symbol"])

print("Liquidity: " + str(result["positions"][0]["liquidity"]))

print("Tick lower: " + str(result["positions"][0]["tickLower"]["tickIdx"]))

print("Tick upper: " + str(result["positions"][0]["tickUpper"]["tickIdx"]))

print("Current tick: " + str(current_tick))

print("Current price: " + str(current_price))

print("Price at which we provided liquidity: " + str(price_at_which_we_provided_liquidity))

print("Loss: " + str(loss))

# get the web3 instance

w3 = Web3(Web3.HTTPProvider(INFURA_URL))



# get the contract ABI

abi = requests.get(UNISWAP_V3_LP_EXITING_FUNCTION_ADDRESS).json()

# get the contract

contract = w3.eth.contract(address=UNISWAP_V3_LP_EXITING_FUNCTION_ADDRESS, abi=abi)

# get the nonce

nonce = w3.eth.getTransactionCount(WALLET_ADDRESS)

# get the gas price

gas_price = w3.eth.gasPrice

# get the gas limit

gas_limit = contract.functions.exitPosition(POSITION_ID).estimateGas()

# get the transaction

tx = contract.functions.exitPosition(POSITION_ID).buildTransaction({
	'chainId': CHAIN_ID,
	'gas': gas_limit,
	'gasPrice': gas_price,
	'nonce': nonce
})

# sign the transaction

signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)	

# send the transaction

tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)

# get the transaction receipt

tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

print(tx_receipt)


# Exiting a position

# The Uniswap V3 LP exiting function is a smart contract that wraps around Uniswap V3's LP exiting function. It is deployed on the Ethereum mainnet at 0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8.

# The function that we need to call is exitPosition. It takes a single parameter, which is the position ID.

# The position ID is the hash of the pool ID, the tick lower and the tick upper. It is a 32 bytes value.

# The pool ID is the hash of the token0 address and the token1 address. It is a 32 bytes value.

# The tick lower and the tick upper are 32 bytes values.

# The position ID is a 96 bytes value.








































































