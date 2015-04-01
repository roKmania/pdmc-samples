// Copyright (c) 2014- K Team. All Rights Reserved.

require "builtins/mint.k"

module INT-IMPL
/*@
 \subsection{An Implementation of "int"}

  This module includes a (partial) implementation of the Cink
  builtin data type "int".
  The implementation is based on the module implementing machine integers 
  of arbitrary bit width represented in 2's complement.
*/

  imports MINT  //module implementing machine integers

  // The number of bits used to represent a int:
  syntax KItem ::= "INT-IMPL" [function]
  // Change the following line for implementations on != 32 bits
  rule INT-IMPL => 32

  // the limits of int
  syntax KItem ::= "INT-MIN" [function]
     | "INT-MAX" [function]

  rule INT-MIN => sminMInt(INT-IMPL)
  rule INT-MAX => smaxMInt(INT-IMPL)

  // Int2int casting

  syntax Int ::= Int2int(Int) [function]
  rule Int2int(I) => svalueMInt(mi(INT-IMPL,I))

  // the arithmetic operations
  syntax Int ::= Int "+int" Int [function]
  rule I1:Int +int I2:Int
       =>
       svalueMInt(addMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2)))


  syntax Int ::= Int "-int" Int [function]
  rule I1:Int -int I2:Int
       =>
       svalueMInt(subMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2)))

  syntax Int ::= Int "*int" Int [function]
  rule I1:Int *int I2:Int
       =>
       svalueMInt(mulMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2)))

  syntax Int ::= Int "/int" Int [function]
  rule I1:Int /int I2:Int
       =>
       svalueMInt(miMInt(sdivMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))))

  syntax Int ::= Int "%int" Int [function]
  rule I1:Int %int I2:Int
       =>
       svalueMInt(miMInt(sremMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))))


  // the relational operators
  syntax Bool ::= Int "<int" Int [function]
  rule I1:Int <int I2:Int
       =>
      sltMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))

  syntax Bool ::= Int ">int" Int [function]
  rule I1:Int >int I2:Int
       =>
      sgtMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))

  syntax Bool ::= Int "<=int" Int [function]
  rule I1:Int <=int I2:Int
       =>
      sleMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))

  syntax Bool ::= Int ">=int" Int [function]
  rule I1:Int >=int I2:Int
       =>
      sgeMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))

  syntax Bool ::= Int "==int" Int [function]
  rule I1:Int ==int I2:Int
       =>
      eqMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))

  syntax Bool ::= Int "!=int" Int [function]
  rule I1:Int !=int I2:Int
       =>
      neMInt(mi(INT-IMPL, I1), mi(INT-IMPL, I2))


  syntax Int ::= Int "<<int" Int [function]
  rule I1:Int <<int I2:Int
       =>
      svalueMInt(shlMInt(mi(INT-IMPL, I1), I2))

  syntax Int ::= Int ">>int" Int [function]
  rule I1:Int >>int I2:Int
       =>
      svalueMInt(lshrMInt(mi(INT-IMPL, I1), I2))   // ????

  syntax Int ::= Int "&int" Int [function]
  rule I1:Int &int I2:Int
       =>
      svalueMInt(andMInt(mi(INT-IMPL, I1),  mi(INT-IMPL, I2)))

  syntax Int ::= Int "|int" Int [function]
  rule I1:Int |int I2:Int
       =>
      svalueMInt(orMInt(mi(INT-IMPL, I1),  mi(INT-IMPL, I2)))

  syntax Int ::= Int "^int" Int [function]
  rule I1:Int ^int I2:Int
       =>
      svalueMInt(xorMInt(mi(INT-IMPL, I1),  mi(INT-IMPL, I2)))


  //... to be completed

endmodule