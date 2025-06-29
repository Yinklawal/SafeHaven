# SafeHaven Insurance Protocol

SafeHaven Insurance Protocol provides a decentralized alternative to traditional insurance by leveraging smart contracts to automate policy creation, premium collection, and claim processing. The protocol maintains a shared pool of funds that users contribute to through premium payments and can withdraw from through validated claims.

## Features

- **Decentralized Coverage**: Purchase insurance policies without intermediaries
- **Automated Claims**: Submit and process claims through smart contract logic
- **Transparent Pool Management**: All fund movements are recorded on-chain
- **Flexible Policy Terms**: Customizable coverage amounts and durations
- **Administrative Controls**: Contract owner can create special admin policies

## Contract Architecture

### Core Components

1. **Policy Management**: Tracks active insurance policies with coverage amounts, premiums, and expiration dates
2. **Claims Processing**: Handles claim submissions and payouts
3. **Fund Pool**: Manages the shared insurance fund pool
4. **Access Control**: Ensures proper authorization for administrative functions

### Data Structures

- `insurance-policies`: Maps user addresses to their policy details
- `insurance-claims`: Tracks submitted and processed claims
- `total-pool-balance`: Global variable maintaining the current fund pool balance

## Functions

### Public Functions

#### `purchase-coverage(desired-coverage, policy-duration)`
Purchase an insurance policy by paying a premium based on coverage amount and duration.

**Parameters:**
- `desired-coverage` (uint): Amount of coverage desired in microSTX
- `policy-duration` (uint): Policy duration in blocks

**Returns:** `(ok true)` on success

#### `submit-claim(requested-amount)`
Submit an insurance claim for a covered amount.

**Parameters:**
- `requested-amount` (uint): Amount to claim in microSTX

**Returns:** `(ok true)` on successful payout

### Administrative Functions

#### `create-admin-policy(coverage-value, premium-cost, duration-blocks)`
Create a special administrative policy (contract owner only).

**Parameters:**
- `coverage-value` (uint): Coverage amount in microSTX
- `premium-cost` (uint): Premium amount in microSTX
- `duration-blocks` (uint): Policy duration in blocks

### Read-Only Functions

#### `get-policy-info(user-address)`
Retrieve policy information for a specific user.

#### `get-claim-info(user-address)`
Get claim details for a specific user.

#### `get-pool-balance()`
Get the current total balance of the insurance pool.

#### `is-policy-active(user-address)`
Check if a user's policy is still active (not expired).

#### `get-remaining-coverage(user-address)`
Calculate remaining coverage after any claims have been processed.

## Constants and Limits

- **Maximum Coverage**: 1 billion microSTX
- **Maximum Policy Duration**: ~1 year (52,560 blocks)
- **Minimum Premium**: 1,000 microSTX
- **Premium Calculation**: Based on coverage amount and duration

## Error Codes

- `ERR-UNAUTHORIZED (u100)`: Unauthorized access attempt
- `ERR-INVALID-AMOUNT (u101)`: Invalid amount specified
- `ERR-CLAIM-EXCEEDS-COVERAGE (u102)`: Claim amount exceeds policy coverage
- `ERR-TRANSFER-FAILED (u103)`: STX transfer operation failed
- `ERR-POLICY-NOT-FOUND (u104)`: No policy found for user
- `ERR-INVALID-PARAMETERS (u105)`: Invalid function parameters

## Usage Examples

### Purchasing Coverage

```clarity
;; Purchase 100,000 microSTX coverage for 1000 blocks
(contract-call? .safehaven-insurance purchase-coverage u100000 u1000)
```

### Submitting a Claim

```clarity
;; Claim 50,000 microSTX from your policy
(contract-call? .safehaven-insurance submit-claim u50000)
```

### Checking Policy Status

```clarity
;; Check if your policy is still active
(contract-call? .safehaven-insurance is-policy-active 'SP1234...ABCD)
```

## Security Considerations

1. **Access Control**: Only the contract owner can create administrative policies
2. **Overflow Protection**: Premium additions include overflow checks
3. **Validation**: All inputs are validated against defined limits
4. **Policy Verification**: Claims are validated against existing policy coverage
5. **Fund Management**: Pool balance is carefully tracked and updated

## Deployment

1. Deploy the contract to the Stacks blockchain
2. The deploying address becomes the contract owner
3. Users can immediately begin purchasing coverage
4. The contract owner can create administrative policies as needed

## Technical Requirements

- **Blockchain**: Stacks
- **Language**: Clarity
- **Token**: STX (microSTX denomination)
- **Block Time**: ~10 minutes (assumed for duration calculations)

## Limitations

- Claims are processed automatically without external validation
- No dispute resolution mechanism
- Single pool model without risk segregation
- Limited to STX token transactions

## Contributing

This is a basic insurance protocol implementation. Consider the following for production use:

- Add external claim validation mechanisms
- Implement actuarial pricing models
- Add multi-signature controls for large payouts
- Include dispute resolution processes
- Add policy renewal capabilities
