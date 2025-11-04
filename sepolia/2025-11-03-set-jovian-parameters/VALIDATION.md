# Validation

## State Changes

Please verify that the following state changes (and none others) are made to the SystemConfig contract.

### SystemConfig State Changes

**Contract Address:** `0xf272670eb55e895584501d564AfEB048bEd26194` (SystemConfig Proxy)

#### 1. DA Footprint Gas Scalar Update

- **Storage Slot:** Check for `daFootprintGasScalar` storage slot
- **Old Value:** `<current value on-chain>`
- **New Value:** `260` (0x0104)
- **Summary:** Updates DA footprint gas scalar to 260

#### 2. Min Base Fee Update

- **Storage Slot:** Check for `minBaseFee` storage slot
- **Old Value:** `<current value on-chain>`
- **New Value:** `5000000` (0x4C4B40)
- **Summary:** Updates minimum base fee to 5,000,000 wei

### Additional Changes

**Nonce Updates:**
- The Owner Safe (`0x0fe884546476dDd290eC46318785046ef68a0BA9`) nonce will increment

### Validation Checklist

- [ ] SystemConfig contract address matches `0xf272670eb55e895584501d564AfEB048bEd26194`
- [ ] DA footprint gas scalar changes to `260`
- [ ] Min base fee changes to `5000000`
- [ ] No other unexpected state changes occur
- [ ] Owner Safe nonce increments by 1
