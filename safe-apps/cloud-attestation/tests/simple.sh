export SAFE_ADDR=http://localhost:7777
. ../cfunctions

postProhibited strong-1 cset image_c1 '[]'
postQualifier strong-1 cset image_c1 '[]'
postRequired strong-1 cset image_c1 '[]'

postInstanceConfig strong-1 pod subinstances '[ctn]'
postSubinstanceConfig strong-1 ctn pod image_c1 '[[k1,v1],[k2,v2]]'

configMatchSet strong-1 strong-1 pod strong-1 cset

