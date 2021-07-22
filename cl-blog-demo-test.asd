(defsystem "cl-blog-demo-test"
  :defsystem-depends-on ("prove-asdf")
  :author "Rajasegar Chandran"
  :license ""
  :depends-on ("cl-blog-demo"
               "prove")
  :components ((:module "tests"
                :components
                ((:test-file "cl-blog-demo"))))
  :description "Test system for cl-blog-demo"
  :perform (test-op (op c) (symbol-call :prove-asdf :run-test-system c)))
