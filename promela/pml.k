module PML-SYNTAX


/*
spec	: module [ module ] *
*/

//syntax Spec ::= List{Module, ""}
syntax Spec ::= Module | Spec Spec [right, seqspec]

/*
module	: proctype	// proctype declaration \\
	| init		// init process       \\
	| never		// never claim        \\
	| trace		// event trace        \\
	| utype		// user defined types \\
	| mtype		// mtype declaration  \\
	| decl_lst	// global vars, chans \\
*/

// partial defined
  syntax Module ::=
       Proctype
     | Init
     | Mtype
     | Decl ";"  [declmod]

/*
proctype: [ active ] PROCTYPE name '(' [ decl_lst ]')'
	  [ priority ] [ enabler ] '{' sequence '}'
*/

//partial defined
  syntax Proctype ::=
       "proctype" Id "(" DeclList ")" "{" Sequence "}"
//     |  "proctype" Id "(" ")" "{" Sequence "}"

/*
init	: INIT [ priority ] '{' sequence '}'
*/

// partial defined
  syntax Init ::= "init" "{" Sequence "}"

/*
never	: NEVER	'{' sequence '}'

trace	: TRACE '{' sequence '}'

utype	: TYPEDEF name '{' decl_lst '}'

mtype	: MTYPE [ '=' ] '{' name [ ',' name ] * '}'
*/

  syntax Mtype ::=
       "mtype" "{" Ids "}"
     | "mtype" "="  "{" Ids "}"

  syntax Ids ::= List{Id, ","}

/*
decl_lst: one_decl [ ';' one_decl ] *
*/

  syntax DeclList ::= List{Decl, ";"}
//  syntax DeclList ::= Decl | DeclList ";" DeclList [right]

/*
one_decl: [ visible ] typename  ivar [',' ivar ] *

typename: BIT | BOOL | BYTE | SHORT | INT | MTYPE | CHAN
	| uname	// user defined type names (see utype) \\
*/

//partial defined
  syntax Decl ::= 
      Typename Id     [decl]
     | Typename Id "=" Expr 
     | Typename Id "=" ChInit
     | Typename Id "[" Int "]"
     | Typename Id "[" Int "]" "=" Expr
     | Typename Id "[" Int "]" "=" ChInit

//  syntax IvarList ::= List{Ivar, ","}

  syntax Typename ::=
       "int"
     | "bool"
     | "chan"


/*
active  : ACTIVE [ '[' const ']' ]	// instantiation \\

priority: PRIORITY const	// simulation priority \\

enabler : PROVIDED '(' expr ')'	// execution constraint \\

visible	: HIDDEN | SHOW

sequence: step [ ';' step ] *
*/

   syntax Sequence ::= List{Step, ";"}


/*
step    : stmnt	[ UNLESS stmnt ]
	| decl_lst
	| XR varref [',' varref ] *
	| XS varref [',' varref ] *
*/

// partial defined
  syntax Step ::=
       Stmt
     | DeclList

/*
ivar    : name [ '[' const ']' ] [ '=' any_expr | '=' ch_init ]

ch_init : '[' const ']' OF '{' typename [ ',' typename ] * '}'
*/

// partial defined
  syntax ChInit ::= 
       "of" TypenameList

//  syntax TypenameList ::= List{Typename, ","}
  syntax TypenameList ::= Typename | TypenameList "," TypenameList [right]

/*
varref	: name [ '[' any_expr ']' ] [ '.' varref ]
*/

  syntax Varref ::= 
       Id
     | Id "[" Expr "]"

/*
send    : varref '!' send_args		// normal fifo send \\
	| varref '!' '!' send_args	// sorted send \\
*/

// partial defined
  syntax Send ::= Varref "!" ExprList

/*
receive : varref '?' recv_args		// normal receive \\
	| varref '?' '?' recv_args	// random receive \\
	| varref '?' '<' recv_args '>'	// poll with side-effect \\
	| varref '?' '?' '<' recv_args '>'	// ditto \\
*/

// partial defined
  syntax Receive ::= Varref "?" VarrefList
  syntax VarrefList ::= List{Varref, ","}

/*
poll    : varref '?' '[' recv_args ']'	// poll without side-effect \\
	| varref '?' '?' '[' recv_args ']'	// ditto \\

send_args: arg_lst | any_expr '(' arg_lst ')'

arg_lst  : any_expr [ ',' any_expr ] *
*/

  syntax ExprList ::= List{Expr, ","}

/*
recv_args: recv_arg [ ',' recv_arg ] *  |  recv_arg '(' recv_args ')'

recv_arg : varref | EVAL '(' varref ')' | [ '-' ] const
*/

  syntax Recvarg ::=
       Varref
     | Const 

  syntax RecvargList ::= List{Recvarg, ","}

/*
assign  : varref '=' any_expr	// standard assignment \\
	| varref '+' '+'	// increment \\
	| varref '-' '-'	// decrement \\
*/

  syntax Assign ::=
       Varref "=" Expr [assign]
     | Varref "++" [inc]
     | Varref "--" [dec]

/*
stmnt	: IF options FI		// selection \\
	| DO options OD		// iteration \\
	| FOR '(' range ')' '{' sequence '}'		// iteration \\
	| ATOMIC '{' sequence '}'	// atomic sequence \\
	| D_STEP '{' sequence '}'	// deterministic atomic \\
	| SELECT '(' range ')'	// non-deterministic value selection \\
	| '{' sequence '}'	// normal sequence \\
	| send
	| receive
	| assign
	| ELSE			// used inside options \\
	| BREAK			// used inside iterations \\
	| GOTO name
	| name ':' stmnt	// labeled statement \\
	| PRINT '(' string [ ',' arg_lst ] ')'
	| ASSERT expr    
	| expr			// condition \\
	| c_code '{' ... '}'	// embedded C code \\
	| c_expr '{' ... '}'
	| c_decl '{' ... '}'
	| c_track '{' ... '}'
	| c_state '{' ... '}'
*/

// partial defined
    syntax Stmt ::= 
      Expr
     | Send
     | Receive
     | Assign
     | "else"
     | "break"
     | "print" "(" String ")"
     | "print" "(" String "," ExprList ")"
     | "assert" Expr
     > "if" OptionList "fi"
     | "do" OptionList "od"
     | "atomic" "{" Sequence "}"
     | "{" Sequence "}"
     | Id ":" Stmt


/*
range	: varref ':' expr '..' expr
	| varref IN varref

options : ':' ':' sequence [ ':' ':' sequence ] *
*/

  syntax Option ::= "::" Sequence 
//  syntax OptionList ::= List{Option, ""}
  syntax OptionList ::= Option | OptionList OptionList [right]

/*
andor	: '&' '&' | '|' '|'

binarop	: '+' | '-' | '*' | '/' | '%' | '&' | '^' | '|'
	| '>' | '<' | '>' '=' | '<' '=' | '=' '=' | '!' '='
	| '<' '<' | '>' '>' | andor

unarop	: '~' | '-' | '!'

any_expr: '(' any_expr ')'
	| any_expr binarop any_expr
	| unarop any_expr
	| '(' any_expr '-' '>' any_expr ':' any_expr ')'
	| LEN '(' varref ')'	// nr of messages in chan \\
	| poll
	| varref
	| const 
	| TIMEOUT
	| NP_			// non-progress system state \\
	| ENABLED '(' any_expr ')'		// refers to a pid \\
	| PC_VALUE '(' any_expr ')'		// refers to a pid \\
	| name '[' any_expr ']' '@' name	// refers to a pid \\
	| RUN name '(' [ arg_lst ] ')' [ priority ]
	| get_priority( expr )			// expr refers to a pid \\
	| set_priority( expr , expr )		// first expr refers to a pid \\

expr	: any_expr
	| '(' expr ')'
	| expr andor expr
	| chanpoll '(' varref ')'	// may not be negated \\

chanpoll: FULL | EMPTY | NFULL | NEMPTY

string	: '"' [ any_ascii_char ] * '"'

uname	: name

name	: alpha [ alpha | number ] *

const	: TRUE | FALSE | SKIP | number [ number ] *
*/

  syntax Const ::= Int | Bool | "skip"

  syntax Expr ::=
       Varref
     | Const
     | "_pid"
     | "timeout"
     | "np_"
     | "(" Expr ")" [bracket]
     > "!" Expr
     | "run" Id "(" ExprList ")"
     | "run" Id "[" Int "]" "(" ExprList ")" 
     > Expr "*" Expr [left, mult]
     | Expr "/" Expr [left, div]
     | Expr "%" Expr [left, mod]
     > Expr "+" Expr [left, plus]
     | Expr "-" Expr [left, minus]
     > Expr "==" Expr [left, eq] 
     | Expr "!=" Expr [left, neq]
     | Expr "<=" Expr [left, leq]
     | Expr ">=" Expr [left, geq]
     | Expr "<" Expr [left, lt]
     | Expr ">" Expr [left, gt]
     > Expr "&&" Expr [left, and]
     | Expr "||" Expr [left, or]


/////// old stuf ////

/*
  syntax Val ::= Int | Bool

  syntax Exp ::=
       Id
     | Val
     | "_pid"
     | "(" Exp ")" [bracket]
     > "!" Exp
     | "run" Id "(" Exps ")"
     | "printf" "(" String ")"
     | Id "[" Exp "]" 
     | Id "++"  
     | Id "--"  
     > Exp "*" Exp [left]
     | Exp "/" Exp [left]
     | Exp "%" Exp [left]
     > Exp "+" Exp [left]
     | Exp "-" Exp [left]
     > Exp "==" Exp [left] 
     | Exp "!=" Exp [left]
     | Exp "<=" Exp [left]
     | Exp ">=" Exp [left]
     | Exp "<" Exp [left]
     | Exp ">" Exp [left]
     > Exp "&&" Exp [left]
     | Exp "||" Exp [left]
     > Id "?" Exps 
     | Id "!" Exps 
     | "[" Int "]" "of" "{" Ids "}"
     > Id "=" Exp 
     > Id "[" Exp "]" "=" Exp 


  syntax Ids ::= List{Id, ","}
  syntax Exps ::= List{Exp, ","}
//  syntax ExpSeq ::= List{Exp, ";"}

  syntax ExpSeq ::= Exp | Exp ";" ExpSeq


  syntax Decl ::=
       "int" Exps
     | "bool" Exps
     | "chan" Exps
     | "mtype" "=" "{" Ids "}"

  syntax DeclSeq ::= List{Decl, ";"}

  syntax Stmt ::= 
       Decl ";"
     | ExpSeq
     | "proctype" Id "(" DeclSeq ")" "{" Stmts "}"
     | "init" "{" Stmts "}"
     | Exp "->" Stmt
     | "::" Stmts
     | "if" Stmts "fi" ";"
     | "do" Stmts "od" ";"
     > Id ":" Stmt

  syntax Stmts ::= List{Stmt, ""}
*/

endmodule

module PML
  imports PML-SYNTAX

  configuration
    <k> $PGM:Spec /* ~> executeInit */ </k>
    <genv> .Map </genv>
    <procs> 
      <proc multiplicity="*">
        <pid> 0 </pid>
        <kproc> .K </kproc>
        <env> .Map </env>
      </proc>
    </procs>
    <strict> .K </strict>
    <store> .Map </store>
    <crntProc> 0 </crntProc> 
    <waitForStateChange> .List </waitForStateChange>
    <nextLoc> 0 </nextLoc>
    <nextProc> 0 </nextProc>

  syntax KResult ::= Const      

  rule S1:Spec S2:Spec => S1 ~> S2
  rule <kproc> S1:Spec S2:Spec => S1 ~> S2 </kproc>
/*
  rule D:Decl ; Ds:Decls => D ~> Ds
  rule <kproc> D:Decl ; Ds:Decls => D ~> Ds </kproc>

  rule int .Exps ; =>  .K
  rule <kproc> int .Exps ; =>  .K </kproc>

  rule <k> int ((X:Expr, Es:ExprList) => Es); ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> 0) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]

  rule <k> bool ((X:Expr, Es:ExprList) => Es); ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> false) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]

  rule <k> int ((X:Id = V:Const, Es:ExprList) => Es); ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]

  rule <k> int ((X:Expr, Es:ExprList) => Es); ...</k>
       <env>... .Map =>  (X |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> 0) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]

  rule <k> bool ((X:Expr, Es:ExprList) => Es); ...</k>
       <env>... .Map =>  (X |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> false) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]

  rule <k> int ((X:Id = V:Const, Es:ExprList) => Es); ...</k>
       <env>... .Map =>  (X |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires isId(X) ==K true
    [structural]
*/

  syntax Const ::= initVal(Typename) [function]
  rule initVal(int) => 0
  rule initVal(bool) => false

  rule <k> T:Typename X:Id; => .K ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  rule <k> T:Typename X:Id[N:Int]; => alloc(N, X, T) ...</k>

  syntax KItem ::= alloc(Int, Id, Typename)

  rule <k> alloc((N:Int => N -Int 1) , X:Id, T:Typename) ...</k>
       <genv>... .Map =>  (X[N -Int 1] |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires N >Int 0
    [structural]

  rule <k> alloc(0 , _:Id, _:Typename) => .K ...</k>

  rule <k> T:Typename X:Id = V:Const; => .K ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]


  syntax KItem ::= lambda(DeclList, Sequence)

  rule <k> proctype P:Id ( Xs:DeclList ) { Ss:Sequence } => .K ...</k>
       <genv>... .Map =>  (P |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> lambda ( Xs , Ss )) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]


//  syntax KItem ::= "executeInit"

  rule <k> init { Ss:Sequence } => Ss ...</k>
       <nextProc> PID => PID +Int 1 </nextProc>
       <procs>...
          (.Bag =>
           <proc>
             <pid> PID </pid>
             <env> GEnv </env>
           </proc>)
       ...</procs>
       <genv> GEnv:Map </genv>

  rule S1:Step; S2:Step => S1 ~> S2
  rule <kproc> S1:Step; S2:Step => S1 ~> S2 </kproc>

  rule <k> run P:Id (Es:ExprList) => loadGenv(PID) ~> bindTo(Ds, Es) ...</k>
       <genv>... P |-> L:Int ...</genv>
       <store>... L |-> lambda(Ds:DeclList, Ss:Sequence) ...</store>
       <nextProc> PID:Int => PID +Int 1 </nextProc>
       <procs>...
          (.Bag =>
           <proc>
             <pid> PID </pid>
             <kproc> Ss </kproc>
             <env> .Map </env>
           </proc>)
       ...</procs>

  syntax KItem ::= loadGenv(Int)

  rule <k> loadGenv(PID:Int) => .K ...</k>
       <genv> GEnv:Map </genv>
       <pid> PID </pid>
       <env> _ => GEnv </env>

  syntax KItem ::= bindTo(DeclList, ExprList)

  rule bindTo(.DeclList, .ExprList) => .K

  rule <k> .K => S </k>
       <crntProc> _ => PID </crntProc>
       <kproc> S:Step => .K ...</kproc>
       <pid> PID:Int </pid>
    requires isAtomic(S) ==K true

  syntax KItem ::= guardOf(Expr, Step)

  rule <kproc> (E:Expr ~> S:Step)  => (E ~> HOLE ~> guardOf(E, S)) ...</kproc>
       <pid> PID:Int </pid>
       <waitForStateChange> PIDs:List </waitForStateChange>
       requires isBooleanExpr(E) andBool isKResult(E) =/=K true andBool notBool PID in PIDs 
    [structural]

  rule <kproc> HOLE ~> guardOf(E:Expr, S:Step)  => S ...</kproc>
       <strict> true => .K </strict> [structural]
  rule <kproc> HOLE ~> guardOf(E:Expr, S:Step)  => E ; S ...</kproc>
       <pid> PID:Int </pid>
       <strict> false => .K </strict>
       <waitForStateChange> .List => ListItem(PID) ...</waitForStateChange>
   [structural]

  syntax Bool ::= isAtomic(Step) [function]

  rule <kproc> X:Id => .K ...</kproc>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> V:Const ...</store>
       <strict> _ => V </strict>

  rule <k> X:Id => .K ...</k>
       <crntProc> PID:Int </crntProc>
       <pid> PID </pid>
       <env>... X |-> L:Int ...</env>
       <store>... L |-> V:Const ...</store>
       <strict> _ => V </strict>

  rule <kproc> X:Id = E:Expr => E ~> X = HOLE ...</kproc>
       requires isKResult(E) =/=K true [structural]
  rule <kproc> X = HOLE  => X = V ...</kproc>
       <strict> V => .K </strict> [structural]

  rule <kproc> X:Id = V:Const => .K ...</kproc>
       <pid> PID:Int </pid>
       <genv>... X |-> L:Int ...</genv>
       <store>... L |-> (_ => V) ...</store>
       <waitForStateChange> _ => .List </waitForStateChange>

  rule <kproc> X:Id = V:Const => .K ...</kproc>
       <pid> PID:Int </pid>
       <env>... X |-> L:Int ...</env>
       <genv> GEnv:Map </genv>
       <store>... L |-> (_ => V) ...</store>
       <waitForStateChange> _ => .List </waitForStateChange>
    requires notBool X in keys(GEnv)

  rule <k> (X:Id = E:Expr) => (E ~> X = HOLE) ...</k>
       requires isKResult(E) =/=K true [structural]
  rule <k> (X = HOLE)  => (X = V) ...</k>
       <strict> V => .K </strict> [structural]

  rule <k> X:Id = V:Const => .K ...</k>
       <pid> PID </pid>
       <env>... X |-> L:Int ...</env>
       <crntProc> PID:Int </crntProc>
       <store>... L |-> (_ => V) ...</store>
       <waitForStateChange> _ => .List </waitForStateChange>

  rule B1:Bool || B2:Bool => B1 orBool B2
  rule B1:Bool && B2:Bool => B1 andBool B2
  rule B1:Bool == B2:Bool => B1 ==Bool B2
  rule B1:Bool != B2:Bool => B1 =/=Bool B2
  rule ! B:Bool => notBool B

  rule I1:Int + I2:Int => I1 +Int I2
  rule I1:Int - I2:Int => I1 -Int I2
  rule I1:Int * I2:Int => I1 *Int I2
  rule I1:Int / I2:Int => I1 /Int I2
  rule I1:Int % I2:Int => I1 %Int I2

  rule I1:Int == I2:Int => I1 ==Int I2
  rule I1:Int <= I2:Int => I1 <=Int I2
  rule I1:Int < I2:Int => I1 <Int I2
  rule I1:Int >= I2:Int => I1 >=Int I2
  rule I1:Int > I2:Int => I1 >Int I2

  rule <kproc> B1:Bool || B2:Bool => B1 orBool B2 ...</kproc>
  rule <kproc> B1:Bool && B2:Bool => B1 andBool B2 ...</kproc>
  rule <kproc> B1:Bool == B2:Bool => B1 ==Bool B2 ...</kproc>
  rule <kproc> B1:Bool != B2:Bool => B1 =/=Bool B2 ...</kproc>
  rule <kproc> ! B:Bool => notBool B ...</kproc>

  rule <kproc> I1:Int + I2:Int => I1 +Int I2 ...</kproc>
  rule <kproc> I1:Int - I2:Int => I1 -Int I2 ...</kproc>
  rule <kproc> I1:Int * I2:Int => I1 *Int I2 ...</kproc>
  rule <kproc> I1:Int / I2:Int => I1 /Int I2 ...</kproc>
  rule <kproc> I1:Int % I2:Int => I1 %Int I2 ...</kproc>

  rule <kproc> I1:Int == I2:Int => I1 ==Int I2 ...</kproc>
  rule <kproc> I1:Int <= I2:Int => I1 <=Int I2 ...</kproc>
  rule <kproc> I1:Int < I2:Int => I1 <Int I2 ...</kproc>
  rule <kproc> I1:Int >= I2:Int => I1 >=Int I2 ...</kproc>
  rule <kproc> I1:Int > I2:Int => I1 >Int I2 ...</kproc>

  rule <k> V:Const => .K ...</k>
       <strict> _ => V </strict>
  [structural]

  rule <kproc> V:Const => .K ...</kproc>
       <strict> _ => V </strict>
  [structural]


//  Auxiliary functions

  rule isAtomic(run _:Id (_:ExprList)) => true
  rule isAtomic(_:Id = _:Expr) => true
  rule isAtomic(_:Step) => false [owise]

  syntax Bool ::= isBooleanExpr(Expr) [function]
  rule isBooleanExpr(B:Bool) => true
  rule isBooleanExpr(E1:Expr == E2:Expr) => true
  rule isBooleanExpr(E1:Expr <= E2:Expr) => true
  rule isBooleanExpr(E1:Expr >= E2:Expr) => true
  rule isBooleanExpr(E1:Expr < E2:Expr) => true
  rule isBooleanExpr(E1:Expr > E2:Expr) => true
  rule isBooleanExpr(E1:Expr != E2:Expr) => true
  rule isBooleanExpr(_) => false [owise]

// Heating/cooling for kproc

  rule <kproc> E1:Expr * E2:Expr => E1 ~> HOLE * E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE * E2:Expr => V * E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr * E2:Expr => E2 ~> E1 * HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr * HOLE => E1 * V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr / E2:Expr => E1 ~> HOLE / E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE / E2:Expr => V / E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr / E2:Expr => E2 ~> E1 / HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr / HOLE => E1 / V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr % E2:Expr => E1 ~> HOLE % E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE % E2:Expr => V % E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr % E2:Expr => E2 ~> E1 % HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr % HOLE => E1 % V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr + E2:Expr => E1 ~> HOLE + E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE + E2:Expr => V + E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr + E2:Expr => E2 ~> E1 + HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr + HOLE => E1 + V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr - E2:Expr => E1 ~> HOLE - E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE - E2:Expr => V - E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr - E2:Expr => E2 ~> E1 - HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr - HOLE => E1 - V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> ! E:Expr  => E ~> ! HOLE ...</kproc>
       requires isKResult(E) =/=K true [structural]
  rule <kproc> ! HOLE  => ! V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr == E2:Expr => E1 ~> HOLE == E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE == E2:Expr => V == E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr == E2:Expr => E2 ~> E1 == HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr == HOLE => E1 == V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr != E2:Expr => E1 ~> HOLE != E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE != E2:Expr => V != E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr != E2:Expr => E2 ~> E1 != HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr != HOLE => E1 != V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr && E2:Expr => E1 ~> HOLE && E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE && E2:Expr => V && E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr && E2:Expr => E2 ~> E1 && HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr && HOLE => E1 && V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]

  rule <kproc> E1:Expr || E2:Expr => E1 ~> HOLE || E2 ...</kproc>
       requires isKResult(E1) =/=K true [structural]
  rule <kproc> HOLE || E2:Expr => V || E2 ...</kproc>
       <strict> V:KResult => .K </strict> [structural]
  rule <kproc> E1:Expr || E2:Expr => E2 ~> E1 || HOLE ...</kproc>
       requires isKResult(E2) =/=K true [structural]
  rule <kproc> E1:Expr || HOLE => E1 || V ...</kproc>
       <strict> V:KResult => .K </strict> [structural]



// Heating/cooling for k
  rule <k> E1:Expr * E2:Expr => E1 ~> HOLE * E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE * E2:Expr => V * E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr * E2:Expr => E2 ~> E1 * HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr * HOLE => E1 * V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr / E2:Expr => E1 ~> HOLE / E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE / E2:Expr => V / E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr / E2:Expr => E2 ~> E1 / HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr / HOLE => E1 / V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr % E2:Expr => E1 ~> HOLE % E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE % E2:Expr => V % E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr % E2:Expr => E2 ~> E1 % HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr % HOLE => E1 % V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr + E2:Expr => E1 ~> HOLE + E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE + E2:Expr => V + E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr + E2:Expr => E2 ~> E1 + HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr + HOLE => E1 + V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr - E2:Expr => E1 ~> HOLE - E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE - E2:Expr => V - E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr - E2:Expr => E2 ~> E1 - HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr - HOLE => E1 - V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> ! E:Expr  => E ~> ! HOLE ...</k>
       requires isKResult(E) =/=K true [structural]
  rule <k> ! HOLE  => ! V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr == E2:Expr => E1 ~> HOLE == E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE == E2:Expr => V == E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr == E2:Expr => E2 ~> E1 == HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr == HOLE => E1 == V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr != E2:Expr => E1 ~> HOLE != E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE != E2:Expr => V != E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr != E2:Expr => E2 ~> E1 != HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr != HOLE => E1 != V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr && E2:Expr => E1 ~> HOLE && E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE && E2:Expr => V && E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr && E2:Expr => E2 ~> E1 && HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr && HOLE => E1 && V ...</k>
       <strict> V:KResult => .K </strict> [structural]

  rule <k> E1:Expr || E2:Expr => E1 ~> HOLE || E2 ...</k>
       requires isKResult(E1) =/=K true [structural]
  rule <k> HOLE || E2:Expr => V || E2 ...</k>
       <strict> V:KResult => .K </strict> [structural]
  rule <k> E1:Expr || E2:Expr => E2 ~> E1 || HOLE ...</k>
       requires isKResult(E2) =/=K true [structural]
  rule <k> E1:Expr || HOLE => E1 || V ...</k>
       <strict> V:KResult => .K </strict> [structural]


endmodule