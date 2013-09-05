;; -*- mode: lisp -*-

;;; infrastructure

(set passed 0)
(set failed 0)
(set tests ())

(defmacro test (x msg)
  `(if (not ,x)
       (do (set failed (+ failed 1))
	   (return ,msg))
     (set passed (+ passed 1))))

(defun test-equal? (a b)
  (if (atom? a)
      (= a b)
    (= (to-string a) (to-string b))))

(defmacro test-equal (a b)
  `(test (test-equal? ,a ,b)
	 (cat " failed: expected " (to-string ,a) ", was " (to-string ,b))))

(defmacro deftest (name _ body...)
  `(push tests (list ',name (lambda () ,@body))))

(defun run-tests ()
  (across (tests test)
    (local name (at test 0))
    (local fn (at test 1))
    (local result (fn))
    (if (string? result)
	(print (cat " " name result))))
  (print (cat passed " passed, " failed " failed")))


;;; basic

(deftest reader ()
  (test-equal 17 (read-from-string "17"))
  (test-equal 0.015 (read-from-string "1.5e-2"))
  (test-equal true (read-from-string "true"))
  (test-equal (not true) (read-from-string "false"))
  (test-equal 'hi (read-from-string "hi"))
  (test-equal '"hi" (read-from-string "\"hi\""))
  (test-equal '(1 2) (read-from-string "(1 2)"))
  (test-equal '(1 (a)) (read-from-string "(1 (a))"))
  (test-equal '(quote a) (read-from-string "'a"))
  (test-equal '(quasiquote a) (read-from-string "`a"))
  (test-equal '(quasiquote (unquote a)) (read-from-string "`,a"))
  (test-equal '(quasiquote (unquote-splicing a)) (read-from-string "`,@a")))

(deftest boolean ()
  (test-equal true (or true false))
  (test-equal false (or false false))
  (test-equal true (not false))
  (test-equal true (and true true))
  (test-equal false (and true false))
  (test-equal false (and true true false)))

(deftest numeric ()
  (test-equal 4 (+ 2 2))
  (test-equal 18 18.00)
  (test-equal 4 (- 7 3))
  (test-equal 5.0 (/ 10 2))
  (test-equal 6 (* 2 3.00))
  (test-equal true (> 2.01 2))
  (test-equal true (>= 5.0 5.0))
  (test-equal false (< 2 2))
  (test-equal true (<= 2 2))
  (test-equal -7 (- 7)))

(deftest string ()
  (test-equal 3 (length "foo"))
  (test-equal 3 (length "\"a\""))
  (test-equal 'a "a")
  (test-equal "a" (char "bar" 1)))

(deftest quote ()
  (test-equal 7 (quote 7))
  (test-equal true (quote true))
  (test-equal false (quote false))
  (test-equal (quote a) 'a)
  (test-equal (quote (quote a)) ''a)
  (test-equal "\"a\"" '"a")
  (test-equal '(quote "a") ''"a")
  (test-equal (quote unquote) 'unquote)
  (test-equal (quote (unquote)) '(unquote))
  (test-equal (quote (unquote a)) '(unquote a)))

(deftest list ()
  (test-equal '() (list))
  (test-equal () (list))
  (test-equal '(a) (list 'a))
  (test-equal '(a) (quote (a)))
  (test-equal '(()) (list (list)))
  (test-equal 0 (length (list)))
  (test-equal 2 (length (list 1 2))))

(deftest quasiquote ()
  (test-equal (quote a) (quasiquote a))
  (test-equal 'a `a)
  (test-equal '() `())
  (test-equal () `())
  (test-equal 2 `,2)
  (local a 42)
  (test-equal 42 `,a)
  (test-equal 42 (quasiquote (unquote a)))
  (test-equal '(quasiquote (unquote a)) ``,a)
  (test-equal '(quasiquote (unquote 42)) ``,,a)
  (test-equal '(quasiquote (quasiquote (unquote (unquote a)))) ```,,a)
  (test-equal '(quasiquote (quasiquote (unquote (unquote 42)))) ```,,,a)
  (test-equal '(a (quasiquote (b (unquote c)))) `(a `(b ,c)))
  (test-equal '(a (quasiquote (b (unquote 42)))) `(a `(b ,,a)))
  (local b 'c)
  (test-equal '(quote c) `',b)
  (test-equal '(42) `(,a))
  (test-equal '((42)) `((,a)))
  (test-equal '(41 (42)) `(41 (,a)))
  (local c '(1 2 3))
  (test-equal '((1 2 3)) `(,c))
  (test-equal '(1 2 3) `(,@c))
  (test-equal '(0 1 2 3) `(0 ,@c))
  (test-equal '(0 1 2 3 4) `(0 ,@c 4))
  (test-equal '(0 (1 2 3) 4) `(0 (,@c) 4))
  (test-equal '(1 2 3 1 2 3) `(,@c ,@c))
  (test-equal '((1 2 3) 1 2 3) `((,@c) ,@c))
  (test-equal '(quasiquote ((unquote-splicing (list a)))) ``(,@(list a)))
  (test-equal '(quasiquote ((unquote-splicing (list 42)))) ``(,@(list ,a))))

(deftest calls ()
  (local f (lambda () 42))
  (test-equal 42 (f))
  (local l (list f))
  (test-equal 42 ((at l 0)))
  (local t (table 'f f))
  (test-equal 42 (t.f))
  (test-equal 42 ((dot t f))))


;;; special forms

(deftest local ()
  (local a 42)
  (test-equal 42 a))

(deftest set ()
  (local a 42)
  (set a 'bar)
  (test-equal 'bar a))

(deftest do ()
  (local a 17)
  (do (set a 10)
      (test-equal 10 a))
  ;; do cannot introduce a new scope
  (do (local a 7)
      (test-equal 7 a))
  (test-equal 7 a))

(deftest if ()
  (if true
      (test-equal true true)
    (test-equal true false)))

(deftest while ()
  (local i 0)
  (while (< i 10)
    (set i (+ i 1)))
  (test-equal 10 i))

(deftest table ()
  (test-equal (table 'a 10 'b 20) (table 'a 10 'b 20))
  (test-equal 10 (get (table 'a 10) 'a)))

(deftest get-set ()
  (local t (table))
  (set (get t 'foo) 'bar)
  (test-equal 'bar (get t 'foo)))

(deftest dot ()
  (local t (table 'a 10))
  (test-equal 10 t.a)
  (test-equal 10 (dot t a)))

(deftest each ()
  (local a "")
  (local b 0)
  (each ((table 'a 10 'b 20 'c 30) k v)
    (set a (cat a k))
    (set b (+ b v)))
  (test-equal 3 (length a))
  (test-equal 60 b))

(deftest lambda ()
  (local f (lambda (n) (+ n 10)))
  (test-equal 20 (f 10))
  (test-equal 30 (f 20))
  (test-equal 40 ((lambda (n) (+ n 10)) 30)))


;;; expressions

(deftest if-expr ()
  (test-equal 10 (if true 10 20)))

(deftest set-expr ()
  (local a 5)
  (test-equal nil (set a 7))
  (test-equal 10 (do (set a 10) a)))

(deftest local-expr ()
  (local a 5)
  (test-equal 10 (do (local a 10) a)))

(deftest while-expr ()
  (local i 0)
  (test-equal 10 (do (while (< i 10) (set i (+ i 1))) i)))

(deftest each-expr ()
  (local t (table 'a 10 'b 20))
  (local i 0)
  (test-equal 2 (do (each (t _ _) (set i (+ i 1))) i)))


;;; library

(deftest push ()
  (local l ())
  (push l 'a)
  (push l 'b)
  (push l 'c)
  (test-equal '(a b c) l))

(deftest pop ()
  (local l '(a b c))
  (test-equal 'c (pop l))
  (test-equal 'b (pop l))
  (test-equal 'a (pop l))
  (test-equal nil (pop l)))

(deftest last ()
  (test-equal 3 (last '(1 2 3)))
  (test-equal nil (last ()))
  (test-equal 'c (last '(a b c))))

(deftest join ()
  (test-equal '(1 2 3) (join '(1 2) '(3)))
  (test-equal '(1 2) (join () '(1 2)))
  (test-equal () (join () ())))

(deftest sub ()
  (test-equal '(b c) (sub '(a b c) 1))
  (test-equal '(b c) (sub '(a b c d) 1 3))
  (test-equal "uux" (sub "quux" 1))
  (test-equal "uu" (sub "quux" 1 3))
  (test-equal "" (sub "quux" 5)))

(deftest find ()
  (test-equal 0 (find "abc" "a"))
  (test-equal 2 (find "abcd" "cd"))
  (test-equal nil (find "abc" "z")))

(deftest split ()
  (test-equal (list "a") (split "a" ","))
  (test-equal (list "a" "") (split "a," ","))
  (test-equal (list "a" "b") (split "a,b" ",")))

(deftest type ()
  (test-equal true (string? "abc"))
  (test-equal false (string? 17))
  (test-equal false (string? '(a)))
  (test-equal false (string? true))
  (test-equal false (string? (table)))
  (test-equal false (number? "abc"))
  (test-equal true (number? 17))
  (test-equal false (number? '(a)))
  (test-equal false (number? true))
  (test-equal false (number? (table)))
  (test-equal false (boolean? "abc"))
  (test-equal false (boolean? 17))
  (test-equal false (boolean? '(a)))
  (test-equal true (boolean? true))
  (test-equal false (boolean? (table)))
  (test-equal false (list? "abc"))
  (test-equal false (list? 17))
  (test-equal true (list? '(a)))
  (test-equal false (list? true))
  (test-equal false (list? (table)))
  (test-equal false (table? "abc"))
  (test-equal false (table? 17))
  (test-equal false (table? '(a)))
  (test-equal false (table? true))
  (test-equal true (table? (table))))

(deftest apply ()
  (test-equal 4 (apply (lambda (a b) (+ a b)) '(2 2)))
  (test-equal '(2 2) (apply (lambda (a...) a) '(2 2))))

(deftest eval ()
  (local f (lambda (x) (eval (compile x))))
  (test-equal 4 (f '(+ 2 2)))
  (test-equal 5 (f '(do (local a 3) (+ 2 a)))))

(deftest bind ()
  (bind (a b c) '(1 2 3))
  (test-equal 1 a)
  (test-equal 2 b)
  (test-equal 3 c)
  (bind (w (x (y) z)) '(1 (2 (3) 4)))
  (test-equal 1 w)
  (test-equal 2 x)
  (test-equal 3 y)
  (test-equal 4 z)
  (bind (a b c...) '(1 2 3 4))
  (test-equal '(3 4) c)
  (bind (w (x y...) z...) '(1 (2 3 4) 5 6 7))
  (test-equal '(3 4) y)
  (test-equal '(5 6 7) z))

(deftest parameters ()
  (local f (lambda (a (b c)) (list a b c)))
  (test-equal '(1 2 3) (f 1 '(2 3)))
  (set f (lambda (a (b c...) d...) (list a b c d)))
  (test-equal '(1 2 (3 4) (5 6 7)) (f 1 '(2 3 4) 5 6 7)))
