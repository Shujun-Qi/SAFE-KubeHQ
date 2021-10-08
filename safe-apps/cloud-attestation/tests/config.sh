
export SAFE_ADDR=http://localhost:7777
. ../cfunctions

postProhibited strong-1 cset image_c1 '[k5]'
postQualifier strong-1 cset image_c1 '[[k1,v1]]'
postRequired strong-1 cset image_c1 '[k1,k2]'
postProhibited strong-1 cset image_c2 '[k5]'
postQualifier strong-1 cset image_c2 '[[k4,v4]]'
postRequired strong-1 cset image_c2 '[k3]'

postInstanceConfig strong-1 pod subinstances '[ctn1,ctn2]'
postSubinstanceConfig strong-1 ctn1 pod image_c1 '[[k1,v1],[k2,v2]]'
postSubinstanceConfig strong-1 ctn2 pod image_c2 '[[k3,v3],[k4,v4]]'

configMatchSet strong-1 strong-1 pod strong-1 cset

