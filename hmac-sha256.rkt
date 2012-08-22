#lang racket/base

;; Starting point was web-server/stuffers/hmac-sha1.
;; Wanted:
;; 1. HMAC-SHA256.
;; 2. Plain SHA256.

(require racket/contract
         web-server/stuffers/stuffer
         racket/runtime-path
         openssl/libcrypto
         (rename-in ffi/unsafe
                    [-> f->]))

(define EVP_SHA256
  (and libcrypto
       (get-ffi-obj 'EVP_sha256 libcrypto
                    (_fun f-> _fpointer))))

(define HMAC-SHA256/raw
  (if libcrypto
      (get-ffi-obj 'HMAC libcrypto
                   (_fun [EVP_MD : _fpointer = (EVP_SHA256)]
                         [key : _bytes]
                         [key_len : _int = (bytes-length key)]
                         [data : _bytes]
                         [data_len : _int = (bytes-length data)]
                         [md : (_bytes o 32)]
                         [md_len : (_ptr o _uint)]
                         f-> _bytes
                         f-> md))
      (lambda (key data) (error 'HMAC-SHA256/raw "libcrypto could not load"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (HMAC-SHA256 key data)
  ;; It returns the same pointer always
  ;; A SHA256 is 32 bytes, including 0s
  (make-sized-byte-string (HMAC-SHA256/raw key data) 32))


(define SHA256/raw
  (if libcrypto
      (get-ffi-obj 'SHA256 libcrypto
                   (_fun [data : _bytes]
                         [data_len : _int = (bytes-length data)]
                         [md : (_bytes o 32)]
                         ;;[md_len : (_ptr o _uint)]
                         f-> _bytes
                         f-> md))
      (lambda (key data) (error 'HMAC-SHA256/raw "libcrypto could not load"))))

(define (SHA256 data)
  (make-sized-byte-string (SHA256/raw data) 32))

(provide/contract
 [SHA256 (bytes? . -> . bytes?)]
 [HMAC-SHA256 (bytes? bytes? . -> . bytes?)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(module+ test
  (require rackunit
           net/base64
           file/sha1)
  (test-case
   "HMAC-SHA256"
   (define b (HMAC-SHA256 (string->bytes/utf-8 "key")
                          (string->bytes/utf-8 "data")))
   (check-equal? (base64-encode b)
                 #"UDH+PZicbRU3oBP6bnOdojRj/a7DtwE32Cjjas4iG9A=\r\n"))

  (test-case
   "SHA256"
   (check-equal?
    (bytes->hex-string (SHA256 #"data"))
    "3a6eb0790f39ac87c94f3856b2dd2c5d110e6811602261a9a923d3bb23adc8b7"))
  )