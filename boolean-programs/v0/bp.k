module EBOOL

//@ booleans extended with "*"

  syntax EBool ::= "True" | "False" | "*"
                 | "notEBool" EBool [function]
                 > EBool "orEBool" EBool [function]
                 | EBool "andEBool" EBool [function]
                 > EBool "==EBool" EBool [function]
                 | EBool "=/=EBool" EBool [function]

  syntax Bool ::= EBool "<=EBool" EBool [function]

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

  rule E:EBool <=EBool E => true
  rule _:EBool <=EBool * => true
  rule True <=EBool False => false
  rule False <=EBool True => false
  rule * <=EBool False => false
  rule * <=EBool True => false

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
//               > "return" ";"
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

  syntax LtlFormula ::= Bool


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
      <returning> false </returning>
      <strict> .K </strict>
      <nextLoc> 0 </nextLoc>
    </T>


/*@\subsection{Declarations}
*/
  rule [decl-var-empty]:
       <k> decl .Ids; => . ...</k> [structural]

  rule [decl-var]:
       <k> decl ((X:Id, Xs:Ids) => Xs); ...</k>
       <env>... .Map =>  (X |-> L) ...</env>
       <store>... .Map => (L |-> *) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
  [structural]

  rule [decl-fun]:
       <k> F:Id ( Xs:Ids ) { Ss:Stmts } => . ...</k>
       <env>... .Map =>  (F |-> L) ...</env>
       <store>... .Map => (L |-> F :: lambda ( Xs , Ss )) ...</store>
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

  rule [heat-not]:
       ! E:Exp  => E ~> ! HOLE requires isKResult(E) =/=K true [structural]
  rule [cool-not]:
       <k> ! HOLE  => ! V ...</k> <strict> V:KResult => .K </strict> [structural]

  rule [heat-eq-left]:
       E1:Exp == E2:Exp => E1 ~> HOLE == E2 requires isKResult(E1) =/=K true [structural]
  rule [cool-eq-left]:
       <k> HOLE == E2:Exp => V == E2 ...</k> <strict> V:KResult => .K </strict> [structural]
  rule [heat-eq-right]:
       E1:Exp == E2:Exp => E2 ~> E1 == HOLE requires isKResult(E2) =/=K true [structural]
  rule [cool-eq-right]:
       <k> E1:Exp == HOLE => E1 == V ...</k> <strict> V:KResult => .K </strict> [structural]

  rule [heat-neq-left]:
       E1:Exp != E2:Exp => E1 ~> HOLE != E2 requires isKResult(E1) =/=K true [structural]
  rule [cool-neq-left]:
       <k> HOLE != E2:Exp => V != E2 ...</k> <strict> V:KResult => .K </strict> [structural]
  rule [heat-neq-right]:
       E1:Exp != E2:Exp => E2 ~> E1 != HOLE requires isKResult(E2) =/=K true [structural]
  rule [cool-neq-right]:
       <k> E1:Exp != HOLE => E1 != V ...</k> <strict> V:KResult => .K </strict> [structural]

  rule [heat-and-left]:
       E1:Exp && E2:Exp => E1 ~> HOLE && E2 requires isKResult(E1) =/=K true [structural]
  rule [cool-and-left]:
       <k> HOLE && E2:Exp => V && E2 ...</k> <strict> V:KResult => .K </strict> [structural]
  rule [heat-and-right]:
       E1:Exp && E2:Exp => E2 ~> E1 && HOLE requires isKResult(E2) =/=K true [structural]
  rule [cool-and-right]:
       <k> E1:Exp && HOLE => E1 && V ...</k> <strict> V:KResult => .K </strict> [structural]

  rule [heat-or-left]:
       E1:Exp || E2:Exp => E1 ~> HOLE || E2 requires isKResult(E1) =/=K true [structural]
  rule [cool-or-left]:
       <k> HOLE || E2:Exp => V || E2 ...</k> <strict> V:KResult => .K </strict> [structural]
  rule [heat-or-right]:
       E1:Exp || E2:Exp => E2 ~> E1 || HOLE requires isKResult(E2) =/=K true [structural]
  rule [cool-or-right]:
       <k> E1:Exp || HOLE => E1 || V ...</k> <strict> V:KResult => .K </strict> [structural]


  rule [fun-call]:
       <k> F:Id(Es:Exps) =>  bindto(Xs, Es) ~> execute(Ss return * ;)  ...</k>
       <env>... F |-> L:Int ...</env>
       <store>... L |-> F :: lambda(Xs:Ids, Ss:Stmts) ...</store>
  [transition]


//@ \texttt{bindto} binds formal parameters to actual parameters
  syntax Kitem ::= "bindto" "(" Exps "," Exps ")"

  rule [heat-bindto]:
       bindto((X:Id, Xs:Ids),(E:Exp, Es:Exps)) => E ~> bindto((X, Xs), (HOLE, Es))
       requires isKResult(E) =/=K true
  [structural]

  rule [cool-bindto]:
       <k> bindto((X:Id, Xs:Ids => Xs),(HOLE, Es:Exps => Es)) ...</k>
       <env>... .Map => X |-> L  ...</env>
       <store>... .Map => L |-> V ...</store>
       <strict> V:KResult => .K </strict>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
  [structural]

  rule [empty-bindto]: bindto((.Exps), (.Exps)) => .K
  [structural]

//@ the execution of the function body

  syntax KItem ::=  "execute" "(" Stmts ")"

  rule [exec-fun-body]:
       <k> execute(Ss:Stmts) => Ss ~> restore(Env) ...</k>
       <env> Env:Map => GEnv </env>
       <genv> GEnv:Map </genv>
  [transition]

//@ restoring the environment
  syntax KItem ::=  restore(Map)

  rule [restore]:
       <k> restore(Env:Map) => V  ...</k>
       <env> _:Map => Env </env>
       <strict> V:KResult => .K </strict>
       <returning> true => false </returning>
  [transition]

// Boolean operators

  rule [or]:
       B1:EBool || B2:EBool => B1 orEBool B2
  [transition]
  rule [and]:
       B1:EBool && B2:EBool => B1 andEBool B2
  [transition]
  rule [eq]:
       B1:EBool == B2:EBool => B1 ==EBool B2
  [transition]
  rule [neq]:
       B1:EBool != B2:EBool => B1 =/=EBool B2
  [transition]
  rule [not]:
       ! B:EBool => notEBool B
  [transition]
  rule [impl]:
       B1:EBool -> B2:EBool => ! B1 || B2 [structural]


// Statements

  rule [seq]:
       Ss1:Stmts Ss2:Stmts => Ss1 ~> Ss2 [structural]

  rule [skip]:
       skip; => .K
  [transition]

  rule [lbld-stmt]:
       Lbl:Id : S:Stmt => S
  [transition]

  rule [block]:
       { Ss:Stmts } => Ss [structural]

  rule [var-lookup]:
       <k> X:Id => V ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> V:EBool ...</store>
  [transition]

  rule [value]:
       <k> V:EBool => .K ...</k>
       <strict> _ => V </strict>
       [structural]

  rule [heat-assign]:
       X:Id = E:Exp; => E ~> X = HOLE; requires isKResult(E) =/=K true [structural]
  rule [cool-assign]:
       <k> X:Id = HOLE; => X = V; ...</k> <strict> V:KResult => .K </strict> [structural]

  rule [assign]:
       <k> X = V:EBool; => .K ...</k>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> (_ => V) ...</store>
  [transition]


  rule [heat-exp-stmt]:
       E:Exp; => E ~> HOLE; requires isKResult(E) =/=K true [structural]
  rule [cool-exp-stmt]:
       <k> HOLE; => V; ...</k> <strict> V:KResult => .K </strict> [structural]
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
       if ( B:EBool ) S1:Stmt else _:Stmt  => S1 requires True <=EBool B
  [transition]
  rule [if-false]:
       if ( B:EBool ) _:Stmt else S2:Stmt => S2  requires False <=EBool B
  [transition]

  rule [while]:
       while ( E:Exp ) S:Stmt
       =>
       if ( E ) { S  while ( E:Exp ) S }  else skip;
  [structural]

//  rule return; => return *;

  rule [heat-return]:
       return E:Exp; => E ~> return HOLE; requires isKResult(E) =/=K true [structural]
  rule [cool-return]:
       <k> return HOLE; => return V; ...</k> <strict> V:KResult => .K </strict> [structural]
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


  syntax EBool ::= getBoolValue(String) [function]
  rule getBoolValue(S:String) => True
    requires "True" ==String substrString(S, lengthString(S) -Int 4, lengthString(S))
  rule getBoolValue(S:String) => False
    requires "False" ==String substrString(S, lengthString(S) -Int 5, lengthString(S))

  syntax Id ::= getId(String) [function]
  rule getId(S:String) => String2Id(substrString(S, 0, lengthString(S) -Int 6))
    requires "IsTrue" ==String substrString(S, lengthString(S) -Int 6, lengthString(S))
  rule getId(S:String) => String2Id(substrString(S, 0, lengthString(S) -Int 7))
    requires "IsFalse" ==String substrString(S, lengthString(S) -Int 7, lengthString(S))

  syntax Bool ::= Bag "||=" String [function]
//  syntax Id ::= Token{"x"}
  rule <generatedTop> <T>... <env> Env:Map </env> <store> Store:Map </store> ...</T> </generatedTop>
       ||=
       S:String
       => true
    requires True <=EBool (getValue(Env, Store, getId(S)) ==EBool getBoolValue(S))


  syntax KItem ::= getValue(Map, Map, Id)  [function]
  rule getValue(X |-> L _:Map, Store:Map, X) => getValueS(Store, L)
  syntax KItem ::= getValueS(Map, K)  [function]
  rule getValueS(L |-> V _:Map, L) => V

  rule <generatedTop> <T>...
         <k> Lbl:Id : _:Stmt  ...</k>
       ...</T> </generatedTop>
       ||=
       S:String
       => true
    requires Id2String(Lbl) ==String S

  rule <generatedTop> B </generatedTop> ||= S:String => false [owise]


  syntax Bool ::= Bag "|=" String [function]
  rule <generatedTop> B </generatedTop> |= S:String
    => <generatedTop> B </generatedTop> ||= S

endmodule

