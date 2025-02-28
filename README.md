# CollectiveChoiceHub

CollectiveChoiceHub is a decentralized decision-making smart contract that allows stakeholders to create and participate in collective decisions through voting mechanisms. It ensures transparency, consensus-based governance, and stake-based participation.

## Features
- **Stake-Based Governance**: Only stakeholders with sufficient stakes can propose motions.
- **Proposal System**: Stakeholders can create new motions for collective decision-making.
- **Voting Mechanism**: Participants can approve or reject motions based on their stake holdings.
- **Consensus Enforcement**: Motions require a defined threshold of approval to be implemented.
- **Stake Management**: Administrators can issue stakes, influencing governance power.
- **Administrative Functions**: Stewardship transfer, deliberation period adjustment, and stake issuance.

## Smart Contract Components

### Constants
- Various error codes (e.g., `ERR-NOT-STAKE-HOLDER`, `ERR-INSUFFICIENT-STAKES`) ensure transaction validity.

### Data Variables
- `hub-steward`: The contract administrator.
- `motion-count`: Tracks the number of motions created.
- `min-stakes-to-propose`: Minimum stakes required to create a motion.
- `consensus-threshold`: Minimum approval percentage required for consensus.
- `deliberation-period`: The duration within which voting is open.
- `total-stakes`: Total stakes issued within the system.

### Data Maps
- `motions`: Stores details of each motion.
- `decisions`: Records votes cast by participants.
- `stake-ledger`: Tracks the stake balance of participants.

## Functionality

### Read-Only Functions
- `get-motion(motion-id)`: Retrieves motion details.
- `get-decision(motion-id, participant)`: Retrieves a participant's decision on a motion.
- `get-stake-balance(address)`: Returns the stake balance of an address.
- `get-total-stakes()`: Retrieves total issued stakes.
- `get-hub-steward()`: Returns the steward of the contract.
- `is-deliberation-open(motion-id)`: Checks if a motion is still open for voting.

### Public Functions
- `create-motion(heading, context)`: Creates a new motion.
- `decide(motion-id, approve)`: Allows stakeholders to vote on motions.
- `implement-motion(motion-id)`: Implements a motion if consensus is met.
- `issue-stakes(amount, recipient)`: Issues new stakes to participants.
- `update-deliberation-period(new-period)`: Updates the deliberation period.
- `transfer-stewardship(new-steward)`: Transfers stewardship to another principal.

## How It Works
1. **Stakeholders obtain stakes** issued by the contract steward.
2. **Motions are created** by stakeholders with sufficient stakes.
3. **Voting occurs** within the deliberation period.
4. **If consensus is met**, motions are implemented.
5. **Stewardship and governance parameters** can be adjusted by the steward.

## Installation & Deployment
To deploy this contract, use a suitable Clarity smart contract environment, such as Stacks blockchain tools.

## License
This project is licensed under the MIT License.

