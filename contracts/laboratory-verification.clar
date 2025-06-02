;; Laboratory Verification Contract
;; Validates quantum chemistry research and experiments

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))

;; Data structures
(define-map research-submissions
    { submission-id: uint }
    {
        researcher: principal,
        title: (string-ascii 256),
        methodology: (string-ascii 512),
        results: (string-ascii 512),
        verified: bool,
        verifier: (optional principal),
        timestamp: uint
    }
)

(define-map researcher-credentials
    { researcher: principal }
    {
        institution: (string-ascii 128),
        verified: bool,
        reputation-score: uint
    }
)

(define-data-var next-submission-id uint u1)

;; Submit research for verification
(define-public (submit-research (title (string-ascii 256)) (methodology (string-ascii 512)) (results (string-ascii 512)))
    (let ((submission-id (var-get next-submission-id)))
        (map-set research-submissions
            { submission-id: submission-id }
            {
                researcher: tx-sender,
                title: title,
                methodology: methodology,
                results: results,
                verified: false,
                verifier: none,
                timestamp: block-height
            }
        )
        (var-set next-submission-id (+ submission-id u1))
        (ok submission-id)
    )
)

;; Verify research submission
(define-public (verify-research (submission-id uint) (is-valid bool))
    (let ((submission (unwrap! (map-get? research-submissions { submission-id: submission-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get verified submission)) err-already-verified)
        (map-set research-submissions
            { submission-id: submission-id }
            (merge submission {
                verified: is-valid,
                verifier: (some tx-sender)
            })
        )
        (ok true)
    )
)

;; Register researcher credentials
(define-public (register-researcher (institution (string-ascii 128)))
    (ok (map-set researcher-credentials
        { researcher: tx-sender }
        {
            institution: institution,
            verified: false,
            reputation-score: u0
        }
    ))
)

;; Read-only functions
(define-read-only (get-research-submission (submission-id uint))
    (map-get? research-submissions { submission-id: submission-id })
)

(define-read-only (get-researcher-credentials (researcher principal))
    (map-get? researcher-credentials { researcher: researcher })
)
