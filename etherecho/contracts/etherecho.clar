;; EtherEcho - Decentralized Digital Echo Platform
;; Written in Clarity for Stacks blockchain

;; Constants
(define-constant echo-master tx-sender)
(define-constant err-not-master (err u100))
(define-constant err-echo-resonated (err u101))
(define-constant err-still-rippling (err u102))
(define-constant err-echo-void (err u103))

;; Data Variables
(define-data-var echo-count uint u0)
(define-data-var ripple-seed uint u1)

;; Define echo structure
(define-map echoes uint {
    resonator: principal,
    echo-hash: (string-utf8 256),
    resonance-height: uint,
    whispered: bool,
    resonated: bool,
    echo-receiver: (optional principal)
})

;; Define echo metadata
(define-map echo-metadata uint {
    echo-title: (string-utf8 64),
    echo-essence: (string-utf8 256),
    echo-form: (string-utf8 16),  ;; "text", "photo", "audio"
    ripple-height: uint
})

;; Public functions
;; Create a new echo
(define-public (create-echo (echo-hash (string-utf8 256)) 
                          (echo-title (string-utf8 64))
                          (echo-essence (string-utf8 256))
                          (echo-form (string-utf8 16))
                          (ripple-delay uint)
                          (whispered bool)
                          (echo-receiver (optional principal)))
    (let ((echo-id (var-get echo-count))
          (resonance-height (+ block-height ripple-delay)))
        
        ;; Store echo data
        (map-set echoes echo-id {
            resonator: tx-sender,
            echo-hash: echo-hash,
            resonance-height: resonance-height,
            whispered: whispered,
            resonated: false,
            echo-receiver: echo-receiver
        })
        
        ;; Store metadata
        (map-set echo-metadata echo-id {
            echo-title: echo-title,
            echo-essence: echo-essence,
            echo-form: echo-form,
            ripple-height: block-height
        })
        
        ;; Increment total echoes
        (var-set echo-count (+ echo-id u1))
        (ok echo-id)))

;; Resonate with an echo (for time-locked or targeted echoes)
(define-public (resonate-echo (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (asserts! (>= block-height (get resonance-height echo)) (err err-still-rippling))
        (asserts! (not (get resonated echo)) (err err-echo-resonated))
        (asserts! (or
            (is-none (get echo-receiver echo))
            (is-eq (some tx-sender) (get echo-receiver echo)))
            (err err-not-master))
        
        ;; Mark as resonated
        (map-set echoes echo-id (merge echo { resonated: true }))
        (ok true)))

;; Find a random unresonated echo
(define-public (find-random-echo)
    (let ((current-ripple (var-get ripple-seed))
          (total (var-get echo-count)))
        
        ;; Update ripple seed
        (var-set ripple-seed (+ current-ripple block-height))
        
        ;; Get random echo ID
        (let ((random-id (mod current-ripple total)))
            (ok (unwrap! (map-get? echoes random-id) (err err-echo-void))))))

;; Read functions
;; Get echo details if resonance time reached
(define-read-only (get-echo-details (echo-id uint))
    (let ((echo (unwrap! (map-get? echoes echo-id) (err err-echo-void))))
        (if (>= block-height (get resonance-height echo))
            (ok {
                echo: echo,
                metadata: (unwrap! (map-get? echo-metadata echo-id) (err err-echo-void))
            })
            (err err-still-rippling))))

;; Get total number of echoes
(define-read-only (get-total-echoes)
    (ok (var-get echo-count)))