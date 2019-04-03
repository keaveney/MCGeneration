#############################################                                                                                          
#Copy, Unzip and Delete the MadGraph tarball#                                                                                          
#############################################                                                                                          
MG=MG5_aMC_v2.6.5

VAR3="$VAR1$VAR2"

MGSOURCE="https://launchpad.net/mg5amcnlo/2.0/2.6.x/+download/"${MG}".tar.gz"

wget --no-check-certificate ${MGSOURCE}
tar xzf ${MG}".tar.gz"
rm ${MG}".tar.gz"

MOD=dim6top_LO_UFO
MODSOURCE="http://feynrules.irmp.ucl.ac.be/raw-attachment/wiki/dim6top/"${MOD}".tar.gz"

#http://feynrules.irmp.ucl.ac.be/raw-attachment/wiki/dim6top/dim6top_LO_UFO.tar.gz

wget --no-check-certificate ${MODSOURCE}
tar -C MG5_aMC_v2_6_5/models/ -xf $MOD".tar.gz"