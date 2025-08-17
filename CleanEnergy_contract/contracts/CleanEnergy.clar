
;; title: CleanEnergy
;; version: 1.0.0
;; summary: Synthetic Assets Smart Contract for Clean Energy and Renewable Tech Exposure
;; description: This contract creates synthetic exposure to traditional assets in the renewable energy and clean tech sector.
;;              Users can mint synthetic tokens backed by collateral that track clean energy asset performance.

;; traits
;; SIP-010 trait implementation (functions implemented below)

;; token definitions
(define-fungible-token clean-energy-token)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-ORACLE-NOT-AUTHORIZED (err u105))
(define-constant ERR-PRICE-TOO-OLD (err u106))
(define-constant ERR-POSITION-NOT-FOUND (err u107))
(define-constant ERR-LIQUIDATION-THRESHOLD-NOT-MET (err u108))

;; Token metadata constants
(define-constant TOKEN-NAME "CleanEnergy Synthetic Token")
(define-constant TOKEN-SYMBOL "CEST")
(define-constant TOKEN-DECIMALS u6)

;; Collateralization and liquidation constants
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization required
(define-constant LIQUIDATION-THRESHOLD u120) ;; Liquidation at 120%
(define-constant LIQUIDATION-PENALTY u10) ;; 10% penalty
(define-constant PRICE-VALIDITY-PERIOD u144) ;; 24 hours in blocks (assuming 10min blocks)

;; data vars
(define-data-var contract-owner principal CONTRACT-OWNER)
(define-data-var total-supply uint u0)
(define-data-var paused bool false)
(define-data-var clean-energy-price uint u100000000) ;; Price in micro-STX (8 decimals)
(define-data-var last-price-update uint u0)

;; data maps
(define-map token-balances principal uint)
(define-map collateral-positions principal {
    collateral-amount: uint,
    debt-amount: uint,
    last-update: uint
})
(define-map authorized-oracles principal bool)
(define-map user-allowances {owner: principal, spender: principal} uint)

;; Oracle management
(define-public (add-oracle (oracle principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (ok (map-set authorized-oracles oracle true))
    )
)

(define-public (remove-oracle (oracle principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (ok (map-delete authorized-oracles oracle))
    )
)

(define-public (update-price (new-price uint))
    (begin
        (asserts! (default-to false (map-get? authorized-oracles tx-sender)) ERR-ORACLE-NOT-AUTHORIZED)
        (asserts! (> new-price u0) ERR-INVALID-AMOUNT)
        (var-set clean-energy-price new-price)
        (var-set last-price-update block-height)
        (ok true)
    )
)

;; SIP-010 trait implementation
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq tx-sender from) (is-eq contract-caller from)) ERR-NOT-TOKEN-OWNER)
        (asserts! (>= (ft-get-balance clean-energy-token from) amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        
        (try! (ft-transfer? clean-energy-token amount from to))
        (print {action: "transfer", from: from, to: to, amount: amount, memo: memo})
        (ok true)
    )
)

(define-read-only (get-name)
    (ok TOKEN-NAME)
)

(define-read-only (get-symbol)
    (ok TOKEN-SYMBOL)
)

(define-read-only (get-decimals)
    (ok TOKEN-DECIMALS)
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance clean-energy-token who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply clean-energy-token))
)

(define-read-only (get-token-uri)
    (ok none)
)

;; Collateral and position management
(define-public (deposit-collateral (amount uint))
    (let (
        (current-position (default-to {collateral-amount: u0, debt-amount: u0, last-update: u0} 
                                    (map-get? collateral-positions tx-sender)))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set collateral-positions tx-sender {
            collateral-amount: (+ (get collateral-amount current-position) amount),
            debt-amount: (get debt-amount current-position),
            last-update: block-height
        })
        (print {action: "deposit-collateral", user: tx-sender, amount: amount})
        (ok true)
    )
)

(define-public (withdraw-collateral (amount uint))
    (let (
        (current-position (unwrap! (map-get? collateral-positions tx-sender) ERR-POSITION-NOT-FOUND))
        (new-collateral (- (get collateral-amount current-position) amount))
        (debt-amount (get debt-amount current-position))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (get collateral-amount current-position) amount) ERR-INSUFFICIENT-COLLATERAL)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        
        ;; Check if remaining collateral meets requirements
        (asserts! (or (is-eq debt-amount u0) 
                     (>= (/ (* new-collateral u100) debt-amount) COLLATERAL-RATIO)) 
                 ERR-INSUFFICIENT-COLLATERAL)
        
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-set collateral-positions tx-sender {
            collateral-amount: new-collateral,
            debt-amount: debt-amount,
            last-update: block-height
        })
        (print {action: "withdraw-collateral", user: tx-sender, amount: amount})
        (ok true)
    )
)

(define-public (mint-synthetic (amount uint))
    (let (
        (current-position (default-to {collateral-amount: u0, debt-amount: u0, last-update: u0} 
                                    (map-get? collateral-positions tx-sender)))
        (current-price (var-get clean-energy-price))
        (collateral-value (* (get collateral-amount current-position) current-price))
        (new-debt (+ (get debt-amount current-position) amount))
        (required-collateral (/ (* new-debt COLLATERAL-RATIO) u100))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        (asserts! (< (- block-height (var-get last-price-update)) PRICE-VALIDITY-PERIOD) ERR-PRICE-TOO-OLD)
        (asserts! (>= collateral-value required-collateral) ERR-INSUFFICIENT-COLLATERAL)
        
        (try! (ft-mint? clean-energy-token amount tx-sender))
        (map-set collateral-positions tx-sender {
            collateral-amount: (get collateral-amount current-position),
            debt-amount: new-debt,
            last-update: block-height
        })
        (var-set total-supply (+ (var-get total-supply) amount))
        (print {action: "mint-synthetic", user: tx-sender, amount: amount})
        (ok true)
    )
)

(define-public (burn-synthetic (amount uint))
    (let (
        (current-position (unwrap! (map-get? collateral-positions tx-sender) ERR-POSITION-NOT-FOUND))
        (new-debt (- (get debt-amount current-position) amount))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (ft-get-balance clean-energy-token tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (>= (get debt-amount current-position) amount) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        
        (try! (ft-burn? clean-energy-token amount tx-sender))
        (map-set collateral-positions tx-sender {
            collateral-amount: (get collateral-amount current-position),
            debt-amount: new-debt,
            last-update: block-height
        })
        (var-set total-supply (- (var-get total-supply) amount))
        (print {action: "burn-synthetic", user: tx-sender, amount: amount})
        (ok true)
    )
)

;; Liquidation functionality
(define-public (liquidate (user principal) (amount uint))
    (let (
        (position (unwrap! (map-get? collateral-positions user) ERR-POSITION-NOT-FOUND))
        (current-price (var-get clean-energy-price))
        (collateral-value (* (get collateral-amount position) current-price))
        (debt-amount (get debt-amount position))
        (collateral-ratio (/ (* collateral-value u100) debt-amount))
        (liquidation-amount (if (<= amount debt-amount) amount debt-amount))
        (collateral-to-seize (/ (* liquidation-amount (+ u100 LIQUIDATION-PENALTY)) u100))
    )
        (asserts! (> liquidation-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (ft-get-balance clean-energy-token tx-sender) liquidation-amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (<= collateral-ratio LIQUIDATION-THRESHOLD) ERR-LIQUIDATION-THRESHOLD-NOT-MET)
        (asserts! (< (- block-height (var-get last-price-update)) PRICE-VALIDITY-PERIOD) ERR-PRICE-TOO-OLD)
        (asserts! (not (var-get paused)) ERR-OWNER-ONLY)
        
        ;; Burn liquidator's tokens
        (try! (ft-burn? clean-energy-token liquidation-amount tx-sender))
        
        ;; Transfer collateral to liquidator
        (try! (as-contract (stx-transfer? collateral-to-seize tx-sender user)))
        
        ;; Update position
        (map-set collateral-positions user {
            collateral-amount: (- (get collateral-amount position) collateral-to-seize),
            debt-amount: (- debt-amount liquidation-amount),
            last-update: block-height
        })
        
        (var-set total-supply (- (var-get total-supply) liquidation-amount))
        (print {action: "liquidation", liquidator: tx-sender, user: user, amount: liquidation-amount})
        (ok true)
    )
)

;; Administrative functions
(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (var-set paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (var-set paused false)
        (ok true)
    )
)

(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-OWNER-ONLY)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

;; read only functions
(define-read-only (get-price)
    (ok (var-get clean-energy-price))
)

(define-read-only (get-last-price-update)
    (ok (var-get last-price-update))
)

(define-read-only (get-position (user principal))
    (ok (map-get? collateral-positions user))
)

(define-read-only (get-collateral-ratio (user principal))
    (match (map-get? collateral-positions user)
        position 
        (let (
            (collateral-value (* (get collateral-amount position) (var-get clean-energy-price)))
            (debt-amount (get debt-amount position))
        )
            (if (> debt-amount u0)
                (ok (some (/ (* collateral-value u100) debt-amount)))
                (ok none)
            )
        )
        (ok none)
    )
)

(define-read-only (is-oracle-authorized (oracle principal))
    (ok (default-to false (map-get? authorized-oracles oracle)))
)

(define-read-only (is-liquidatable (user principal))
    (match (map-get? collateral-positions user)
        position
        (let (
            (collateral-value (* (get collateral-amount position) (var-get clean-energy-price)))
            (debt-amount (get debt-amount position))
            (collateral-ratio (/ (* collateral-value u100) debt-amount))
        )
            (ok (and (> debt-amount u0) (<= collateral-ratio LIQUIDATION-THRESHOLD)))
        )
        (ok false)
    )
)

(define-read-only (get-contract-info)
    (ok {
        name: TOKEN-NAME,
        symbol: TOKEN-SYMBOL,
        decimals: TOKEN-DECIMALS,
        total-supply: (ft-get-supply clean-energy-token),
        collateral-ratio: COLLATERAL-RATIO,
        liquidation-threshold: LIQUIDATION-THRESHOLD,
        current-price: (var-get clean-energy-price),
        paused: (var-get paused),
        owner: (var-get contract-owner)
    })
)

;; Initialize contract - Set deployer as first oracle
(map-set authorized-oracles CONTRACT-OWNER true)
