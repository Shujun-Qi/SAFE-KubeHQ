import("../safe.slang").

//
// Group Authority 
//

defcon addGroupMember(?Group, ?User, ?Delegatable) :-
  spec('Add a user into a group'),
  ?GroupRef := label($Self, "groups/?Group"),
  {
    groupMember($Group, $User, $Delegatable).
    link($GroupRef).
    label("groupMember/$Group/$User").     (* this link should be saved in the subject set of ?User *)
  }.

defpost postGroupMember(?Group, ?User, ?Delegatable) :- [addGroupMember(?Group, ?User, ?Delegatable)].

defcon delegateGroup(?Group, ?SubGroup, ?Delegatable) :-
  spec('Delegate administration to another group'), (* Membership is granted if membership of sub-group is granted *)
  ?GroupRef := label($Self, "groups/?Group"),
  {
    nestGroup($Group, $SubGroup, $Delegatable).
    link($GroupRef).
    label("delegateGroup/$Group/$SubGroup").  (* this link should be saved in the ID set of ?SubGroup *)
  }.

defpost postGroupDelegation(?Group, ?SubGroup, ?Delegatable) :- [delegateGroup(?Group, ?SubGroup, ?Delegatable)].

defcon addTokenToGroupSet(?Token, ?Group) :-
  spec("Add a link to a group's ID set. Invoked on delegation to this group"),
  {
    link($Token).
    label("groups/$Group").
  }.

defpost updateGroupSet(?Token, ?Group) :- [addTokenToGroupSet(?Token, ?Group)].


//
// Group member
//

defcon delegateGroupMembership(?User, ?Group, ?Delegatable) :-
  spec('Delegate group membership to another user'),
  ?SubjectSetRef := label("subject($Self)"),
  {
    delegateMembership($User, $Group, $Delegatable).
    link($SubjectSetRef).
    label("membershipDelegation/$Group/$User").     (* this link should be saved in the subject set of ?User *)
  }.

defpost postMembershipDelegation(?User, ?Group, ?Delegatable) :- [delegateGroupMembership(?User, ?Group, ?Delegatable)].
//
// Guard
//

defcon memberSet() :-
  spec('Local policies on group membership'),
  {
    membership(?Group, ?User) :-
      membership(?Group, ?User, _).
  
   //
   // If the group root can automatically have membership of the group, 
   // enable this rule.
   //
   // membership(?Group, ?User, true) :-
   //   ?GRoot := rootPrincipal(?Group),
   //   ?GRoot = ?User.
   //

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group), 
      ?GRoot: groupMember(?Group, ?User, ?Delegatable).
    
    membership(?Group, ?User, ?Delegatable) :-
      ?Delegator: delegateMembership(?User, ?Group, ?Delegatable),
      membership(?Group, ?Delegator, true).

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group),
      ?GRoot: nestGroup(?Group, ?SubGroup, true), 
      membership(?SubGroup, ?User, ?Delegatable).

    membership(?Group, ?User, ?Delegatable) :-
      ?GRoot := rootPrincipal(?Group),
      ?GRoot: nestGroup(?Group, ?SubGroup, false), 
      ?SubGroupRoot := rootPrincipal(?SubGroup),
      ?SubGroupRoot: groupMember(?SubGroup, ?User, ?Delegatable).

    label('standard-membership-policy').
  }.

definit memberSet().

defguard whoami() :-
  spec("Query principal id"),
  {
    principalId($Self).
    principalId(?X)?
  }.

defguard queryMembership(?Group, ?SubjectId) :-
  spec("Query the group membership of a principal"),
  ?MembershipPolicy := label('standard-membership-policy'),
  {
    link($MembershipPolicy).
    link($BearerRef).
    membership($Group, $SubjectId)?
  }.
