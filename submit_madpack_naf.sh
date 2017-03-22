#!/bin/bash                                                                                                                                                                                                        
#SUBMCHI=(   1   1   1    1    1    1    1      1  10  10  10   10  50  50  50   50   50 )  
#SUBMPHI=(  10  20  50  100  200  300  500  10000  10  15  50  100  10  50  95  200  300 )
#TTBARSETUP=ttbar01j 

#SUBMCHI=(  1  1   1 )
#SUBMPHI=( 10 50 100 )
#TTBARSETUP=ttbar

SUBLAMBDA=( 5000 )
SUBCG=( -2 0 2 )

#NLO setup
TTBARSETUP=ttbar_NLO

#LO setup
#TTBARSETUP=ttbar


#Master loop for different DM mediators not needed for EFT MC
for SUBMEDIATOR in Pseudoscalar ; do 
    NMASSCOMBI=`echo "scale=0; ${#SUBCG[@]} -1 " | bc`

# Loop over different lambda values
    for IMASSCOMBI in `seq 0 ${NMASSCOMBI}`; do 

	#Define string describing this setup and delete any files created from previous attampts at this setup 
	EFTSETUP=EFT_${TTBARSETUP}_lambda_${SUBLAMBDA[${IMASSCOMBI}]}_CG_${SUBCG[${IMASSCOMBI}]}_weights
        
        echo "This is the name of the EFT setup = = " $EFTSETUP
	rm -rf EFT_tt/cards/${EFTSETUP} 
	rm -rf EFT_tt/models/${EFTSETUP} 
	
	# prepare card files 
	# create dedicated directory to hold config cards associated with this setup
	mkdir -p EFT_tt/cards/${EFTSETUP}
	# copy cards into dedicated directory from template directory
	for CARD in run_card proc_card customizecards reweight_card madspin_card; do 
	 #   cp -rp EFT_tt/cards/${TTBARSETUP}_template/${CARD}.dat  EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_${CARD}.dat
	 cp -rp EFT_tt/cards/${TTBARSETUP}_template/${CARD}.dat  EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_${CARD}.dat

	done 
	sed -i -e "s|SUBLAMBDA|${SUBLAMBDA[${IMASSCOMBI}]}|g" EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_*.dat 
	sed -i -e "s|SUBCG|${SUBCG[${IMASSCOMBI}]}|g" EFT_tt/cards/${EFTSETUP}/${EFTSETUP}_*.dat 
	
        # prepare model files 
	# copy directories containing model templates into dedicated for this setup
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
        # Edit parmaeters.py file of model to set Lambda to appropriate value

#	sed -i -e "s|SUBLAMBDA|${SUBLAMBDA[${IMASSCOMBI}]}|g" EFT_tt/models/${EFTSETUP}/parameters.py  
#	sed -i -e "s|SUBCG|${SUBCG[${IMASSCOMBI}]}|g" EFT_tt/models/${EFTSETUP}/parameters.py  
	
#submit NAF batch job with minimal script
	SUBPATH=${PWD}

#try writing gridpacks to dust
#	SUBPATH=/nfs/dust/cms/user/keaveney/gridpacks/

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
done


echo ${SUBPATH}
echo ${EFTSETUP}
