#!/bin/bash                                                                                                                                                                                                        
SUBLAMBDA=1000
SUBCG=( -2 0 2 )

#NLO setup
TTBARSETUP=ttbar_NLO

#LO setup
#TTBARSETUP=ttbar

NMASSCOMBI=`echo "scale=0; ${#SUBCG[@]} -1 " | bc`

# Loop over different CtG values
    for IMASSCOMBI in `seq 0 ${NMASSCOMBI}`; do 
	#Define string describing this setup and delete any files created from previous attampts at this setup 
	EFTSETUP=EFT_${TTBARSETUP}_lambda_${SUBLAMBDA}_CG_${SUBCG[${IMASSCOMBI}]}       
	rm -rf EFT_tt/cards/${EFTSETUP} 
	rm -rf EFT_tt/models/${EFTSETUP} 
        echo "This is the name of the EFT setup = = " $EFTSETUP
	
	# prepare card files 
	# create dedicated directory to hold config cards associated with this setup
	mkdir -p EFT_tt/cards/${EFTSETUP}

	# copy cards into dedicated directory from template directory
	for CARD in run_card proc_card customizecards reweight_card madspin_card; do 
	 cp -rp EFT_tt/cards/${TTBARSETUP}_template/${CARD}.dat  EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_${CARD}.dat

	done
        # Edit cards file of model to set Lambda, CtG to proper values instead of spacerholder strings
	sed -i -e "s|SUBLAMBDA|${SUBLAMBDA}|g" EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_*.dat 
	sed -i -e "s|SUBCG|${SUBCG[${IMASSCOMBI}]}|g" EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_*.dat 
	
        # prepare model files 
	# copy directories containing model templates into dedicated directory for this setup
        # a different model is chosen depending on the specfic choice of ttbar modelling
	if [ ${TTBARSETUP} == "ttbar_NLO" ]; then 
	   # cp -rp EFT_tt/models/ttbar_NLO EFT_tt/models/${EFTSETUP} 
             cp -rp EFT_tt/models/EFT_ttbar_NLO EFT_tt/models/${EFTSETUP}
	elif [ ${TTBARSETUP} == "ttbar" ]; then 
	    cp -rp EFT_tt/models/ttbar EFT_tt/models/${EFTSETUP}
	elif [ ${TTBARSETUP} == "ttbar_01j" ]; then
	    cp -rp EFT_tt/models/ttbar_01j EFT_tt/models/${EFTSETUP}
	else 
	    echo "Unknown ttbar setup"
	    exit 
	fi

        # Edit parmaeters.py file of model to set Lambda to appropriate value (currently we don't follow this approach, instead we edit the restrict card)
        #sed -i -e "s|SUBLAMBDA|${SUBLAMBDA[${IMASSCOMBI}]}|g" EFT_tt/models/${EFTSETUP}/parameters.py   
         sed -i -e "s|SUBCG|${SUBCG[${IMASSCOMBI}]}|g" EFT_tt/models/${EFTSETUP}/parameters.py  
         sed -i -e "s|SUBCG|${SUBCG[${IMASSCOMBI}]}|g" EFT_tt/models/${EFTSETUP}/restrict_CtG.dat  
	
        #submit NAF batch job with minimal script
	SUBPATH=${PWD}

	qsub -N ${EFTSETUP} -j y -m as -o ${SUBPATH}/EFT_tt/gridpacks -S /bin/bash -l h_rt=24:00:00,h_vmem=16G,distro=sld6 << EOF
#!/bin/bash
cd ${SUBPATH}
source /etc/profile.d/modules.sh 
module use -a /afs/desy.de/group/cms/modulefiles/
module load cmssw
export PRODHOME=${SUBPATH}
echo './gridpack_generation.sh ${EFTSETUP} EFT_tt/cards/${EFTSETUP}' 
./gridpack_generation.sh ${EFTSETUP} EFT_tt/cards/${EFTSETUP}
rm -rf ${SUBPATH}/${EFTSETUP}
EOF
	
    done 