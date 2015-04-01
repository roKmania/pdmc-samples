module PML-SYNTAX


/*
spec	: module [ module ] *
*/

//syntax Spec ::= List{Module, ""}
syntax Spec ::=
     Module 
   | Spec Spec [right, seqspec]

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
     | Mtype ";"               // not exactly as in the grammar 
     | DeclList ";" [declmod]  // not exactly as in the grammar 
     | Macro    // not in the grammar

/*
proctype: [ active ] PROCTYPE name '(' [ decl_lst ]')'
	  [ priority ] [ enabler ] '{' sequence '}'
*/

//partial defined
  syntax Proctype ::=
       "proctype" Id "(" DeclList ")" "{" Sequence "}"
     |  "proctype" Id "(" ")" "{" Sequence "}"
     | "inline" Id "(" DeclList ")" "{" Sequence "}"
     |  "inline" Id "(" ")" "{" Sequence "}"

/*
init	: INIT [ priority ] '{' sequence '}'
*/

// partial defined 
  syntax Init ::= "init" "{" Sequence "}"

/*
never	: NEVER	'{' sequence '}'

trace	: TRACE '{' sequence '}'

utype	: TYPEDEF name '{' decl_lst '}'
*/

/*
mtype	: MTYPE [ '=' ] '{' name [ ',' name ] * '}'
*/

  syntax Mtype ::=
       "mtype" "{" Ids "}"
     | "mtype" "="  "{" Ids "}"

  syntax Ids ::= List{Id, ","}

/*
decl_lst: one_decl [ ';' one_decl ] *
*/

//  syntax DeclList ::= List{Decl, ";"}

  syntax DeclList ::= Decl | DeclList ";" DeclList [right, declist, klabel("declComp")]

  syntax priorities declmod > declist

/*
one_decl: [ visible ] typename  ivar [',' ivar ] *
*/

//partial defined

  syntax Decl ::= Typename IvarList

  syntax IvarList ::= List{Ivar, ","}
/*
ivar    : name [ '[' const ']' ] [ '=' any_expr | '=' ch_init ]
*/
  syntax Ivar ::=
       Id
     | Id "=" Expr                  [ivar, klabel("initIvarSimple")]
     | Id "=" ChInit                [ivar, klabel("chInitIvarSimple")] 
     | Id "[" Expr "]"             [klabel("ivarArr")]
     | Id "[" Expr "]" "=" Expr    [ivar, klabel("initIvarArr")]
     | Id "[" Expr "]" "=" ChInit  [ivar, klabel("chInitIvarArr")]

/*

typename: BIT | BOOL | BYTE | SHORT | INT | MTYPE | CHAN
	| uname	// user defined type names (see utype) \\
*/

  syntax Typename ::=
       "int"
     | "byte"
     | "bit"
     | "bool"
     | "chan"
     | "mtype"

// Macros (not in the grammar)

  syntax Macro ::=
       "#define" Id Const

/*
active  : ACTIVE [ '[' const ']' ]	// instantiation \\

priority: PRIORITY const	// simulation priority \\

enabler : PROVIDED '(' expr ')'	// execution constraint \\

visible	: HIDDEN | SHOW

sequence: step [ ';' step ] *
*/

//   syntax Sequence ::= List{Step, ";"} [sequence]

  syntax Sequence ::=
       Step
     | Sequence ";" Sequence [right, sequence, klabel("sequenceComp")]

  syntax priorities sequence > declmod

/*
step    : stmnt	[ UNLESS stmnt ]
	| decl_lst
	| XR varref [',' varref ] *
	| XS varref [',' varref ] *
*/

// partial defined
  syntax Step ::=
       Stmt
     | Decl

/*

ch_init : '[' const ']' OF '{' typename [ ',' typename ] * '}'
*/

// partial defined
  syntax ChInit ::= 
       "of" "{" TypenameList "}"
     | "[" Const "]" "of" "{" TypenameList "}"

//  syntax TypenameList ::= List{Typename, ","}
  syntax TypenameList ::= Typename | TypenameList "," TypenameList [right]

/*
varref	: name [ '[' any_expr ']' ] [ '.' varref ]
*/

  syntax Varref ::= 
       Id
     | Id "[" Expr "]"  [klabel("varrefArr")]

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
  syntax Receive ::= Varref "?" RecvArgs
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

  syntax RecvArgs ::=
       RecvargList
     | Recvarg "(" RecvargList ")"

/*
assign  : varref '=' any_expr	// standard assignment \\
	| varref '+' '+'	// increment \\
	| varref '-' '-'	// decrement \\
*/

  syntax Assign ::=
       Varref "=" Expr [assign, klabel("assign")]
     | Varref "++" [inc]
     | Varref "--" [dec]

  syntax priorities assign > ivar

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
     | "printf" "(" String ")"
     | "printf" "(" String "," ExprList ")"
     | "assert" Expr
     > "if" OptionList "fi"
     | "do" OptionList "od"
     | "atomic" "{" Sequence "}"
     | "{" Sequence "}"
     | Id ":" Stmt
     > Stmt "->" Sequence    [guard]

  syntax priorities  guard > sequence

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

  syntax Const ::= Int | Bool | "skip" | Id

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
     | Id "(" ExprList ")"
     | Id "[" Int "]" "(" ExprList ")" 
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


  syntax Const ::= initVal(Typename) [function]
  rule initVal(int) => 0
  rule initVal(byte) => 0
  rule initVal(bit) => 0
  rule initVal(bool) => false

// macros (are stored as global variables
  rule <k> #define X:Id C:Const => .K ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> C) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

// global variables

  rule <k> T:Typename .IvarList; => .K ...</k>

  rule <kproc> T:Typename .IvarList; => .K ...</kproc>

  rule <k> T:Typename (X:Id, Xs => Xs); ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  rule <kproc> T:Typename (X:Id, Xs => Xs); ...</kproc>
       <env>... .Map =>  (X |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]


  rule <k> T:Typename X:Id[E:Expr], Xs; => E ~> T X[HOLE], Xs; ...</k>
    requires isKResult(E) =/=K true
  rule <k> V:Int ~>  T:Typename X:Id[HOLE], Xs; => T X[V], Xs; ...</k>

  rule <k> T:Typename X:Id[N:Int], Xs; => alloc(N, X, T) ~> T Xs; ...</k>

  rule <kproc> T:Typename X:Id[N:Int], Xs; => alloc(N, X, T) ~> T Xs; ...</kproc>

  syntax KItem ::= alloc(Int, Id, Typename)

  rule <k> alloc((N:Int => N -Int 1) , X:Id, T:Typename) ...</k>
       <genv>... .Map =>  (X[N -Int 1]::Ivar |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires N >Int 0
    [structural]

  rule <kproc> alloc((N:Int => N -Int 1) , X:Id, T:Typename) ...</kproc>
       <env>... .Map =>  (X[N -Int 1]::Ivar |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> initVal(T)) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    requires N >Int 0
    [structural]

  rule <k> alloc(0 , _:Id, _:Typename) => .K ...</k>

  rule <kproc> alloc(0 , _:Id, _:Typename) => .K ...</kproc>

  rule <k> T:Typename (X:Id = E:Expr)::Ivar => E ~> T (X = HOLE:Expr)::Ivar ...</k>
       requires isKResult(E) =/=K true [structural]

  rule <k> T:Typename (X:Id = HOLE:Expr)::Ivar => T (X = V:Expr)::Ivar ...</k>
       <strict> V => .K </strict>
       requires isKResult(V) ==K true
    [structural]

  rule <k> T:Typename (X:Id = V:Const)::Ivar => .K ...</k>
       <genv>... .Map =>  (X |-> L:Int) ...</genv>
       <store>... .Map => (L:Int |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  rule <kproc> T:Typename (X:Id = E:Expr)::Ivar => E ~> T (X = HOLE:Expr)::Ivar ...</kproc>
       requires isKResult(E) =/=K true [structural]

  rule <kproc> T:Typename (X:Id = HOLE:Expr)::Ivar => T (X = V:Expr)::Ivar ...</kproc>
       <strict> V => .K </strict>
       requires isKResult(V) ==K true
    [structural]

  rule <kproc> T:Typename (X:Id = V:Const)::Ivar => .K ...</kproc>
       <env>... .Map =>  (X |-> L:Int) ...</env>
       <store>... .Map => (L:Int |-> V) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>
    [structural]

  syntax KItem ::= lambda(DeclList, Sequence)

  syntax DeclList ::= ".DeclList"

  rule proctype P:Id ( ) { Ss:Sequence } => proctype P( .DeclList ) { Ss }

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

  rule run P:Id [I:Int] (Es:ExprList) => run P (Es) ~> run P[I -Int 1] (Es)
    requires I >Int 0

  rule run P:Id [0] (Es:ExprList) => run P (Es)

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

  rule <kproc> (X:Id = E:Expr)::Assign => E ~> (X = HOLE)::Assign ...</kproc>
       requires isKResult(E) =/=K true [structural]
  rule <kproc> (X:Id = HOLE)::Assign  => (X = V)::Assign ...</kproc>
       <strict> V:Const => .K </strict> [structural]

  rule <kproc> (X:Id = V:Const)::Assign => .K ...</kproc>
       <pid> PID:Int </pid>
       <genv>... X |-> L:Int ...</genv>
       <store>... L |-> (_ => V) ...</store>
       <waitForStateChange> _ => .List </waitForStateChange>

  rule <kproc> (X:Id = V:Const)::Assign => .K ...</kproc>
       <pid> PID:Int </pid>
       <env>... X |-> L:Int ...</env>
       <genv> GEnv:Map </genv>
       <store>... L |-> (_ => V) ...</store>
       <waitForStateChange> _ => .List </waitForStateChange>
    requires notBool X in keys(GEnv)

  rule <k> (X:Id = E:Expr)::Assign => (E ~> (X = HOLE)::Assign) ...</k>
       requires isKResult(E) =/=K true [structural]
  rule <k> (X:Id = HOLE)::Assign  => (X = V)::Assign ...</k>
       <strict> V:Const => .K </strict> [structural]

  rule <k> (X:Id = V:Const)::Assign => .K ...</k>
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

  rule  <kproc> _pid => PID ...</kproc>
        <pid> PID </pid>


//  Auxiliary functions

  rule isAtomic(run _:Id (_:ExprList)) => true
  rule isAtomic(_:Varref = _:Expr) => true
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


// statements

  rule <k> do Opns od => if Opns fi; do Opns od ...</k>

  rule <kproc> do Opns od => if Opns fi; do Opns od ...</kproc>


endmodule