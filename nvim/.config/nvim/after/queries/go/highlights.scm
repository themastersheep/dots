;; extends
;;
;; inherits: go

(short_var_declaration
   left: (expression_list
    (identifier) @variable.declaration))

(var_spec
  name: (identifier) @variable.declaration)

(assignment_statement
  left: (expression_list
    (identifier) @variable.redeclaration))
