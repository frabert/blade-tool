start = decls

decls
  = name:([a-zA-Z][a-zA-Z0-9]*) [ \n\t]* ":" [ \n\t]*
      ("int"
      / "[" [ \n\t]* [0-9]+ [ \n\t]* "," [ \n\t]* [0-9]+ [ \n\t]* "]")
    [ \n\t]* ";" [ \n\t]* c:decls { return c }
  / command

value
  = num:[0-9]+ { return { type: "int", value: parseInt(num.join(""), 10) } }
  / "true" { return { type: "bool", value: true } }
  / "false" { return { type: "bool", value: false } }
  / name:([a-zA-Z][a-zA-Z0-9]*) { return { type: "name", name: name.join("") } }

expr
  = "length" [ \n\t]* "(" [ \n\t]* e:expr [ \n\t]* ")" { return { type: "length", value: e } }
  / "base" [ \n\t]* "(" [ \n\t]* e:expr [ \n\t]* ")" { return { type: "base", value: e } }
  / e1:primary [ \n\t]* "?" [ \n\t]* e2:expr [ \n\t]* ":" [ \n\t]* e3:expr { return { type: "select", e1: e1, e2: e2, e3: e3 } }
  / e1:primary [ \n\t]* op:("+"/"<") [ \n\t]* e2:expr { return { type: "op", op: op, e1: e1, e2: e2 } }
  / primary

primary
  = value
  / "(" [ \n\t]* e:expr [ \n\t]* ")" { return e }

command
  = c1:command_primary [ \n\t]* ";" [ \n\t]* c2:command { return { type: "seq", c1: c1, c2: c2 } }
  / c:command_primary ";"? { return c }

right_hand_side
  = "*" [ \n\t]* e:expr { return { type: "ptr-read", expr: e } }
  / ("protect_slh" / "protect_fence" / "protect") [ \n\t]* "(" [ \n\t]* r:right_hand_side ")" { return { type: "protect", arg: r } }
  / arr:([a-zA-Z][a-zA-Z0-9]*) [ \n\t]* "[" [ \n\t]* e2:expr [ \n\t]* "]" { return { type: "arr-read", arr: arr.join(""), index:e2 } }
  / e:expr { return { type: "expr", expr: e } }

command_primary
  = "skip" { return { type: "skip" } }
  / "fail" { return { type: "fail" } }
  / "if" [ \n\t]* cond:expr [ \n\t]* "then" [ \n\t]* c1:command [ \n\t]* "else" [ \n\t]* c2:command [ \n\t]* "endif" { return { type:"if", cond: cond, c1: c1, c2: c2 } }
  / "while" [ \n\t]* cond:expr [ \n\t]* "do" [ \n\t]* c:command [ \n\t]* "endwhile" { return { type:"while", cond: cond, body: c } }
  / name:([a-zA-Z][a-zA-Z0-9]*) [ \n\t]* ":=" [ \n\t]* val:right_hand_side { return { type: "asgn", name: name.join(""), value: val } }
  / name:([a-zA-Z][a-zA-Z0-9]*) [ \n\t]* "[" [ \n\t]* i:expr [ \n\t]* "]" [ \n\t]* ":=" [ \n\t]* e:expr { return { type: "arr-write", index: i, name: name.join(""), expr: e } }
  / "*" [ \n\t]* ptr:expr [ \n\t]* ":=" [ \n\t]* e:expr { return { type: "ptr-write", ptr: ptr, expr: e } }