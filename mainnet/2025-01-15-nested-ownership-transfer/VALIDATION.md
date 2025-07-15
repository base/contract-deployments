# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### CB Signer Safe: `0x9855054731540A48b28990B63DcF4f33d8AE46A1`
>
> - Domain Hash: `0x88aac3dc27cc1618ec43a87b3df21482acd24d172027ba3fbb5a5e625d895a0b`
> - Message Hash: `0x6d94fb1830256047147a93745f0826cac47380b7c57a32625b1259e8a3f8e27c`

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Task State Overrides

### CB Signer Safe (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

- **Raw Slot**: `0x0000000000000000000000000000000000000000000000000000000000000004`
  **Value**: `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning**: Overrides the threshold to 1 so the simulation can occur.

## Task State Changes

### CB Signer Safe (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`)

- **Raw Slot**: `0x0000000000000000000000000000000000000000000000000000000000000003` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000006` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000002` \
  **Value Type**: uint256 \
  **Decoded Old Value**: 6 \
  **Decoded New Value**: 2 \
  **Meaning**: Updates the owner count.

- **Raw Slot**: `0x0000000000000000000000000000000000000000000000000000000000000004` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000001` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000002` \
  **Value Type**: uint256 \
  **Decoded Old Value**: 1 \
  **Decoded New Value**: 2 \
  **Meaning**: Updates the safe's signing threshold. The previous value is actually 3, but the state diff presents this way because of the state override above.

- **Raw Slot**: `0x0000000000000000000000000000000000000000000000000000000000000005` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000014` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000015` \
  **Value Type**: uint256 \
  **Decoded Old Value**: 20 \
  **Decoded New Value**: 21 \
  **Meaning**: Nonce increment.

- **Raw Slot**: `0x1772a703ae675a1daf302df5578a40ec15df2da0f370aaae76c24b3dc3cf5a82` \
  **Raw Old Value**: `0x0000000000000000000000003cd692ece8b6573a2220ae00d0deb98f0dffa9a1` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0x3cd692eCE8b6573A2220ae00d0dEb98f0DfFA9a1` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0x6CD3850756b7894774Ab715D136F9dD02837De50` from the owners linked list. Confirm the storage key with `cast index address 0x6CD3850756b7894774Ab715D136F9dD02837De50 2`.

- **Raw Slot**: `0x46b3491a8cd829af805c1f7fb76736ca5fd88e02a78fcec356aaa2b41bf599db` \
  **Raw Old Value**: `0x0000000000000000000000003dad2200849925bb46d9bf05afa5f7f213f4c18e` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0x5FbEFA105bbd53b43bf537Cbc5cD30804Dd0c993` from the owners linked list. Confirm the storage key with `cast index address 0x5FbEFA105bbd53b43bf537Cbc5cD30804Dd0c993 2`.

- **Raw Slot**: `0x758f7362f1c252e82fc720287a93c81366f743607812809705593fe1d7c3853f` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000001` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0x0000000000000000000000000000000000000001` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0xf9e320f3dA12E68af219d9E2A490Dd649f6B177c` from the owners linked list. Confirm the storage key with `cast index address 0xf9e320f3dA12E68af219d9E2A490Dd649f6B177c 2`.

- **Raw Slot**: `0xc2eb038642409cacb7427667d194e7ffc6322f605a293c3088ea50e7387c0be8` \
  **Raw Old Value**: `0x000000000000000000000000b011a32ed8b4f70d9943a2199f539bbecd7b62f7` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0xB011a32ED8b4F70D9943A2199F539bbeCd7b62F7` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E` from the owners linked list. Confirm the storage key with `cast index address 0x3Dad2200849925Bb46d9bF05aFa5f7F213F4c18E 2`.

- **Raw Slot**: `0xc68c82056a4782e6920506248dec06b7949eabf81d66a13e5e8ec70d4e8f4b13` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Raw New Value**: `0x0000000000000000000000009c4a57feb77e294fd7bf5ebe9ab01caa0a90a110` \
  **Value Type**: address \
  **Decoded Old Value**: `0x0000000000000000000000000000000000000000` \
  **Decoded New Value**: `0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110` \
  **Meaning**: Adds `0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd` to the owners linked list. Confirm the storage key with `cast index address 0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd 2`.

- **Raw Slot**: `0xdaf8a00b5bed19da86efcb9f47bb7ded536a0ee70f1c43b062cb09e630709778` \
  **Raw Old Value**: `0x000000000000000000000000f9e320f3da12e68af219d9e2a490dd649f6b177c` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0xf9e320f3dA12E68af219d9E2A490Dd649f6B177c` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0xB011a32ED8b4F70D9943A2199F539bbeCd7b62F7` from the owners linked list. Confirm the storage key with `cast index address 0xB011a32ED8b4F70D9943A2199F539bbeCd7b62F7 2`.

- **Raw Slot**: `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` \
  **Raw Old Value**: `0x0000000000000000000000006cd3850756b7894774ab715d136f9dd02837de50` \
  **Raw New Value**: `0x00000000000000000000000020acf55a3dcfe07fc4cecacfa1628f788ec8a4dd` \
  **Value Type**: address \
  **Decoded Old Value**: `0x6CD3850756b7894774Ab715D136F9dD02837De50` \
  **Decoded New Value**: `0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd` \
  **Meaning**: Sets the updated head of the owners linked list to `0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`. Confirm storage key with `cast index address 0x0000000000000000000000000000000000000001 2`.

- **Raw Slot**: `0xf2703bf6aed371ed0006c3f1370d925046c90122272e607d356ede2c94165357` \
  **Raw Old Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000001` \
  **Value Type**: address \
  **Decoded Old Value**: `0x0000000000000000000000000000000000000000` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000001` \
  **Meaning**: Sets the updated tail of the owners linked list to `0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`. Confirm storage key with `cast index address 0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110 2`.

- **Raw Slot**: `0xf50027dc233102bb13bb30a38326315505fe2452eaf2e2f78f1c0da0084d86c4` \
  **Raw Old Value**: `0x0000000000000000000000005fbefa105bbd53b43bf537cbc5cd30804dd0c993` \
  **Raw New Value**: `0x0000000000000000000000000000000000000000000000000000000000000000` \
  **Value Type**: address \
  **Decoded Old Value**: `0x5FbEFA105bbd53b43bf537Cbc5cD30804Dd0c993` \
  **Decoded New Value**: `0x0000000000000000000000000000000000000000` \
  **Meaning**: Removes `0x3cd692eCE8b6573A2220ae00d0dEb98f0DfFA9a1` from the owners linked list. Confirm the storage key with `cast index address 0x3cd692eCE8b6573A2220ae00d0dEb98f0DfFA9a1 2`.

### Your Signer Address

- Nonce increment
