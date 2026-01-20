from web3 import Web3
import sys
import os
from eth_hash.auto import keccak
from concurrent.futures import ThreadPoolExecutor, as_completed

# -------------------------------
# Configuration
# -------------------------------

try:
    RPC_URL = os.environ['RPC_URL']
    print(f"RPC_URL environment variable: {RPC_URL}")
except KeyError:
    print("RPC_URL environment variable not set.")
    os.exit(1)

try:
    DISPUTE_GAME_FACTORY = os.environ['DISPUTE_GAME_FACTORY']
    print(f"DISPUTE_GAME_FACTORY environment variable: {DISPUTE_GAME_FACTORY}")
except KeyError:
    print("DISPUTE_GAME_FACTORY environment variable not set.")
    os.exit(1)

try:
    L2_DIVERGENCE_BLOCK_NUMBER = int(os.environ['L2_DIVERGENCE_BLOCK_NUMBER'])
    print(f"L2_DIVERGENCE_BLOCK_NUMBER environment variable: {L2_DIVERGENCE_BLOCK_NUMBER}")
except KeyError:
    print("L2_DIVERGENCE_BLOCK_NUMBER environment variable not set.")
    os.exit(1)

# The storage slot index where the array is stored (integer)
ARRAY_SLOT = 104

# Number of elements to fetch (optional limit if you don’t want to fetch all)
MAX_ELEMENTS = 100

abi = [
    {
        "inputs": [],
        "name": "l2BlockNumber",
        "outputs": [{"internalType": "uint256", "name": "l2SequenceNumber_", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]

# -------------------------------
# Setup Web3
# -------------------------------

w3 = Web3(Web3.HTTPProvider(RPC_URL))

if not w3.is_connected():
    print("Failed to connect to the Ethereum node.")
    sys.exit(1)

# -------------------------------
# Helper functions
# -------------------------------

def keccak256(value: bytes) -> bytes:
    """Compute keccak256 hash of given bytes."""
    return keccak(value)

def get_storage_at(address, slot):
    """Read raw 32-byte storage value from the given slot."""
    return w3.eth.get_storage_at(address, slot)

def read_dispute_game_addresses(address, base_slot, max_elements=None, max_workers=10):
    """
    Reads a dynamic array of addresses from storage in parallel threads.
    """
    # 1️⃣ Read array length
    length_data = get_storage_at(address, base_slot)
    length = int.from_bytes(length_data, byteorder="big")
    print(f"Total number of dispute games: {length}")

    if max_elements:
        length = min(length, max_elements)

    # 2️⃣ Compute starting slot for elements: keccak256(p)
    base_hash = keccak256(base_slot.to_bytes(32, byteorder="big"))
    base_int = int.from_bytes(base_hash, byteorder="big")

    # 3️⃣ Prepare list of slots to read
    slots = [base_int + i for i in range(length)]

    # 4️⃣ Worker function for fetching a single address
    def fetch_address(i, slot):
        value_bytes = get_storage_at(address, slot)
        value_int = int.from_bytes(value_bytes, byteorder="big")
        addr_hex = hex(value_int)[2:].rjust(64, "0")[-40:]
        return i, Web3.to_checksum_address("0x" + addr_hex)

    # 5️⃣ Launch parallel reads
    addresses = [None] * length
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(fetch_address, i, slot) for i, slot in enumerate(slots)]
        for future in as_completed(futures):
            i, addr = future.result()
            addresses[i] = addr
            print(f"Dispute Game Address [{i}]: {addr}")

    return addresses

def filter_dispute_game_addresses_by_l2_divergence_block_number(addresses, l2_divergence_block_number, max_workers=10):
    # 1️⃣ Worker function to fetch the l2 block number of a dispute game
    def fetch_l2_block_number(i, DISPUTE_GAME_FACTORY):
        contract = w3.eth.contract(address=DISPUTE_GAME_FACTORY, abi=abi)
        l2_block_number = contract.functions.l2BlockNumber().call()
        return i, DISPUTE_GAME_FACTORY, l2_block_number


    # 2️⃣ Launch parallel reads
    filtered_address = [None] * len(addresses)
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [executor.submit(fetch_l2_block_number, i, DISPUTE_GAME_FACTORY) for i, DISPUTE_GAME_FACTORY in enumerate(addresses)]
        for future in as_completed(futures):
            i, DISPUTE_GAME_FACTORY, l2_block_number = future.result()
            filtered_address[i] = (DISPUTE_GAME_FACTORY, l2_block_number)
            print(f"Dispute Game L2 Block Number: [{i}] {l2_block_number}")

    filtered_address = [x[0] for x in filtered_address if x is not None and x[1] >= l2_divergence_block_number]
    return filtered_address

def array_to_comma_seperated_string(array):
    return ",".join(array)

# -------------------------------
# Run
# -------------------------------
if __name__ == "__main__":
    print(f"Reading array from contract {DISPUTE_GAME_FACTORY} at slot {ARRAY_SLOT}...")
    addresses = read_dispute_game_addresses(DISPUTE_GAME_FACTORY, ARRAY_SLOT, max_elements=None)
    addresses = filter_dispute_game_addresses_by_l2_divergence_block_number(addresses, L2_DIVERGENCE_BLOCK_NUMBER)

    print(f"\nFound {len(addresses)} dispute game addresses.")
    print(f"\nADDRESSES_TO_BLACKLIST={array_to_comma_seperated_string(addresses)}")
