(module
  (type (;0;) (func (param i32) (result i32)))
  (func (;0;) (type 0) (param i32) (result i32)
    local.get 0
    i32.const 10
    i32.add)
  (memory (;0;) 17)
  (export "memory" (memory 0))
  (export "plus_10" (func 0)))
