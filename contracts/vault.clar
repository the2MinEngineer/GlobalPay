;; GlobalPay Stablecoin Vault
;; Handles multi-token deposits, withdrawals, fees, compliance, and accounting
;; Clarity v2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS & ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-TOKEN-NOT-ALLOWED u101)
(define-constant ERR-INSUFFICIENT-BALANCE u102)
(define-constant ERR-WITHDRAW-LIMIT u103)
(define-constant ERR-PAUSED u104)
(define-constant ERR-ZERO-AMOUNT u105)
(define-constant ZERO-ADDR 'SP000000000000000000002Q6VF78)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATE VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-data-var admin principal tx-sender)
(define-data-var auditor principal tx-sender)
(define-data-var paused bool false)

;; Balances and accounting
(define-map vault-balances { user: principal, token: principal } uint)

;; Whitelisted stablecoins
(define-map allowed-tokens { token: principal } bool)

;; Daily withdrawal limits (per token)
(define-map daily-withdrawals { user: principal, token: principal } uint)
(define-data-var daily-limit uint u10000) ;; Default 10k stablecoin limit

;; Fee configuration
(define-data-var deposit-fee-bps uint u10)  ;; 0.10%
(define-data-var withdraw-fee-bps uint u20) ;; 0.20%
(define-data-var collected-fees uint u0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE HELPERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (only-admin)
  (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
)

(define-private (only-auditor)
  (asserts! (is-eq tx-sender (var-get auditor)) (err ERR-NOT-AUTHORIZED))
)

(define-private (not-paused)
  (asserts! (not (var-get paused)) (err ERR-PAUSED))
)

(define-private (is-token-allowed (token principal))
  (asserts! (is-some (map-get? allowed-tokens { token: token })) (err ERR-TOKEN-NOT-ALLOWED))
)

(define-private (calculate-fee (amount uint) (bps uint))
  (/ (* amount bps) u10000)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ADMIN FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (set-admin (new-admin principal))
  (begin
    (only-admin)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (set-auditor (new-auditor principal))
  (begin
    (only-admin)
    (var-set auditor new-auditor)
    (ok true)
  )
)

(define-public (set-paused (pause bool))
  (begin
    (only-admin)
    (var-set paused pause)
    (ok pause)
  )
)

(define-public (whitelist-token (token principal) (status bool))
  (begin
    (only-admin)
    (map-set allowed-tokens { token: token } status)
    (ok status)
  )
)

(define-public (set-daily-limit (limit uint))
  (begin
    (only-admin)
    (var-set daily-limit limit)
    (ok limit)
  )
)

(define-public (set-fees (deposit-bps uint) (withdraw-bps uint))
  (begin
    (only-admin)
    (var-set deposit-fee-bps deposit-bps)
    (var-set withdraw-fee-bps withdraw-bps)
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CORE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (deposit (token principal) (amount uint))
  (begin
    (not-paused)
    (is-token-allowed token)
    (asserts! (>= amount u1) (err ERR-ZERO-AMOUNT))
    ;; Move tokens into vault
    (try! (contract-call? token transfer tx-sender (as-contract tx-sender) amount none))
    ;; Calculate fee
    (let ((fee (calculate-fee amount (var-get deposit-fee-bps))))
      (map-set vault-balances { user: tx-sender, token: token }
        (+ (- amount fee) (default-to u0 (map-get? vault-balances { user: tx-sender, token: token }))))
      (var-set collected-fees (+ (var-get collected-fees) fee))
      (print { event: "deposit", user: tx-sender, token: token, amount: amount, fee: fee })
      (ok true)
    )
  )
)

(define-public (withdraw (token principal) (amount uint))
  (begin
    (not-paused)
    (is-token-allowed token)
    (asserts! (>= amount u1) (err ERR-ZERO-AMOUNT))
    ;; Check vault balance
    (let ((bal (default-to u0 (map-get? vault-balances { user: tx-sender, token: token }))))
      (asserts! (>= bal amount) (err ERR-INSUFFICIENT-BALANCE))
      ;; Check daily limit
      (let ((withdrawn-today (default-to u0 (map-get? daily-withdrawals { user: tx-sender, token: token }))))
        (asserts! (<= (+ withdrawn-today amount) (var-get daily-limit)) (err ERR-WITHDRAW-LIMIT))
        ;; Update balances
        (let ((fee (calculate-fee amount (var-get withdraw-fee-bps))))
          (map-set vault-balances { user: tx-sender, token: token } (- bal amount))
          (map-set daily-withdrawals { user: tx-sender, token: token } (+ withdrawn-today amount))
          (try! (contract-call? token transfer (as-contract tx-sender) tx-sender (- amount fee) none))
          (var-set collected-fees (+ (var-get collected-fees) fee))
          (print { event: "withdraw", user: tx-sender, token: token, amount: amount, fee: fee })
          (ok true)
        )
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AUDITOR FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (reset-daily-withdrawals (user principal) (token principal))
  (begin
    (only-auditor)
    (map-delete daily-withdrawals { user: user, token: token })
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-balance (user principal) (token principal))
  (ok (default-to u0 (map-get? vault-balances { user: user, token: token })))
)

(define-read-only (get-daily-withdrawn (user principal) (token principal))
  (ok (default-to u0 (map-get? daily-withdrawals { user: user, token: token })))
)

(define-read-only (get-collected-fees)
  (ok (var-get collected-fees))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (get-auditor)
  (ok (var-get auditor))
)

(define-read-only (is-token-whitelisted (token principal))
  (ok (default-to false (map-get? allowed-tokens { token: token })))
)
