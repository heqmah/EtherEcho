;; EtherEcho - Decentralized Digital Echo Platform
;; Written in Clarity for Stacks blockchain

;; Error codes
(define-constant err-not-master (err u100))
(define-constant err-echo-resonated (err u101))
(define-constant err-still-rippling (err u102))
(define-constant err-echo-void (err u103))
(define-constant err-echo-sealed (err u104))
(define-constant err-invalid-ripple-delay (err u105))
(define-constant err-invalid-title-length (err u106))
(define-constant err-invalid-essence-length (err u107))
(define-constant err-invalid-echo-form (err u108))
(define-constant err-echo-silenced (err u109))
(define-constant err-self-amplify (err u110))
(define-constant err-waves-frozen (err u111))
(define-constant err-invalid-harmonics (err u112))
(define-constant err-invalid-echo-signature (err u113))
(define-constant err-invalid-receiver (err u114))
(define-constant err-invalid-whisper-flag (err u115))

;; Constants
(define-constant echo-master tx-sender)
(define-constant max-title-length u64)
(define-constant max-essence-length u256)
(define-constant min-ripple-delay u1)
(define-constant max-ripple-delay u52560)
(define-constant text-form "text")
(define-constant photo-form "photo")
(define-constant audio-form "audio")

;; Data Variables
(define-data-var echo-count uint u0)
(define-data-var ripple-seed uint u1)
(define-data-var waves-frozen bool false)

;; Define echo structure
(define-map echoes uint {
    resonator: principal,
    echo-signature: (string-ascii 256),
    resonance-height: uint,
    whispered: bool,
    resonated: bool,
    silenced: bool,
    echo-receiver: (optional principal),
    amplifications: uint,
    dissonance: uint,
    echo-form: (string-ascii 5)
})

;; Define echo metadata
(define-map echo-metadata uint {
    echo-title: (string-ascii 64),
    echo-essence: (string-ascii 256),
    ripple-height: uint,
    last-vibration: uint,
    harmonics: (list 5 (string-ascii 32))
})

;; Resonator interaction tracking
(define-map resonator-interactions principal {
    echoes-created: uint,
    echoes-resonated: uint,
    amplifications-given: uint
})

;; Echo amplifications tracking
(define-map echo-amplifications (tuple (echo-id uint) (resonator principal)) bool)

;; Private validation functions
(define-private (is-valid-echo-form (echo-form (string-ascii 5)))
    (and 
        (is-some (as-max-len? echo-form u5))
        (or 
            (is-eq echo-form text-form)
            (is-eq echo-form photo-form)
            (is-eq echo-form audio-form)
        )))

(define-private (sanitize-echo-signature (echo-signature (string-ascii 256)))
    (match (as-max-len? echo-signature u256)
        success (ok echo-signature)
        (err err-invalid-echo-signature)))

(define-private (sanitize-ripple-delay (ripple-delay uint))
    (if (and (>= ripple-delay min-ripple-delay) (<= ripple-delay max-ripple-delay))
        (ok ripple-delay)
        (err err-invalid-ripple-delay)))

(define-private (sanitize-title (title (string-ascii 64)))
    (match (as-max-len? title u64)
        success (if (<= (len title) max-title-length)
            (ok title)
            (err err-invalid-title-length))
        (err err-invalid-title-length)))

(define-private (sanitize-essence (essence (string-ascii 256)))
    (match (as-max-len? essence u256)
        success (if (<= (len essence) max-essence-length)
            (ok essence)
            (err err-invalid-essence-length))
        (err err-invalid-essence-length)))

(define-private (sanitize-harmonics (harmonics (list 5 (string-ascii 32))))
    (match (as-max-len? harmonics u5)
        success (ok harmonics)
        (err err-invalid-harmonics)))

(define-private (sanitize-receiver (receiver (optional principal)))
    (ok receiver))

(define-private (sanitize-whispered (whispered bool))
    (if (or (is-eq whispered true) (is-eq whispered false))
        (ok whispered)
        (err err-invalid-whisper-flag)))

(define-private (validate-echo-params 
    (echo-title (string-ascii 64))
    (echo-essence (string-ascii 256))
    (echo-form (string-ascii 5))
    (ripple-delay uint)
    (echo-signature (string-ascii 256))
    (harmonics (list 5 (string-ascii 32))))
    (begin
        (asserts! (is-some (as-max-len? echo-title u64)) (err err-invalid-title-length))
        (asserts! (is-some (as-max-len? echo-essence u256)) (err err-invalid-essence-length))
        (asserts! (is-valid-echo-form echo-form) (err err-invalid-echo-form))
        (try! (sanitize-ripple-delay ripple-delay))
        (asserts! (is-some (as-max-len? echo-signature u256)) (err err-invalid-echo-signature))
        (asserts! (is-some (as-max-len? harmonics u5)) (err err-invalid-harmonics))
        (ok true)))

(define-private (update-resonator-stats (resonator principal) (action (string-ascii 6)))
    (let ((current-stats (default-to 
            { echoes-created: u0, echoes-resonated: u0, amplifications-given: u0 }
            (map-get? resonator-interactions resonator))))
        (if (is-eq action "create")
            (map-set resonator-interactions resonator (merge current-stats { echoes-created: (+ (get echoes-created current-stats) u1) }))
            (if (is-eq action "claim")
                (map-set resonator-interactions resonator (merge current-stats { echoes-resonated: (+ (get echoes-resonated current-stats) u1) }))
                (if (is-eq action "amp")
                    (map-set resonator-interactions resonator (merge current-stats { amplifications-given: (+ (get amplifications-given current-stats) u1) }))
                    false)))))

;; Public functions

;; Contract management
(define-public (toggle-waves-freeze)
    (begin
        (asserts! (is-eq tx-sender echo-master) (err err-not-master))
        (ok (var-set waves-frozen (not (var-get waves-frozen))))))

;; Create a new echo
(define-public (create-echo 
    (echo-signature (string-ascii 256)) 
    (echo-title (string-ascii 64))
    (echo-essence (string-ascii 256))
    (echo-form (string-ascii 5))
    (ripple-delay uint)
    (whispered bool)
    (echo-receiver (optional principal))
    (harmonics (list 5 (string-ascii 32))))
    
    (begin
        (asserts! (not (var-get waves-frozen)) (err err-waves-frozen))
        (try! (validate-echo-params echo-title echo-essence echo-form ripple-delay echo-signature harmonics))
        
        (let ((echo-id (var-get echo-count))
              (validated-signature (try! (sanitize-echo-signature echo-signature)))
              (validated-ripple-delay (try! (sanitize-ripple-delay ripple-delay)))
              (validated-whispered (try! (sanitize-whispered whispered)))
              (validated-receiver (sanitize-receiver echo-receiver))
              (validated-title (try! (sanitize-title echo-title)))
              (validated-essence (try! (sanitize-essence echo-essence)))
              (validated-harmonics (try! (sanitize-harmonics harmonics)))
              (resonance-height (+ block-height validated-ripple-delay)))
            
            ;; Store echo data
            (map-set echoes echo-id {
                resonator: tx-sender,
                echo-signature: validated-signature,
                resonance-height: resonance-height,
                whispered: validated-whispered,
                resonated: false,
                silenced: false,
                echo-receiver: (unwrap! validated-receiver (err err-invalid-receiver)),
                amplifications: u0,
                dissonance: u0,
                echo-form: echo-form
            })
            
            ;; Store metadata
            (map-set echo-metadata echo-id {
                echo-title: validated-title,
                echo-essence: validated-essence,
                ripple-height: block-height,
                last-vibration: block-height,
                harmonics: validated-harmonics
            })
            
            ;; Update stats
            (update-resonator-stats tx-sender "create")
            
            ;; Increment total echoes
            (var-set echo-count (+ echo-id u1))
            (ok echo-id))))

;; Resonate with an echo
(define-public (resonate-echo (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (asserts! (not (var-get waves-frozen)) (err err-waves-frozen))
        (asserts! (not (get silenced echo)) (err err-echo-silenced))
        (asserts! (>= block-height (get resonance-height echo)) (err err-still-rippling))
        (asserts! (not (get resonated echo)) (err err-echo-resonated))
        (asserts! (or
            (is-none (get echo-receiver echo))
            (is-eq (some tx-sender) (get echo-receiver echo)))
            (err err-not-master))
        
        ;; Mark as resonated and update stats
        (map-set echoes echo-id (merge echo { resonated: true }))
        (update-resonator-stats tx-sender "claim")
        (ok true)))

;; Amplify an echo
(define-public (amplify-echo (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void)))
          (amplification-key {echo-id: echo-id, resonator: tx-sender}))
        (asserts! (not (var-get waves-frozen)) (err err-waves-frozen))
        (asserts! (not (get silenced echo)) (err err-echo-silenced))
        (asserts! (>= block-height (get resonance-height echo)) (err err-still-rippling))
        (asserts! (is-none (map-get? echo-amplifications amplification-key)) (err err-echo-resonated))
        
        ;; Update amplifications count and record resonator interaction
        (map-set echoes echo-id (merge echo { amplifications: (+ (get amplifications echo) u1) }))
        (map-set echo-amplifications amplification-key true)
        (update-resonator-stats tx-sender "amp")
        (ok true)))

;; Report dissonant content
(define-public (report-dissonance (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (asserts! (not (var-get waves-frozen)) (err err-waves-frozen))
        (asserts! (not (get silenced echo)) (err err-echo-silenced))
        
        ;; Increment dissonance count
        (map-set echoes echo-id (merge echo { dissonance: (+ (get dissonance echo) u1) }))
        (ok true)))

;; Silence echo (only resonator or echo master)
(define-public (silence-echo (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (asserts! (or 
            (is-eq tx-sender (get resonator echo))
            (is-eq tx-sender echo-master))
            (err err-not-master))
        
        (map-set echoes echo-id (merge echo { silenced: true }))
        (ok true)))

;; Find a random unresonated echo
(define-public (find-random-echo)
    (let ((current-seed (var-get ripple-seed))
          (total (var-get echo-count)))
        
        (asserts! (not (var-get waves-frozen)) (err err-waves-frozen))
        
        ;; Update ripple seed
        (var-set ripple-seed (+ current-seed block-height))
        
        ;; Get random echo ID
        (let ((random-id (mod current-seed total)))
            (ok (unwrap! (map-get? echoes random-id) (err err-echo-void))))))

;; Read functions

;; Get echo details if resonance time reached
(define-read-only (get-echo-details (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (asserts! (not (get silenced echo)) (err err-echo-silenced))
        (if (>= block-height (get resonance-height echo))
            (ok {
                echo: echo,
                metadata: (unwrap! (map-get? echo-metadata echo-id) (err err-echo-void))
            })
            (err err-still-rippling))))

;; Get resonator statistics
(define-read-only (get-resonator-stats (resonator principal))
    (ok (default-to 
        { echoes-created: u0, echoes-resonated: u0, amplifications-given: u0 }
        (map-get? resonator-interactions resonator))))

;; Get total number of echoes
(define-read-only (get-total-echoes)
    (ok (var-get echo-count)))

;; Check if echo is amplified by resonator
(define-read-only (is-echo-amplified-by-resonator (echo-id uint) (resonator principal))
    (ok (is-some (map-get? echo-amplifications {echo-id: echo-id, resonator: resonator}))))