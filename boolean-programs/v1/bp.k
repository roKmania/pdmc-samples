module EBOOL

//@ booleans extended with "*"

  syntax EBool ::= "True" | "False" | "*"
                 | "notEBool" EBool [function]
                 > EBool "orEBool" EBool [function]
                 | EBool "andEBool" EBool [function]
                 > EBool "==EBool" EBool [function]
                 | EBool "=/=EBool" EBool [function]

  rule False orEBool B:EBool => B
  rule True orEBool _:EBool => True
  rule * orEBool _:EBool => *

  rule B:EBool orEBool False => B
  rule _:EBool orEBool True => True
  rule _:EBool orEBool  * => *

  rule True andEBool B:EBool => B
  rule False andEBool _:EBool => False
  rule * andEBool _:EBool => *

  rule B:EBool andEBool True => B
  rule _:EBool andEBool False => False
  rule _:EBool andEBool  * => *

  rule True ==EBool True => True
  rule False ==EBool False => True
  rule _:EBool ==EBool * => *
  rule * ==EBool _:EBool => *
  rule True ==EBool False => False
  rule False ==EBool True => False

  rule notEBool True => False
  rule notEBool False => True
  rule notEBool * => *

  rule B1:EBool =/=EBool B2:EBool => notEBool (B1 ==EBool B2)

  syntax String ::= EBool2String(EBool) [function]
  rule EBool2String(True) => "True"
  rule EBool2String(False) => "False"
  rule EBool2String(*) => "*"

endmodule


module BP-SYNTAX 
  imports EBOOL

  /*@ \subsubsection*{Expressions} */

  syntax Exp ::= EBool | Id 
               | "(" Exp ")" [bracket]
               | Exp "(" Exps ")"
               > "!" Exp
               > Exp "==" Exp [left] 
               | Exp "!=" Exp [left]
               > Exp "&&" Exp [left]
               | Exp "||" Exp [left]
               > Exp "->" Exp [left]

  syntax Id ::= "main"

  /*@ \subsubsection*{Statements} */
  syntax UnlbldStmt ::= "skip" ";"
               | "{" Stmts "}"
               > "decl" Ids ";"
               | Id "(" Ids ")" "{" Stmts "}"
               > "return" ";"
               > "return" Exp ";"
               | "if" "(" Exp ")" Stmt "else" Stmt
               | "while" "(" Exp ")" Stmt
               | Exp ";"
//               | "print" "(" Exps ")" ";"
               | "goto" Id ";"
               > Id "=" Exp ";" 

  syntax LbldStmt ::= Id ":" Stmt 

  syntax Stmt ::= UnlbldStmt | LbldStmt

  /*@ \subsubsection*{Programs} */
  syntax Pgm ::=  Stmts

  /*@ \subsubsection*{Lists} */
  syntax Stmts ::= Stmt
                 | Stmts Stmts  [right]

  syntax Ids ::= List{Id,","}
  syntax Exps ::= List{Exp,","}


endmodule

module BP
  imports BP-SYNTAX

  syntax Val ::= EBool
               | Id "::" "lambda" "(" Ids "," Stmts ")"
                     [latex("({#1}::\\lambda{#2}\\,.\\,{#2})")]

  syntax Exp ::= Val
  syntax Vals ::= List{Val,","}

  syntax KResult ::= Val


  configuration
    <T>
      <k> $PGM:K ~> startsExecution </k>
      <env> .Map </env>
      <genv> .Map </genv>
      <store> .Map </store>
      <strict> .K </strict>
      <crnt-function> .Map </crnt-function> 
      <returning> false </returning>
    </T>


/*@\subsection{Declarations}
*/
  rule <k> decl .Ids; => . ...</k> [structural]

  rule <k> decl ((X:Id, Xs:Ids) => Xs); ...</k>
       <env>... .Map =>  (X |-> !L:Int) ...</env>
       <store>... .Map => (!L:Int |-> *) ...</store>
  [structural]

  rule <k> F:Id ( Xs:Ids ) { Ss:Stmts } => . ...</k>
       <env>... .Map =>  (F |-> !L:Int) ...</env>
       <store>... .Map => (!L:Int |-> F :: lambda ( Xs , Ss )) ...</store>
  [structural]

// the execution of the main function

  syntax KItem ::= "startsExecution"
  rule <k> startsExecution => main(.Vals) </k>
       <env> Env:Map </env>
       <genv> .Map => Env </genv> 
  [structural]


// Expressions

  rule ! E:Exp  => E ~> ! HOLE
       requires isKResult(E) =/=K true [structural]
  rule <k> ! HOLE  => ! V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule E1:Exp == E2:Exp => E1 ~> HOLE == E2
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE == E2:Exp => V == E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule E1:Exp == E2:Exp => E2 ~> E1 == HOLE
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Exp == HOLE => E1 == V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule E1:Exp != E2:Exp => E1 ~> HOLE != E2
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE != E2:Exp => V != E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule E1:Exp != E2:Exp => E2 ~> E1 != HOLE
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Exp != HOLE => E1 != V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule E1:Exp && E2:Exp => E1 ~> HOLE && E2
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE && E2:Exp => V && E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule E1:Exp && E2:Exp => E2 ~> E1 && HOLE
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Exp && HOLE => E1 && V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule E1:Exp || E2:Exp => E1 ~> HOLE || E2
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE || E2:Exp => V || E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule E1:Exp || E2:Exp => E2 ~> E1 || HOLE
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Exp || HOLE => E1 || V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> F:Id(Es:Exps) =>  bindto(Xs, Es) ~> execute(Ss return;)  ...</k>
       <env>... F |-> L:Int ...</env>
       <store>... L |-> F :: lambda(Xs:Ids, Ss:Stmts) ...</store>


//@ \texttt{bindto} binds formal parameters to actual parameters 
  syntax Kitem ::= "bindto" "(" Exps "," Exps ")"

  rule bindto((X:Id, Xs:Ids),(E:Exp, Es:Exps)) => E ~> bindto((X, Xs), (HOLE, Es))
       requires isKResult(E) =/=K true
  [structural] 

  rule <k> bindto((X:Id, Xs:Ids => Xs),(HOLE, Es:Exps => Es)) ...</k>
       <env>... .Map => X |-> !L:Int  ...</env>
       <store>... .Map => !L:Int |-> V ...</store>
       <strict> V:KResult => .K </strict>
  [structural]

  rule bindto((.Exps), (.Exps)) => .K 
  [structural]

//@ the execution of the function body

  syntax KItem ::=  "execute" "(" Stmts ")"
  rule <k> execute(Ss:Stmts) => startLoad(Ss) ~> restore(Env, CF) ...</k>
       <env> Env:Map => GEnv </env>
       <genv> GEnv:Map </genv>
       <crnt-function> CF:Map => .Map </crnt-function>
  [structural]

  syntax KItem ::=  "startLoad" "(" Stmts ")"
  rule startLoad(Ss:Stmts) => loadSegment(Ss) ~> Ss
  [structural]

  syntax KItem ::=  "loadSegment" "(" K ")"
  rule loadSegment(((Ss1:Stmts Ss2:Stmts) => (Ss1 ~> Ss2)) ~> _)
  [structural]
  rule loadSegment({Ss1:Stmts}~> Ss2:K) => loadSegment(Ss1 ~> Ss2)
  [structural]
  rule loadSegment(decl _; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(return; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(return _; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(_; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(goto _; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(_=_; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(if (_) S1:Stmt else S2 ~> Ss:K) => loadSegment(S1 ~> Ss) ~> loadSegment(S2 ~> frozen(Ss))
  [structural]
  rule loadSegment(while (E:Exp) S:Stmt ~> Ss:K) => loadSegment(S ~> frozen(while (E) S) ~> Ss)
  [structural]
  rule loadSegment(skip; ~> Ss:K) => loadSegment(Ss)
  [structural]
  rule loadSegment(.K) => .K
  [structural]

  syntax KItem ::= frozen(K)
  rule loadSegment(frozen(_) ~> Ss:K) => loadSegment(Ss)
  [structural]

  syntax K ::= unfreeze(K) [function]
  rule unfreeze(S:Stmt ~> Ss:K) => S ~> unfreeze(Ss)
  rule unfreeze(frozen(Ss1:K) ~> Ss2:K) => Ss1 ~> unfreeze(Ss2)
  rule unfreeze(.K) => .K

  rule <k> loadSegment(Lbl:Id : S:Stmt ~> Ss:K) => loadSegment(S ~> Ss) ...</k>
       <crnt-function>... .Map => Lbl |-> unfreeze(S ~> Ss) </crnt-function>
  [structural]

//@ restoring the environment
  syntax KItem ::=  restore(Map, Map)

  rule <k> restore(Env:Map, CF:Map) => V  ...</k>
       <env> _ => Env </env>
       <crnt-function> _ => CF </crnt-function>
       <strict> V:KResult => .K </strict>
       <returning> true => false </returning>

// Boolean operators

  rule B1:EBool || B2:EBool => B1 orEBool B2
  rule B1:EBool && B2:EBool => B1 andEBool B2
  rule B1:EBool == B2:EBool => B1 ==EBool B2
  rule B1:EBool != B2:EBool => B1 =/=EBool B2
  rule ! B:EBool => notEBool B
  rule B1:EBool -> B2:EBool => ! B1 || B2 [structural]


// Statements

  rule Ss1:Stmts Ss2:Stmts => Ss1 ~> Ss2 [structural]

  rule skip; => .K

  rule Lbl:Id : S:Stmt => S

  rule { Ss:Stmts } => Ss [structural]

  rule <k> goto Lbl:Id; => Ss ...</k>
       <crnt-function>... Lbl |-> Ss:K ...</crnt-function>

  rule <k> X:Id => V ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> V:EBool ...</store>

  rule <k> V:EBool => .K ...</k>
       <strict> _ => V </strict>
  [structural]

  rule X:Id = E:Exp; => E ~> X = HOLE;
       requires isKResult(E) =/=K true [structural]
  rule <k> X:Id = HOLE; => X = V; ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> X = V:EBool; => .K ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> (_ => V) ...</store>


  rule E:Exp; => E ~> HOLE;
       requires isKResult(E) =/=K true [structural]
  rule <k> HOLE; => V; ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule * => True 
  rule * => False

  rule if (E2) S1 else S2 => E2 ~> if (HOLE) S1 else S2 
       requires isKResult(E2) =/=K true
  rule <k> if (HOLE) S1 else S2 => if (V) S1 else S2 ...</k> 
       <strict> V:KResult => .K </strict>

  rule if ( True ) S1:Stmt else _:Stmt  => S1 
  rule if ( False ) _:Stmt else S2:Stmt => S2

  rule if ( * ) S1:Stmt else _:Stmt  => S1 
  rule if ( * ) _:Stmt else S2:Stmt => S2

  rule while ( E:Exp ) S:Stmt 
       =>
       if ( E ) { S  while ( E:Exp ) S }  else skip;
  [structural]

  rule return; => return *;
 
  rule return E:Exp; => E ~> return HOLE;
       requires isKResult(E) =/=K true [structural]
  rule <k> return HOLE; => return V; ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> return V:Val; => .K ...</k>
       <strict> _ => V </strict>
       <crnt-function> _ => .Map </crnt-function>
       <returning> _ => true </returning>

  rule <k> KL:KLabel(_) => .K ...</k>
       <returning> true </returning>
  requires KL =/=KLabel 'restore

  rule V:Val; => .K


  syntax Bool ::= Bag "||=" String [function]
//  syntax Id ::= Token{"x"}
  rule <generatedTop>...
         <env>... X:Id |-> L:Int ...</env>
         <store> Store:Map </store> 
       ...</generatedTop>
       ||=
       S:String
       => (Id2String(X) +String "Is" +String EBool2String(Store[L])) ==String S

  rule <generatedTop>...
         <k> Lbl:Id : _:Stmt  ...</k>  
       ...</generatedTop>
       ||=
       S:String
       =>
       Id2String(Lbl) ==String S

  syntax Bool ::= Bag "|=" String [function]
  rule <generatedTop> B </generatedTop> |= S:String 
       =>
       (<generatedTop> B </generatedTop> ||= S) ==K true

endmodule

