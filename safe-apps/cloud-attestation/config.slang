import("./plist.slang").


/*
postProhibited cset1 image_c1 '[k5]'
postQualifier cset1 image_c1 '[[k1,v1]]'
postRequired cset1 image_c1 '[k1,k2]'
postProhibited cset1 image_c2 '[k5]'
postQualifier cset1 image_c2 '[[k4,v4]]'
postRequired cset1 image_c2 '[k3]'

postInstanceConfig kmaster pod1 subinstances '[ctn1,ctn2]'
postSubinstanceConfig kmaster ctn1 pod1 image_c1 '[[k1,v1],[k2,v2]]'
postSubinstanceConfig kmaster ctn2 pod1 image_c2 '[[k3,v3],[k4,v4]]'
*/

// Adapted from Latte's policy.slang.  Experimental new approach.
// A ConfigSet has exactly three lists (known as PQR) for each eligible named image.
// They are: Prohibited arg keys, Qualifying values for arg keys, and Required arg keys.
// If any PQR list is not present, then the image is not eligible (not whitelisted).
// Each PQR list is a keyset: a sorted list of keys with optional values (called k-list or k+v list).
// P and R are k-lists, and Q is a k+v list.
//
// These keysets are asserted in predicates called prohibited, required, and qualifier.
// Keyed by ConfigSetID and Subinstance name.
// Grouped in a single set labeled as ConfigSets/ConfigSetID.
//
// Note error rakes:
// - Results are indeterminate if any PQR list is unsorted, or if any image is missing
// any PQR list, or if an image has more than one list for any PQR in the ConfigSet.

defcon createProhibited(?ConfigSetID, ?ImageID, ?PKeyset) :-
{
    prohibited($ConfigSetID, $ImageID, $PKeyset).
    label("ConfigSets/$ConfigSetID").
}.

defcon createRequired(?ConfigSetID, ?ImageID, ?RKeyset) :-
{
    required($ConfigSetID, $ImageID, $RKeyset).
    label("ConfigSets/$ConfigSetID").
}.

defcon createQualifier(?ConfigSetID, ?ImageID, ?QKeyset) :-
{
    qualifier($ConfigSetID, $ImageID, $QKeyset).
    label("ConfigSets/$ConfigSetID").
}.

defpost postProhibited(?ConfigSetID, ?ImageID, ?ConfProhibited) :-
    [createProhibited(?ConfigSetID, ?ImageID, ?ConfProhibited)].

defpost postRequired(?ConfigSetID,  ?ImageID, ?ConfRequired) :-
    [createRequired(?ConfigSetID, ?ImageID, ?ConfRequired)].

defpost postQualifier(?ConfigSetID, ?ImageID, ?ConfQualifiers) :-
    [createQualifier(?ConfigSetID, ?ImageID, ?ConfQualifiers)].

//
// Config
// Config describes an instance e.g., a pod.  It has a list of named subinstances (e.g., containers),
// each of which has an image and an arg keyset.  The subinstances are listed in a keyset named
// "subinstances".  There may be other named keysets for the instance.
// [Other named keysets for instance such as "global" are not currently used for matching.]
// We use two Config predicates: configInstance and configSubinstance.
// Config statements for an instance appear in a single set labeled instance/$Instance.
//
defcon consInstanceConfig(?Instance,?ConfigKey,?Value) :-
{
    configInstance($Instance, $ConfigKey, $Value).
    label("instance/$Instance").
}.
defpost postInstanceConfig(?Instance,?ConfigKey,?Value) :-
    [ consInstanceConfig(?Instance,?ConfigKey,?Value) ].

defcon consSubinstanceConfig(?Subinstance,?Instance,?Image,?ArgKeyset) :-
{
    configSubinstance($Subinstance, $Instance, $Image, $ArgKeyset).
    label("instance/$Instance").
}.
defpost postSubinstanceConfig(?Subinstance,?Instance,?Image,?ArgKeyset) :-
    [ consSubinstanceConfig(?Subinstance,?Instance,?Image,?ArgKeyset) ].

//postSubinstanceConfig kmaster ctn1 pod1 image_c1 '[[k1,v1],[k2,v2]]'


defcon dtorInstanceConfig(?Instance,?Config,?Value) :-
{
    config($Instance, $Config, $Value)~
    label("instance/$Instance").
    invalid().
}.
defpost delInstanceConfig(?Instance,?Config,?Value) :-
    [ dtorInstanceConfig(?Instance,?Config,?Value) ].

defguard configMatchSet(?Attester, ?Instance, ?Endorser, ?ConfigSet) :-
    ?InstanceToken := label(?Attester, "instance/?Instance"),
    ?ConfigSetToken := label(?Endorser, "ConfigSets/?ConfigSet"),
    ?ListRules := label("property-list-rules"),
    ?MatchRules := label("config-match-rules"), 
{

// 9/16/21 These two links don't resolve properly until we have name-to-PID conversion for incoming script args
// from curl.  The posts use PID, but these synthesized links get only the nickname (e.g., "strong-1").
//  link($InstanceToken). 
//  link($ConfigSetToken).
// Until that happy day we hardwire set links for test scenario.

    link('mac6Mkn2BB0yZ4SHFakqSLf0FvtlwDtVQ0ellN5ibLo=').
    link('nafxpum0XMwwIMXV7rR1DXtlwhzzfaTz-3yXBGwJ27M=').

    link($ListRules).
    link($MatchRules).

    configMatch($Instance, $ConfigSet)?
}.

//
// Logic rules for match, i.e., check compliance of a Config to a ConfigSet.
//
// Note: these presume that Configs and ConfigSets are named by scids at the logic level.
// They are not in the curl test scenarios, so we whack the getters below to allow non-scids.
// It's temporary, but for now the attester, endorser, and guard must all be the same principal.
//

defcon configSetMatchRules() :- 
{

    label("config-match-rules").
    resolving(match).
    
    // Wildcard matches to short-circuit 'required' check only for testing/debugging.
    // Match iff I believe anything useful about the args.
    // configMatch(AConfig, EConfigSet) :- configInstance(AConfig, _, _),required(EConfigSet, _, _).
    // Match special case: skip all checks for (pod,cset).
    // configMatch(pod,cset).

    // Special case match/allow ground facts for simple testing/debugging.  Mostly harmless.
    // compliantSubinstances(pod, [ctn], cset).
    // compliesRequired(cset, image_c1, [[k1,v1],[k2,v2]]).

    configMatch(AConfig, EConfigSet) :-
      getSubinstances(AConfig, ASubinstances),
      compliantSubinstances(AConfig, ASubinstances, EConfigSet).

    // Tail: check each subinstance of a Config against PQR for EConfigSet.
    compliantSubinstances(AConfig, [Subinstance|Rest], EConfigSet) :- 
      getSubinstanceConfig(AConfig, Subinstance, Image, ArgKeyset),
      compliesRequired(EConfigSet, Image, ArgKeyset),
      compliesQualifier(EConfigSet, Image, ArgKeyset),
      \+( violatesProhibited(EConfigSet, Image, ArgKeyset) ),
      compliantSubinstances(AConfig, Rest, EConfigSet).

    // Base case for tail recursion.
    compliantSubinstances(_, [], _).

    compliesRequired(EConfigSet, Image, ArgKeyset) :-
      getRequiredKeyset(EConfigSet, Image, RKeyset),
      propsPresent(RKeyset, ArgKeyset).
//      subseq(CRequiredKeys, PList),

    compliesQualifier(EConfigSet, Image, ArgKeyset) :-
      getQualifierKeyset(EConfigSet, Image, QKeyset),
      esubseq(QKeyset, ArgKeyset).

    violatesProhibited(EConfigSet, Image, ArgKeyset) :-
      getProhibitedKeyset(EConfigSet, Image, PKeyset),      
      anyPropPresent(PKeyset, ArgKeyset).

    getRequiredKeyset(EConfigSet, Image, RKeyset) :-
      required(EConfigSet, Image, RKeyset).
      
    getQualifierKeyset(EConfigSet, Image, QKeyset) :-
      qualifier(EConfigSet, Image, QKeyset).

    getProhibitedKeyset(EConfigSet, Image, PKeyset) :-
      prohibited(EConfigSet, Image, PKeyset).

    getSubinstances(AConfig, ASubinstances) :-
      configInstance(AConfig, "subinstances", ASubinstances).    

    getSubinstanceConfig(AConfig, Subinstance, Image, ArgKeyset) :-
      configSubinstance(Subinstance, AConfig, Image, ArgKeyset).
}.

definit configSetMatchRules().
definit listMatchingRules().

/*
    These are the proper logic getters.  Shortened to avoid dealing with scids
    during testing from a shell client.  The shortened versions can work iff
    the attester and endorser are both equal to $self at guard query time.

    getRequiredKeyset(EConfigSet, Image, RKeyset) :-
      Owner := rootPrincipal(EConfigSet),
      Owner:required(EConfigSet, Image, RKeyset).
      
    getQualifierKeyset(EConfigSet, Image, QKeyset) :-
      Owner := rootPrincipal(EConfigSet),
      Owner:qualifier(EConfigSet, Image, QKeyset).

    getProhibitedKeyset(EConfigSet, Image, PKeyset) :-
      Owner := rootPrincipal(EConfigSet),
      Owner:prohibited(EConfigSet, Image, PKeyset).

    getSubinstances(AConfig, ASubinstances) :-
      Owner := rootPrincipal(AConfig),
      Owner:configInstance(AConfig, "subinstances", ASubinstances).    

    getSubinstanceConfig(AConfig, SubInstance, Image, ArgKeyset) :-
      Owner := rootPrincipal(AConfig),
      Owner:configSubinstance(Subinstance, AConfig, Image, ArgKeyset).

*/
