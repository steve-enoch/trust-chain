# TrustChain Protocol

## Overview

**TrustChain** is an advanced decentralized trust scoring and identity verification protocol for participants in the **Bitcoin Layer 2 ecosystem**.
It establishes immutable, evolving trust profiles based on verified on-chain activity, enabling **reputation portability** across:

* **Lightning Network routing nodes**
* **Bitcoin-backed lending protocols**
* **Decentralized exchanges (DEXs)**
* **Layer 2 validation mechanisms**
* **Peer-to-peer Bitcoin transactions**

The protocol ensures participants’ trustworthiness without sacrificing **privacy**, **decentralization**, or **user sovereignty** over their identity and trust data.

---

## Key Innovations

* **Dynamic Trust Decay**: Periodic reduction of reputation scores to incentivize continuous participation.
* **Multi-Dimensional Scoring**: Configurable reputation actions with multipliers that reflect diverse ecosystem contributions.
* **Proof-of-Reputation Events**: Immutable audit trails for all score changes, backed by on-chain data.
* **Interoperability**: Compatible with Bitcoin Layer 2 protocols, providing a unified trust framework across multiple environments.
* **User Sovereignty**: Identities are user-controlled and portable across applications.

---

## System Overview

The TrustChain Protocol consists of three core layers:

1. **Identity Registry**
   Each participant creates a decentralized identity (DID) mapped to a reputation score.

   * Identities contain metadata such as reputation score, creation timestamp, update history, and status.
   * Identities can be enabled/disabled by the owner.

2. **Reputation Actions**
   Actions represent **ecosystem contributions** or **trustworthy behaviors** (e.g., successful Lightning routing, loan repayment).

   * Each action type is configurable with a multiplier and description.
   * Contract admins can add, update, or deactivate actions.

3. **Reputation History (Audit Trail)**
   Every reputation update, including **positive actions** or **automatic decay**, is immutably logged.

   * Provides transparency for third-party verification.
   * Enables trust portability across multiple platforms.

---

## Contract Architecture

### Administrative Controls

* **Contract Ownership**: Admin can transfer ownership.
* **System Activation**: Enable/disable contract activity globally.
* **Decay Configuration**: Adjustable decay rate (%) and decay period (blocks).
* **Starting Reputation**: Configurable baseline for new identities.

### Identity Lifecycle

* `create-identity` → Register a DID with a starting reputation score.
* `update-identity-status` → Enable/disable identity.
* `decay-reputation` → Manually trigger reputation decay if decay period elapsed.

### Reputation Management

* `update-reputation-score` → Award reputation points for verified actions.
* `decay-reputation-internal` → Internal time-based decay applied automatically before updates.
* **Cap Enforcement**: Reputation scores cannot exceed `MAX-REPUTATION-SCORE`.

### Data Structures

* **`identities`** → Mapping of principal → identity profile.
* **`reputation-actions`** → Mapping of action type → multiplier & metadata.
* **`reputation-history`** → Mapping of (owner, tx-id) → score change event.

---

## Data Flow

```mermaid
flowchart TD
    A[Identity Creation] --> B[Identity Registry]
    B --> C[Reputation Actions]
    C --> D[Reputation Update]
    D --> E[Reputation History (Audit Trail)]
    E --> F[Verification & Queries]
    F --> G[External Protocols (Lightning, DeFi, DEXs)]
    
    subgraph Decay Mechanism
        H[Decay Parameters] --> D
    end
```

1. **User registers** identity (`create-identity`).
2. **Reputation Actions** are executed (`update-reputation-score`).
3. **Decay Mechanism** reduces scores over time.
4. **Audit Trail** logs all score changes immutably.
5. **Verification** queries provide trust proofs to external protocols.

---

## Read-Only Queries

* `get-reputation` → Fetch current reputation score.
* `get-full-identity` → Retrieve identity profile.
* `verify-reputation` → Check if identity meets minimum threshold.
* `get-reputation-action` → Fetch action configuration.
* `get-reputation-history` → Retrieve past reputation events.
* `get-contract-parameters` → View contract configuration.

---

## Default Reputation Actions

The contract bootstraps with predefined actions relevant to Bitcoin Layer 2:

* **Lightning Routing**: `multiplier = 8`
* **BTC Loan Repayment**: `multiplier = 12`
* **Layer 2 Validation**: `multiplier = 6`
* **Channel Maintenance**: `multiplier = 4`
* **Protocol Governance**: `multiplier = 7`

---

## Deployment Notes

* Contract automatically initializes with standard reputation actions.
* Admin must manage **decay parameters**, **starting reputation**, and **custom actions** according to ecosystem needs.
* Designed to be modular and extensible for future Bitcoin Layer 2 integrations.

---

## Example Use Cases

* **Lightning Network Nodes**: Build trust routing based on uptime and successful payments.
* **DeFi Protocols**: Verify borrower trustworthiness for BTC-collateralized loans.
* **DEXs**: Enforce minimum trust scores for liquidity providers or traders.
* **DAOs & Governance**: Weight proposals/votes by participant trust level.

---

## License

This protocol is released under the **MIT License**.
