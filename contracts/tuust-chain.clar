;; Title: TrustChain Protocol
;; Summary: Advanced decentralized trust scoring and identity verification
;;          system built for Bitcoin Layer 2 ecosystem participants
;; Description: TrustChain establishes a revolutionary framework for measuring
;;              and tracking participant reliability across Bitcoin's Layer 2
;;              networks. This protocol creates immutable trust profiles that
;;              evolve based on verified on-chain activities, enabling seamless
;;              reputation portability across DeFi protocols, Lightning Network
;;              interactions, and peer-to-peer Bitcoin transactions.
;;              
;;              Key innovations include dynamic trust decay algorithms, 
;;              multi-dimensional scoring mechanisms, and cryptographic proof
;;              of reputation events. Designed for maximum interoperability
;;              with existing Bitcoin infrastructure while maintaining complete
;;              decentralization and user sovereignty over their trust data.
;;              
;;              Perfect for Lightning Network routing nodes, Bitcoin-backed
;;              lending protocols, decentralized exchanges, and any application
;;              requiring verified participant trustworthiness without
;;              compromising privacy or decentralization principles.

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMETERS (err u101))
(define-constant ERR-IDENTITY-EXISTS (err u102))
(define-constant ERR-IDENTITY-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u104))
(define-constant ERR-MAX-REPUTATION-REACHED (err u105))
(define-constant ERR-ACTION-EXISTS (err u106))
(define-constant ERR-ACTION-NOT-FOUND (err u107))
(define-constant ERR-NOT-ADMIN (err u108))
(define-constant ERR-NOT-ACTIVE (err u109))

;; SYSTEM CONSTANTS

(define-constant MAX-REPUTATION-SCORE u1000)
(define-constant MIN-REPUTATION-SCORE u0)
(define-constant DEFAULT-STARTING-REPUTATION u50)
(define-constant DEFAULT-DECAY-RATE u10) ;; 10% decay per period
(define-constant MINIMUM_DID_LENGTH u5)

;; STATE VARIABLES

(define-data-var contract-owner principal tx-sender)
(define-data-var contract-active bool true)
(define-data-var decay-rate uint DEFAULT-DECAY-RATE)
(define-data-var decay-period uint u10000) ;; In blocks
(define-data-var starting-reputation uint DEFAULT-STARTING-REPUTATION)

;; DATA STRUCTURES

;; Core identity registry mapping principals to their trust profiles
(define-map identities
  { owner: principal }
  {
    did: (string-ascii 50), ;; Decentralized Identity
    reputation-score: uint,
    created-at: uint,
    last-updated: uint,
    last-decay: uint,
    total-actions: uint,
    active: bool,
  }
)

;; Configurable trust action types and their scoring multipliers
(define-map reputation-actions
  { action-type: (string-ascii 50) }
  {
    multiplier: uint,
    description: (string-ascii 100),
    active: bool,
  }
)

;; Comprehensive audit trail for all trust score changes
(define-map reputation-history
  {
    owner: principal,
    tx-id: uint,
  }
  {
    action-type: (string-ascii 50),
    previous-score: uint,
    new-score: uint,
    timestamp: uint,
    block-height: uint,
  }
)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer contract ownership to a new principal
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    ;; Validate new owner is not the same as current owner
    (asserts! (not (is-eq new-owner (var-get contract-owner)))
      (err ERR-INVALID-PARAMETERS)
    )
    ;; Validate new owner is not the zero principal
    (asserts! (not (is-eq new-owner 'ST000000000000000000002AMW42H))
      (err ERR-INVALID-PARAMETERS)
    )
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; Enable or disable the entire contract system
(define-public (set-contract-active (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (var-set contract-active active)
    (ok true)
  )
)

;; Configure reputation decay parameters for temporal score reduction
(define-public (set-decay-parameters
    (new-rate uint)
    (new-period uint)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (<= new-rate u100) (err ERR-INVALID-PARAMETERS))
    (asserts! (> new-period u0) (err ERR-INVALID-PARAMETERS))
    (var-set decay-rate new-rate)
    (var-set decay-period new-period)
    (ok true)
  )
)

;; Set the initial reputation score for newly created identities
(define-public (set-starting-reputation (new-value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    ;; Validate new-value is within acceptable range
    (asserts! (>= new-value MIN-REPUTATION-SCORE) (err ERR-INVALID-PARAMETERS))
    (asserts! (<= new-value MAX-REPUTATION-SCORE) (err ERR-INVALID-PARAMETERS))
    (var-set starting-reputation new-value)
    (ok true)
  )
)

;; REPUTATION ACTION MANAGEMENT

;; Register a new reputation-earning action type with scoring multiplier
(define-public (add-reputation-action
    (action-type (string-ascii 50))
    (multiplier uint)
    (description (string-ascii 100))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    ;; Validate action-type is not empty
    (asserts! (> (len action-type) u0) (err ERR-INVALID-PARAMETERS))
    ;; Validate multiplier is reasonable (0-100 range)
    (asserts! (<= multiplier u100) (err ERR-INVALID-PARAMETERS))
    ;; Validate description is not empty
    (asserts! (> (len description) u0) (err ERR-INVALID-PARAMETERS))
    ;; Check action doesn't already exist
    (asserts!
      (is-none (map-get? reputation-actions { action-type: action-type }))
      (err ERR-ACTION-EXISTS)
    )
    (map-set reputation-actions { action-type: action-type } {
      multiplier: multiplier,
      description: description,
      active: true,
    })
    (ok true)
  )
)

;; Modify existing reputation action parameters and status
(define-public (update-reputation-action
    (action-type (string-ascii 50))
    (multiplier uint)
    (description (string-ascii 100))
    (active bool)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    ;; Validate action-type is not empty
    (asserts! (> (len action-type) u0) (err ERR-INVALID-PARAMETERS))
    ;; Validate multiplier is reasonable (0-100 range)
    (asserts! (<= multiplier u100) (err ERR-INVALID-PARAMETERS))
    ;; Validate description is not empty
    (asserts! (> (len description) u0) (err ERR-INVALID-PARAMETERS))
    ;; Check action exists
    (asserts!
      (is-some (map-get? reputation-actions { action-type: action-type }))
      (err ERR-ACTION-NOT-FOUND)
    )
    (map-set reputation-actions { action-type: action-type } {
      multiplier: multiplier,
      description: description,
      active: active,
    })
    (ok true)
  )
)

;; Bootstrap the contract with standard Bitcoin ecosystem reputation actions
(define-public (initialize-reputation-actions)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (map-set reputation-actions { action-type: "lightning-routing" } {
      multiplier: u8,
      description: "Successful Lightning Network payment routing",
      active: true,
    })
    (map-set reputation-actions { action-type: "btc-lending-repay" } {
      multiplier: u12,
      description: "Timely repayment of Bitcoin-collateralized loans",
      active: true,
    })
    (map-set reputation-actions { action-type: "layer2-validation" } {
      multiplier: u6,
      description: "Participation in Layer 2 consensus validation",
      active: true,
    })
    (map-set reputation-actions { action-type: "channel-maintenance" } {
      multiplier: u4,
      description: "Maintaining healthy Lightning Network channels",
      active: true,
    })
    (map-set reputation-actions { action-type: "protocol-governance" } {
      multiplier: u7,
      description: "Active participation in protocol governance",
      active: true,
    })
    (ok true)
  )
)

;; HELPER FUNCTIONS

;; Validate that a principal has a registered identity and is the transaction sender
(define-private (is-valid-owner (owner principal))
  (and
    (is-some (map-get? identities { owner: owner }))
    (is-eq owner tx-sender)
  )
)

;; Create immutable audit trail entry for reputation score changes
(define-private (log-reputation-change
    (owner principal)
    (action-type (string-ascii 50))
    (previous-score uint)
    (new-score uint)
  )
  (map-set reputation-history {
    owner: owner,
    tx-id: stacks-block-height,
  } {
    action-type: action-type,
    previous-score: previous-score,
    new-score: new-score,
    timestamp: burn-block-height,
    block-height: stacks-block-height,
  })
)