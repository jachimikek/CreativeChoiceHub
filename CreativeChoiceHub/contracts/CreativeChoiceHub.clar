;; CollectiveChoiceHub - A decentralized decision-making contract
;; Allows stake holders to create and participate in collective decisions

;; Constants
(define-constant ERR-NOT-STAKE-HOLDER (err u1))
(define-constant ERR-INVALID-MOTION (err u2))
(define-constant ERR-DUPLICATE-MOTION (err u3))
(define-constant ERR-MOTION-NOT-FOUND (err u4))
(define-constant ERR-ALREADY-PARTICIPATED (err u5))
(define-constant ERR-INSUFFICIENT-STAKES (err u6))
(define-constant ERR-PARTICIPATION-CLOSED (err u7))
(define-constant ERR-CONSENSUS-NOT-MET (err u8))
(define-constant ERR-RESTRICTED (err u9))

;; Data variables
(define-data-var hub-steward principal tx-sender)
(define-data-var motion-count uint u0)
(define-data-var min-stakes-to-propose uint u100)
(define-data-var consensus-threshold uint u51)
(define-data-var deliberation-period uint u144) ;; ~24 hours in blocks
(define-data-var total-stakes uint u0)    ;; Track total stakes in circulation

;; Data maps
(define-map motions
    uint
    {
        heading: (string-ascii 50),
        context: (string-ascii 500),
        initiator: principal,
        start-block: uint,
        approvals: uint,
        rejections: uint,
        implemented: bool
    }
)

(define-map decisions
    {motion-id: uint, participant: principal}
    {decided: bool, approval: bool}
)

(define-map stake-ledger principal uint)

;; Read-only functions
(define-read-only (get-motion (motion-id uint))
    (map-get? motions motion-id)
)

(define-read-only (get-decision (motion-id uint) (participant principal))
    (map-get? decisions {motion-id: motion-id, participant: participant})
)

(define-read-only (get-stake-balance (address principal))
    (default-to u0 (map-get? stake-ledger address))
)

(define-read-only (get-total-stakes)
    (var-get total-stakes)
)

(define-read-only (get-hub-steward)
    (var-get hub-steward)
)

(define-read-only (is-deliberation-open (motion-id uint))
    (let (
        (motion (unwrap! (get-motion motion-id) false))
        (current-block block-height)
    )
    (<= current-block (+ (get start-block motion) (var-get deliberation-period)))
    )
)

;; Private functions
(define-private (check-motion-validity (heading (string-ascii 50)) (context (string-ascii 500)))
    (let (
        (caller tx-sender)
        (stake-balance (get-stake-balance caller))
    )
    (asserts! (>= stake-balance (var-get min-stakes-to-propose))
        ERR-INSUFFICIENT-STAKES)
    (asserts! (> (len heading) u0) ERR-INVALID-MOTION)
    (asserts! (> (len context) u0) ERR-INVALID-MOTION)
    (ok true))
)

;; Public functions
(define-public (create-motion (heading (string-ascii 50)) (context (string-ascii 500)))
    (let (
        (motion-id (+ (var-get motion-count) u1))
        (caller tx-sender)
    )
        ;; Validate motion
        (try! (check-motion-validity heading context))
        
        ;; Create new motion
        (map-set motions motion-id
            {
                heading: heading,
                context: context,
                initiator: caller,
                start-block: block-height,
                approvals: u0,
                rejections: u0,
                implemented: false
            }
        )
        
        ;; Increment motion count
        (var-set motion-count motion-id)
        (ok motion-id)
    )
)

(define-public (decide (motion-id uint) (approve bool))
    (let (
        (caller tx-sender)
        (stake-balance (get-stake-balance caller))
        (motion (unwrap! (get-motion motion-id) ERR-MOTION-NOT-FOUND))
        (previous-decision (get-decision motion-id caller))
    )
        ;; Validate decision conditions
        (asserts! (> stake-balance u0) ERR-INSUFFICIENT-STAKES)
        (asserts! (is-deliberation-open motion-id) ERR-PARTICIPATION-CLOSED)
        (asserts! (is-none previous-decision) ERR-ALREADY-PARTICIPATED)
        
        ;; Record decision
        (map-set decisions
            {motion-id: motion-id, participant: caller}
            {decided: true, approval: approve}
        )
        
        ;; Update decision counts
        (map-set motions motion-id
            (merge motion
                {
                    approvals: (if approve
                        (+ (get approvals motion) stake-balance)
                        (get approvals motion)
                    ),
                    rejections: (if approve
                        (get rejections motion)
                        (+ (get rejections motion) stake-balance)
                    )
                }
            )
        )
        
        (ok true)
    )
)

(define-public (implement-motion (motion-id uint))
    (let (
        (motion (unwrap! (get-motion motion-id) ERR-MOTION-NOT-FOUND))
        (total-decisions (+ (get approvals motion) (get rejections motion)))
        (consensus-requirement (* (var-get total-stakes) (var-get consensus-threshold)))
    )
        ;; Validate implementation conditions
        (asserts! (not (get implemented motion)) ERR-INVALID-MOTION)
        (asserts! (not (is-deliberation-open motion-id)) ERR-PARTICIPATION-CLOSED)
        (asserts! (>= (* total-decisions u100) consensus-requirement) ERR-CONSENSUS-NOT-MET)
        
        ;; Mark motion as implemented
        (map-set motions motion-id
            (merge motion {implemented: true})
        )
        
        (ok true)
    )
)

;; Administrative functions
(define-public (issue-stakes (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender (var-get hub-steward)) ERR-RESTRICTED)
        
        ;; Update recipient balance
        (let (
            (current-balance (get-stake-balance recipient))
        )
            ;; Set new balance
            (map-set stake-ledger
                recipient
                (+ current-balance amount)
            )
            
            ;; Update total stake supply
            (var-set total-stakes (+ (var-get total-stakes) amount))
            
            (ok true)
        )
    )
)

(define-public (update-deliberation-period (new-period uint))
    (begin
        (asserts! (is-eq tx-sender (var-get hub-steward)) ERR-RESTRICTED)
        (var-set deliberation-period new-period)
        (ok true)
    )
)

(define-public (transfer-stewardship (new-steward principal))
    (begin
        (asserts! (is-eq tx-sender (var-get hub-steward)) ERR-RESTRICTED)
        (var-set hub-steward new-steward)
        (ok true)
    )
)