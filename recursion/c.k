require "int-impl.k"

module C-SYNTAX
  syntax Type  ::= "int"
                 | "char"

  syntax Decl  ::= Type Exps  [klabel(decl)]


  syntax Exp   ::= Int | Id
                 | Exp "(" Exps ")"         [funcall]
                 | "++" Exp                 [prefinc]
                 | "--" Exp                 [prefdec]
                 | Exp "++"                 [ postinc]
                 | Exp "--"                 [postdec]
//                 > "-" Exp                  [prefminus]
                 > left:
                   Exp "/" Exp              [left, div]
                 | Exp "*" Exp              [left, mult]
                 | Exp "%" Exp              [left, mod]
                 > left:
                   Exp "+" Exp              [left, plus]
                 | Exp "-" Exp              [left, minus]
                 > left:
                   Exp "==" Exp             [eq]
                 | Exp "<=" Exp             [leq]
                 | Exp ">=" Exp             [geq]
                 | Exp "!=" Exp             [neq]
                 | Exp "<" Exp              [lt]
                 | Exp ">" Exp              [gt]
                 | "!" Exp                  [not]
                 > Exp "&&" Exp             [left, and]
                 > Exp "||" Exp             [left, or]
                 > left:
                   Exp "<<" Exp             [left, shiftl]
                 | Exp ">>" Exp             [left, shiftr]
                 > Exp "&" Exp              [left, andbit]
                 > Exp "|" Exp              [left, orbit]
                 | Exp "^" Exp              [left, xorbit]
                 > left:
                   Exp "=" Exp              [right, assign]
                 | Exp "+=" Exp             [right, plusassign]
                 | Exp "-=" Exp             [right, minusassign]
                 | Exp "*=" Exp             [right, multassign]
                 | Exp "/=" Exp             [right, divassign]
                 | Exp "%=" Exp             [right, modassign]
                 > "(" Exp ")"              [bracket]

  syntax Block ::= "{" "}"
                 | "{" Stmt "}"

  syntax Stmt  ::= Block
                 | "#include" "<iostream>"
                 | "if" "(" Exp ")"                 [if]
                 | Block "else" Block               [else]
                 | "while" "(" Exp ")" Block        [while]
                 | "return" Exp ";"                 [return]
                 | Decl "(" Decls ")" "{" Stmt "}"  [declfun]
                 | Decl ";"                         [klabel(declStmt), declvars]
                 > Exp ";"                         [klabel(expStmt), expstmt]
                 > Stmt Stmt                        [left]

  syntax Ids   ::= List{Id,","}
  syntax Exps  ::= List{Exp,","}
  syntax Decls ::= List{Decl,","}

  syntax Id ::= "main"
endmodule


module C
  imports C-SYNTAX
  imports INT-IMPL

  syntax Val ::= Int | Bool
               | "noVal"
               | Id "::" "function" "of" "(" Decls ")" "returning" Type "defined" "by" Stmt
                 [latex("({#1}::\\lambda{#2}\\,.\\,{#2})")]

  syntax Exp ::= Val
  syntax Vals ::= List{Val,","}

  syntax KResult ::= Val

  configuration <T color="yellow">
                  <k color="green"> $PGM:Stmt ~> startsExecution </k>
                  <env> .Map </env>
                  <genv> .Map </genv>
                  <store> .Map </store>
                  <returning> false </returning>
                  <strict> .K </strict>
                  <bind> .Map </bind>
                  <nextLoc> 0 </nextLoc>
                </T>



/*@\subsection{Declarations}
*/
  rule [decl-var-empty]:
       <k> _:Type .Ids; => . ...</k>
    [structural]

  rule [decl-var]:
       <k> T:Type ((X:Id, Xs:Exps) => Xs); ...</k>   
       <env>... .Map =>  (X |-> L) ...</env>
       <store>... .Map => (L |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  rule [decl-var-with-init-heat]:
       T:Type (X:Id = E:Exp, Xs:Exps); => E ~> T (X = HOLE, Xs);
       requires isKResult(E) =/=K true

  rule [decl-var-with-init-cool]:
       <k> T:Type ((X:Id = (HOLE => V), Xs:Exps)); ...</k>   
       <strict> V:KResult => .K </strict>
    [structural]

  rule [decl-var-with-init]:
       <k> T:Type ((X:Id = V:Val, Xs:Exps) => Xs); ...</k>   
       <env>... .Map =>  (X |-> L) ...</env>
       <store>... .Map => (L |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  syntax Val ::= initVal(Type) [function]
  rule initVal(int) => 0

  rule [decl-fun]:
       <k> T:Type F:Id ( Xs:Decls ) { Ss:Stmt } => . ...</k>
       <env>... .Map =>  (F |-> L) ...</env>
       <store>... .Map => (L |-> F :: function of ( Xs ) returning T defined by Ss ) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

// the execution of the main function

  syntax KItem ::= "startsExecution"
  rule [start-exec]:
       <k> startsExecution => main(.Vals); </k>
       <env> Env:Map </env>
       <genv> .Map => Env </genv>
    [structural]


// Expressions

  rule [heat-mult-left]:
       E1:Exp * E2:Exp => E1 ~> HOLE * E2
       requires isKResult(E1) =/=K true
    [structural]
  rule [cool-mult-left]:
       <k> HOLE * E2:Exp => V * E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-mult-right]:
       E1:Exp * E2:Exp => E2 ~> E1 * HOLE
       requires isKResult(E2) =/=K true
    [structural]
  rule [cool-mult-right]:
       <k> E1:Exp * HOLE => E1 * V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-div-left]:
       E1:Exp / E2:Exp => E1 ~> HOLE / E2
       requires isKResult(E1) =/=K true
    [structural]
  rule [cool-div-left]:
       <k> HOLE / E2:Exp => V / E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-div-right]:
       E1:Exp / E2:Exp => E2 ~> E1 / HOLE
       requires isKResult(E2) =/=K true
    [structural]
  rule [cool-div-right]:
       <k> E1:Exp / HOLE => E1 / V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-mod-left]:
       E1:Exp % E2:Exp => E1 ~> HOLE % E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-mod-left]:
       <k> HOLE % E2:Exp => V % E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-mod-right]:
       E1:Exp % E2:Exp => E2 ~> E1 % HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-mod-right]:
       <k> E1:Exp % HOLE => E1 % V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-plus-left]:
       E1:Exp + E2:Exp => E1 ~> HOLE + E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-plus-left]:
       <k> HOLE + E2:Exp => V + E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-plus-right]:
       E1:Exp + E2:Exp => E2 ~> E1 + HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-plus-right]:
       <k> E1:Exp + HOLE => E1 + V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-minus-left]:
       E1:Exp - E2:Exp => E1 ~> HOLE - E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-minus-left]:
       <k> HOLE - E2:Exp => V - E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-minus-right]:
       E1:Exp - E2:Exp => E2 ~> E1 - HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-minus-right]:
       <k> E1:Exp - HOLE => E1 - V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-leq-left]:
       E1:Exp <= E2:Exp => E1 ~> HOLE <= E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-leq-left]:
       <k> HOLE <= E2:Exp => V <= E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-leq-right]:
       E1:Exp <= E2:Exp => E2 ~> E1 <= HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-leq-right]:
       <k> E1:Exp <= HOLE => E1 <= V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-geq-left]:
       E1:Exp >= E2:Exp => E1 ~> HOLE >= E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-geq-left]:
       <k> HOLE >= E2:Exp => V >= E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-geq-right]:
       E1:Exp >= E2:Exp => E2 ~> E1 >= HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-geq-right]:
       <k> E1:Exp >= HOLE => E1 >= V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-gt-left]:
       E1:Exp > E2:Exp => E1 ~> HOLE > E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-gt-left]:
       <k> HOLE > E2:Exp => V > E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-gt-right]:
       E1:Exp > E2:Exp => E2 ~> E1 > HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-gt-right]:
       <k> E1:Exp > HOLE => E1 > V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-lt-left]:
       E1:Exp < E2:Exp => E1 ~> HOLE < E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-lt-left]:
       <k> HOLE < E2:Exp => V < E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-lt-right]:
       E1:Exp < E2:Exp => E2 ~> E1 < HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-lt-right]:
       <k> E1:Exp < HOLE => E1 < V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-neq-left]:
       E1:Exp != E2:Exp => E1 ~> HOLE != E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-neq-left]:
       <k> HOLE != E2:Exp => V != E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-neq-right]:
       E1:Exp != E2:Exp => E2 ~> E1 != HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-neq-right]:
       <k> E1:Exp != HOLE => E1 != V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-shl-left]:
       E1:Exp << E2:Exp => E1 ~> HOLE << E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-shl-left]:
       <k> HOLE << E2:Exp => V << E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-shl-right]:
       E1:Exp << E2:Exp => E2 ~> E1 << HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-shl-right]:
       <k> E1:Exp << HOLE => E1 << V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-shr-left]:
       E1:Exp >> E2:Exp => E1 ~> HOLE >> E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-shr-left]:
       <k> HOLE >> E2:Exp => V >> E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-shr-right]:
       E1:Exp >> E2:Exp => E2 ~> E1 >> HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-shr-right]:
       <k> E1:Exp >> HOLE => E1 >> V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-orbit-left]:
       E1:Exp | E2:Exp => E1 ~> HOLE | E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-orbit-left]:
       <k> HOLE | E2:Exp => V | E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-orbit-right]:
       E1:Exp | E2:Exp => E2 ~> E1 | HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-orbit-right]:
       <k> E1:Exp | HOLE => E1 | V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]


  rule [heat-andbit-left]:
       E1:Exp & E2:Exp => E1 ~> HOLE & E2
     requires isKResult(E1) =/=K true
    [structural]
  rule [cool-andbit-left]:
       <k> HOLE & E2:Exp => V & E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-andbit-right]:
       E1:Exp & E2:Exp => E2 ~> E1 & HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-andbit-right]:
       <k> E1:Exp & HOLE => E1 & V ...</k>
    <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-xorbit-left]:
       E1:Exp ^ E2:Exp => E1 ~> HOLE ^ E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-xorbit-left]:
       <k> HOLE ^ E2:Exp => V ^ E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-xorbit-right]:
       E1:Exp ^ E2:Exp => E2 ~> E1 ^ HOLE
       requires isKResult(E2) =/=K true
    [structural]
  rule [cool-xorbit-right]:
       <k> E1:Exp ^ HOLE => E1 ^ V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]


  rule [heat-not]:
       ! E:Exp  => E ~> ! HOLE
    requires isKResult(E) =/=K true
    [structural]
  rule [cool-not]:
       <k> ! HOLE  => ! V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-eq-left]:
       E1:Exp == E2:Exp => E1 ~> HOLE == E2
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-eq-left]:
       <k> HOLE == E2:Exp => V == E2 ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-eq-right]:
       E1:Exp == E2:Exp => E2 ~> E1 == HOLE
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-eq-right]:
       <k> E1:Exp == HOLE => E1 == V ...</k>
       <strict> V:KResult => .K </strict>
    [structural]


  rule [heat-and-left]:
       E1:Exp && E2:Exp => E1 ~> HOLE && E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-and-left]:
       <k> HOLE && E2:Exp => V && E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-and-right]:
       E1:Exp && E2:Exp => E2 ~> E1 && HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-and-right]:
       <k> E1:Exp && HOLE => E1 && V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [heat-or-left]:
       E1:Exp || E2:Exp => E1 ~> HOLE || E2 
    requires isKResult(E1) =/=K true
    [structural]
  rule [cool-or-left]:
       <k> HOLE || E2:Exp => V || E2 ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]
  rule [heat-or-right]:
       E1:Exp || E2:Exp => E2 ~> E1 || HOLE 
    requires isKResult(E2) =/=K true
    [structural]
  rule [cool-or-right]:
       <k> E1:Exp || HOLE => E1 || V ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

//@ Function call

  rule [fun-call]:
       <k> F:Id(Es:Exps) =>  evaluate(Xs, Es) ~> bindToThenExecute(Ss return noVal;)  ...</k>  
       <env>... F |-> L:Int ...</env>
       <store>... L |-> F :: function of ( Xs:Decls ) returning T:Type defined by Ss:Stmt ...</store>
    [transition]


//@ \texttt{bindto} binds formal parameters to actual parameters
  syntax Kitem ::= "evaluate" "(" Decls "," Exps ")"

  rule [heat-evaluate]:
       evaluate(((T:Type (X:Id, .Ids)), Xs:Decls),(E:Exp, Es:Exps))
       =>
       E ~> evaluate(((T X), Xs), (HOLE, Es))// TBD: returning type
    requires isKResult(E) =/=K true
    [structural]

  rule [cool-evaluate]:
       <k> evaluate(((T:Type (X:Id, .Ids)), Xs:Decls),((HOLE => V), Es:Exps)) ...</k>
       <strict> V:KResult => .K </strict>
    [structural]

  rule [evaluate]:
       <k> evaluate(((T:Type (X:Id, .Exps)), Xs:Decls => Xs),(V:Val, Es:Exps => Es)) ...</k>
       <bind>... .Map => X |-> V ...</bind>
    [structural]


  rule [empty-evaluate]: evaluate((.Decls), (.Exps)) => .K
    [structural]


  syntax KItem ::=  "bindToThenExecute" "(" Stmt ")"

//  rule bindToThenExecute(Ss:Stmt) => bindTo ~> execute(Ss)

  rule [bindToThenExecute]:
       <k> bindToThenExecute(Ss:Stmt) => bindTo(Ss) ~> restore(Env) ...</k>
       <env> Env:Map => GEnv </env>
       <genv> GEnv:Map </genv>

  syntax KItem ::=  bindTo(Stmt)

  rule [bindTo]:
       <k> bindTo(Ss:Stmt) ...</k>
       <bind>... X |-> V => .Map ...</bind>
       <env>... .Map => X |-> L  ...</env>
       <store>... .Map => L |-> V ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  rule [bindTo]:
       <k> bindTo(Ss:Stmt) => Ss  ...</k>
       <bind> .Map </bind>
    [structural]


//@ the execution of the function body
/*
  syntax KItem ::=  "execute" "(" Stmt ")"

  rule [exec-fun-body]:
       <k> execute(Ss:Stmt) => Ss ~> restore(Env) ...</k>
       <env> Env:Map => GEnv </env>
       <genv> GEnv:Map </genv>
    [transition]
*/

//@ restoring the environment
  syntax KItem ::=  restore(Map)

  rule [restore]:
       <k> restore(Env:Map) => V  ...</k>
       <env> _:Map => Env </env>
       <strict> V:KResult => .K </strict>
       <returning> true => false </returning>
    [transition]

// arithmetic expressions
  rule I1 / I2 => I1 /int I2
    requires I2 =/=Int 0
    [transition]
  rule I1 * I2 => I1 *int I2
    [transition]
  rule I1 % I2 => I1 %int I2
    [transition]
  rule I1 + I2 => I1 +int I2
    [transition]
  rule I1 - I2 => I1 -int I2
    [transition]

// shift operators
  rule I1 >> I2 => I1 >>int I2
    [transition]
  rule I1 << I2 => I1 <<int I2
    [transition]

// bitwise operators
  rule I1 & I2 => I1 &int I2
    [transition]
  rule I1 | I2 => I1 |int I2
    [transition]
  rule I1 ^ I2 => I1 ^int I2
    [transition]

// relational expressions
  rule [eq]:
       I1 == I2 => I1 ==int I2
    [transition]
  rule [neq]:
       I1 != I2 => I1 !=int I2
    [transition]
  rule [leq]:
       I1 <= I2 => I1 <=int I2
    [transition]
  rule [geq]:
       I1 >= I2 => I1 >=int I2
    [transition]
  rule [lt]:
       I1 < I2 => I1 <int I2
    [transition]
  rule [gt]:
       I1 > I2 => I1 >int I2
    [transition]

// boolean operators

  rule [not]:
       ! I => I ==int 0 
    [structural]
  rule [not]:
       ! B:Bool => notBool B
    [transition]

  rule [and]:
       I && B => (I !=int 0) && B
    [structural]
  rule [and]:
       B && I => B && (I !=int 0)
    [structural]
  rule [and]:
       true && B => B
    [transition]
  rule [and]:
       false && _ => false
    [transition]

  rule [or]:
       I || B => (I !=int 0) || B
    [structural]
  rule [or]:
       B || I => B || (I !=int 0)
    [structural]
  rule [or]:
       true || _ => true
    [transition]
  rule [or]:
       false || B:Bool => B
    [transition]

  rule [true]:
       true => 1
    [structural]
  rule [false]:
       false => 0
    [structural]

// variable lookup

  rule [var-lookup]:
       <k> X:Id => V ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> V:Val ...</store>
  [transition]

// 

  rule [value]:
       <k> V:Val => .K ...</k>
       <strict> _ => V </strict>
       [structural]

// assignment operators

  rule [heat-assign]:
       X:Id = E:Exp => E ~> X = HOLE 
    requires isKResult(E) =/=K true
    [structural]
  rule [cool-assign]:
       <k> X:Id = HOLE => X = V  ...</k> 
       <strict> V:KResult => .K </strict>
    [structural]

  rule [assign]:
       <k> X = V:Val => L ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> (_ => V) ...</store>
  [transition]

  rule X += E => X = X + E
    [structural]

  rule X -= E => X = X - E
    [structural]

  rule X *= E => X = X * E
    [structural]

  rule X /= E => X = X / E
    [structural]

  rule X %= E => X = X % E
    [structural]

// increment/decrement operators

  rule X++ => X = X + 1
    [structural]

  rule X-- => X = X - 1
    [structural]

  rule ++X => X = X + 1
    [structural]

  rule --X => X = X - 1
    [structural]


// Statements

  rule S1:Stmt S2:Stmt => S1 ~> S2
    [structural]

  rule [heat-exp-stmt]:
       E:Exp; => E ~> HOLE:Exp; 
    requires isKResult(E) =/=K true
    [structural]
  rule [cool-exp-stmt]:
       <k> HOLE:Exp; => V; ...</k>
       <strict> V:Val => .K </strict>
    [structural]
  rule [exp-stmt]:
       V:Val; => .K
  [transition]

  rule [heat-if]:
       if (E2) S1 else S2 => E2 ~> if (HOLE) S1 else S2
       requires isKResult(E2) =/=K true
    [transition]
  rule [cool-if]:
       <k> if (HOLE) S1 else S2 => if (V) S1 else S2 ...</k>
       <strict> V:KResult => .K </strict>
    [transition]
  rule [if-true]:
       if ( I ) S1:Block else _:Block  => S1 
    requires I !=int 0
    [transition]
  rule [if-false]:
       if ( I ) _:Block else S2:Block => S2  
    requires I ==int 0
    [transition]

  rule [while]:
       while ( E:Exp ) S:Block
       =>
       if ( E ) { S  while ( E:Exp ) S }  else {}
    [structural]

  rule [heat-return]:
       return E:Exp; => E ~> return HOLE;
    requires isKResult(E) =/=K true
    [structural]
  rule [cool-return]:
       <k> return HOLE; => return V; ...</k>
       <strict> V:KResult => .K </strict>
    [structural]
  rule [return]:
       <k> return V:Val; => .K ...</k>
       <strict> .K => V </strict>
       <returning> false => true </returning>
  [transition]

  rule [clean-kcell]:
       <k> KL:KLabel(_) => .K ...</k>
       <returning> true </returning>
    requires KL =/=KLabel 'restore
    [transition]

endmodule
