Require Export Common Computation ADTSig ADT ADTNotation.ilist ADTNotation.BuildADTSig.
Require Import Ensembles ADTNotation.StringBound.

(* Notations for ADTs. *)

Generalizable All Variables.
Set Implicit Arguments.

Bind Scope ADT_Scope with ADT.
Delimit Scope ADT_scope with ADT.

Require Import List String.

(* This class is used by BuildADT to give a hint
   to help infer the representation type. *)
Class RepHint := {repHint : Type}.

(* Notations for ADT methods. Mutator and Observer methods
   are parameterized by a signature that includes the
   domain (both) and codomain (just observers). *)

Record obsDef {Rep : Type} (Sig : obsSig) :=
  { obsBody :> observerMethodType Rep (obsDom Sig) (obsCod Sig)}.

Notation "'def' 'obs' id ( r : 'rep' , x : dom ) : cod := bod" :=
  (Build_obsDef {| obsID := id; obsDom := dom; obsCod := cod |} (fun (r : repHint) x => bod%comp))
    (no associativity, id at level 0, r at level 0, x at level 0, dom at level 0,
     cod at level 0, only parsing,
     at level 94, format "'def'  'obs'  id  ( r  :  'rep' ,  x  :  dom )  :  cod  :=  '[  '   bod ']' " ) :
obsDefParsing_scope.

Notation "'def' 'obs' id ( r : 'rep' , x : dom ) : cod := bod" :=
  (Build_obsDef {| obsID := id; obsDom := dom; obsCod := cod |} (fun r x => bod%comp))
    (no associativity, id at level 0, r at level 0, x at level 0, dom at level 0,
     cod at level 0,
     at level 94, format "'def'  'obs'  id  ( r  :  'rep' ,  x  :  dom )  :  cod  :=  '[  '   bod ']' " ) :
obsDef_scope.

Delimit Scope obsDefParsing_scope with obsDefParsing.
Delimit Scope obsDef_scope with obsDef.

Definition minDef :=
  (def obs "Min" ( r : rep , n : unit ) : nat := ret (plus r 0))%obsDef.

Record mutDef {Rep : Type} (Sig : mutSig) :=
  { mutBody :> mutatorMethodType Rep (mutDom Sig) }.

Notation "'def' 'mut' id ( r : 'rep' , x : dom ) : 'rep' := bod" :=
  (Build_mutDef {| mutID := id; mutDom := dom |} (fun (r : repHint) x => bod%comp))
    (no associativity, at level 94, id at level 0, r at level 0,
     x at level 0, dom at level 0, only parsing,
     format "'def'  'mut'  id  ( r  :  'rep' ,  x :  dom )  :  'rep'  :=  '[  '   bod ']' " ) :
mutDefParsing_scope.

Notation "'def' 'mut' id ( r : 'rep' , x : dom ) : 'rep' := bod" :=
  (Build_mutDef {| mutID := id; mutDom := dom |} (fun r x => bod%comp))
    (no associativity, at level 94, id at level 0, r at level 0,
     x at level 0, dom at level 0,
     format "'def'  'mut'  id  ( r  :  'rep' ,  x :  dom )  :  'rep'  :=  '[  '   bod ']' " ) :
mutDef_scope.

Delimit Scope mutDef_scope with mutDef.
Delimit Scope mutDefParsing_scope with mutDefParsing.

Definition insertDef :=
  (def mut "Insert" ( r : rep , n : unit ) : rep := {n | n = plus r 0})%mutDef.

(* Lookup functions for mutator and observer definitions. Because
   method definitions are parameterized on a signature, the
   method bodies are contained in an indexed list [ilist] which is
   parameterized on a list of method signatures. *)

Definition getMutDef
        (Rep : Type)
        (mutSigs : list mutSig)
        (mutDefs : ilist (@mutDef Rep) mutSigs)
        (idx : string)
: mutatorMethodType Rep
                    (mutDom
                       (nth (findIndex mutSig_eq mutSigs idx)
                            mutSigs ("null" : rep × () → rep)%mutSig)) :=
  mutBody (ith mutSig_eq mutDefs idx
              ("null" : rep × () → rep)%mutSig
              {| mutBody := (fun r _ => ret r) |}).

Definition getObsDef
         (Rep : Type)
         (obsSigs : list obsSig)
         (obsDefs : ilist (@obsDef Rep) obsSigs)
         (idx : string)
: observerMethodType Rep
                     (obsDom (nth (findIndex obsSig_eq obsSigs idx)
                                  obsSigs ("null" : rep × () → ())%obsSig))
                     (obsCod (nth (findIndex obsSig_eq obsSigs idx)
                                  obsSigs ("null" : rep × () → ())%obsSig)) :=
  obsBody (ith obsSig_eq obsDefs idx _
               (@Build_obsDef Rep ("null" : rep × () → ()) (fun r _ => ret tt))).

(* Always simplify method lookup when the index is specified. *)
Arguments getMutDef [_] [_] _ idx%string / _ _ .
Arguments getObsDef [_] [_] _ idx%string / _ _ .

(* [BuildADT] constructs an ADT from a list of
   mutator definitions and a list of observer signatures,
   both indexed by their signatures. [BuildADT] uses [BuildADTSig]
   to construct the signature of the ADT from these signatures.
   This definition is formated nicely using notations. *)

Program Definition BuildADT
        (Rep : Type)
        (mutSigs : list mutSig)
        (obsSigs : list obsSig)
        (mutDefs : ilist (@mutDef Rep) mutSigs)
        (obsDefs : ilist (@obsDef Rep) obsSigs)
: ADT (BuildADTSig mutSigs obsSigs)
      := {|
          Rep := Rep;
          MutatorMethods idx := getMutDef mutDefs idx;
          ObserverMethods idx := getObsDef obsDefs idx
          |}.

(* Notation for ADTs built from [BuildADT]. *)

Notation "'ADTRep' r { mut1 , .. , mutn ; obs1 , .. , obsn } " :=
  (let _ := {| repHint := r |} in
    @BuildADT r
             _
             _
             (icons _ mut1%mutDefParsing .. (icons _ mutn%mutDefParsing (inil (@mutDef r))) ..)
             (icons _ obs1%obsDefParsing .. (icons _ obsn%obsDefParsing (inil (@obsDef r))) ..))
    (no associativity, at level 96, r at level 0,
     format "'ADTRep'  r  '/' '[hv  ' {  mut1 , '//' .. , '//' mutn ; '//' obs1 , '//' .. , '//' obsn  ']' }") : ADTParsing_scope.

Notation "'ADTRep' r { mut1 , .. , mutn ; obs1 , .. , obsn } " :=
  (@BuildADT r
             _
             _
             (icons _ mut1%mutDef .. (icons _ mutn%mutDef (inil (@mutDef r))) ..)
             (icons _ obs1%obsDef .. (icons _ obsn%obsDef (inil (@obsDef r))) ..))
    (no associativity, at level 96, r at level 0,
     format "'ADTRep'  r  '/' '[hv  ' {  mut1 , '//' .. , '//' mutn ; '//' obs1 , '//' .. , '//' obsn  ']' }") : ADT_scope.

(* Notations for method calls. *)
Notation callObs adt idx := (ObserverMethods adt {| bstring := idx |}).
Notation callMut adt idx := (MutatorMethods adt {| bstring := idx |}).
