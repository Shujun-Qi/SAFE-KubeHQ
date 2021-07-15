
export SAFE_ADDR=http://localhost:7777
. ../cfunctions

postProhibited cset1 image_c1 '[k5]'
postQualifier cset1 image_c1 '[[k1,v1]]'
postRequired cset1 image_c1 '[k1,k2]'
postProhibited cset1 image_c2 '[k5]'
postQualifier cset1 image_c2 '[[k4,v4]]'
postRequired cset1 image_c2 '[k3]'

postInstanceConfig kmaster pod1 subinstances '[ctn1,ctn2]'
postSubinstanceConfig kmaster ctn1 pod1 image_c1 '[[k1,v1],[k2,v2]]'
postSubinstanceConfig kmaster ctn2 pod1 image_c2 '[[k3,v3],[k4,v4]]'
