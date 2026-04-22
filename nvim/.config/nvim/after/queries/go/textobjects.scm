;; extends
;;
;; inherits: go
;; Package-level function textobjects for Go

;; Outer textobject: includes the entire function (signature + body)
((function_declaration
   name: (identifier) @function.name) @pkgfunc.outer)

;; Inner textobject: only the function body (without signature)
((function_declaration
   body: (block) @pkgfunc.inner))

;; Function name for movement (goes directly to identifier)
((function_declaration
   name: (identifier) @pkgfunc.name))

;; This will capture both value and pointer receivers

;; Capture the entire method declaration (outer)
(method_declaration
  receiver: (parameter_list) @method.receiver.outer
  name: (field_identifier) @method.name
  body: (block) @method.body
) @pkgfunc.outer

;; Capture only the method body (inner)
(method_declaration
  body: (block) @pkgfunc.inner
)

;; Method name for movement (goes directly to identifier)
(method_declaration
  name: (field_identifier) @pkgfunc.name
)

(return_statement) @return.outer

(
  (return_statement
    (expression_list) @return.inner)
)

(
  (return_statement
    (expression_list (_) @parameter.outer))
)
