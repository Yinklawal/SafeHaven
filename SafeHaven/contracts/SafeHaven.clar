;; Project name: SafeHaven Insurance Protocol
;; Description: Decentralized smart contract enabling coverage purchases, claim submissions, and fund management

;; Constants - Error Codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-CLAIM-EXCEEDS-COVERAGE (err u102))
(define-constant ERR-TRANSFER-FAILED (err u103))
(define-constant ERR-POLICY-NOT-FOUND (err u104))
(define-constant ERR-INVALID-PARAMETERS (err u105))

;; Constants - System Parameters
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-COVERAGE-AMOUNT u1000000000) ;; 1 billion microSTX
(define-constant MAX-POLICY-DURATION u52560) ;; ~1 year in blocks (assuming 10min blocks)
(define-constant MIN-PREMIUM-AMOUNT u1000) ;; 1000 microSTX minimum

;; Data Structures
;; Policy registry - tracks active insurance policies
(define-map insurance-policies
    principal
    {
        coverage-amount: uint,
        premium-paid: uint,
        expiration-block: uint
    })

;; Claims registry - tracks submitted and processed claims
(define-map insurance-claims
    principal
    {
        claim-amount: uint,
        is-processed: bool
    })

;; Global State Variables
(define-data-var total-pool-balance uint u0)

;; Administrative Functions
;; Initialize a new insurance policy (admin only)
(define-public (create-admin-policy (coverage-value uint) (premium-cost uint) (duration-blocks uint))
    (let ((policy-expiration (+ stacks-block-height duration-blocks)))
        (begin
            ;; Verify admin authorization
            (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
            
            ;; Validate policy parameters
            (asserts! (<= coverage-value MAX-COVERAGE-AMOUNT) ERR-INVALID-PARAMETERS)
            (asserts! (>= premium-cost MIN-PREMIUM-AMOUNT) ERR-INVALID-PARAMETERS)
            (asserts! (<= duration-blocks MAX-POLICY-DURATION) ERR-INVALID-PARAMETERS)
            
            ;; Store policy details
            (map-set insurance-policies tx-sender
                {
                    coverage-amount: coverage-value,
                    premium-paid: premium-cost,
                    expiration-block: policy-expiration
                })
            (ok true))))

;; Public Functions
;; Purchase insurance coverage
(define-public (purchase-coverage (desired-coverage uint) (policy-duration uint))
    (let 
        ((premium-fee (* desired-coverage (/ u1 u100) policy-duration))
         (policy-expiration (+ stacks-block-height policy-duration)))
        (begin
            ;; Validate coverage parameters
            (asserts! (<= desired-coverage MAX-COVERAGE-AMOUNT) ERR-INVALID-PARAMETERS)
            (asserts! (<= policy-duration MAX-POLICY-DURATION) ERR-INVALID-PARAMETERS)
            (asserts! (>= premium-fee MIN-PREMIUM-AMOUNT) ERR-INVALID-PARAMETERS)
            
            ;; Prevent overflow in pool balance
            (asserts! (>= (+ (var-get total-pool-balance) premium-fee) (var-get total-pool-balance)) ERR-INVALID-AMOUNT)
            
            ;; Transfer premium to contract
            (try! (stx-transfer? premium-fee tx-sender (as-contract tx-sender)))
            
            ;; Update pool balance
            (var-set total-pool-balance (+ (var-get total-pool-balance) premium-fee))
            
            ;; Register new policy
            (map-set insurance-policies tx-sender
                {
                    coverage-amount: desired-coverage,
                    premium-paid: premium-fee,
                    expiration-block: policy-expiration
                })
            (ok true))))

;; Submit insurance claim
(define-public (submit-claim (requested-amount uint))
    (let 
        ((user-policy (unwrap! (map-get? insurance-policies tx-sender) ERR-POLICY-NOT-FOUND)))
        (begin
            ;; Verify claim doesn't exceed coverage
            (asserts! (<= requested-amount (get coverage-amount user-policy)) ERR-CLAIM-EXCEEDS-COVERAGE)
            
            ;; Process payout from contract to user
            (asserts! (is-ok (as-contract (stx-transfer? requested-amount tx-sender tx-sender))) ERR-TRANSFER-FAILED)
            
            ;; Update pool balance
            (var-set total-pool-balance (- (var-get total-pool-balance) requested-amount))
            
            ;; Record claim details
            (map-set insurance-claims tx-sender
                {
                    claim-amount: requested-amount,
                    is-processed: true
                })
            (ok true))))

;; Read-Only Query Functions
;; Get policy information for a specific user
(define-read-only (get-policy-info (user-address principal))
    (map-get? insurance-policies user-address))

;; Get claim information for a specific user
(define-read-only (get-claim-info (user-address principal))
    (map-get? insurance-claims user-address))

;; Get current total pool balance
(define-read-only (get-pool-balance)
    (var-get total-pool-balance))

;; Additional utility functions
;; Check if policy is still active
(define-read-only (is-policy-active (user-address principal))
    (match (map-get? insurance-policies user-address)
        policy-data (< stacks-block-height (get expiration-block policy-data))
        false))

;; Get remaining coverage for a user
(define-read-only (get-remaining-coverage (user-address principal))
    (match (map-get? insurance-policies user-address)
        policy-data 
            (match (map-get? insurance-claims user-address)
                claim-data (- (get coverage-amount policy-data) (get claim-amount claim-data))
                (get coverage-amount policy-data))
        u0))