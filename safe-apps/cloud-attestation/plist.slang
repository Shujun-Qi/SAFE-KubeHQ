// Adapted from Latte's plist-lib.slang.
// Cleaned up, stripped down.

import("../safe.slang").

defcon listMatchingRules() :-
{
// Test if L is a subsequence of R.
subseq([X|L], [X|R]) :-
   subseq(L, R).
subseq([H|L], [S|R]) :-
   S < H,
   subseq([H|L], R).
subseq([], R).

// Test if L is an extended subsequence of R.
esubseq([[X,Y]|L], [[X,Y]|R]) :-
   esubseq(L, R).
esubseq([[H,Y]|L], [[S,_]|R]) :-
   S < H,
   esubseq([[H,Y]|L], R).
esubseq([], R).

// Test if L and R intersect
intersecting([E|_], [E|_]).
intersecting([S|L], R) :-
  [H|_] = R,
  S < H,
  intersecting(L, R).
intersecting(L, [S|R]) :-
  [H|_] = L,
  S < H,
  intersecting(L, R).

// Test if each property K in L corresponds to a [K,V] pair in R.
propsPresent([], R).
propsPresent([K|L], [[K,_]|R]):-
  propsPresent(L, R).
propsPresent(L, [[S,_]|R]):-
  [H|_] = L,
  S < H,
  propsPresent(L, R).

// Test if any property K in L corresponds to a [K,V] pair in R.
anyPropPresent([K|_],[[K,_]|_]).
anyPropPresent(L, [[S,_]|R]) :-
  [H|_] = L,
  S < H,
  anyPropPresent(L,R).
anyPropPresent([S|L], R) :-
  [[H,_]|_] = R,
  S < H,
  anyPropPresent(L,R).

// "Harmless" ground fact useful to verify that plist.slang is in a context.
  resolving(plist).

  label("property-list-rules").
}.