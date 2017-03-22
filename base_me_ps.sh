#!/bin/bash

echo -e "\nJob started at "`date`" on "`hostname --fqdn`"\n"

# define source 
SOURCE=SUBSOURCE
# define last step 
LASTSTEP=SUBLASTSTEP

# set job id 
ID="$(printf '%05d' "${SGE_TASK_ID}")"
# change to scratch directory
cd $TMPDIR

#copy files if needed 
cp SUBOUTPUTDIR/scripts/SUBSCRIPTFILE.py ${CMSSW_BASE}/src/SUBSCRIPTDIR/ 
if [ ${SOURCE} == "LHE" ] ; then
    echo "Searching for tarred LHE files in: " $SUBINPUTDIR
#    tar xzf SUBINPUTDIR/*.${ID}.lhe.tar.gz  
    tar xzf SUBINPUTDIR/*.lhe.tar.gz  
    #agrohsje make more specific if possible and needed in future
    mv *.lhe input.lhe
fi
# setup cms environment
# not needed as -V was used for job submission

# define seed 
SEED=`echo "526719+${SGE_TASK_ID}" | bc`

# execute command
if [ ${SOURCE} == "NONE" ] ; then  
    if [ ${LASTSTEP} == "GEN" ]; then
    #--datatier GEN-SIM-RAW
	cmsDriver.py SUBSCRIPTDIR/SUBSCRIPTFILE.py --mc --no_exec --python_filename step1.py \
	    --step LHE,GEN --eventcontent RAWSIM --datatier GEN \
	    --conditions auto:mc \
	    --customise_command "process.source.firstRun = cms.untracked.uint32(${SEED})" \
	    -n SUBNEVT --fileout file:step1.root
    elif [ ${LASTSTEP} == "SIM" ]; then 
	cmsDriver.py SUBSCRIPTDIR/SUBSCRIPTFILE.py --mc --no_exec --python_filename step1.py \
	    --step LHE,GEN,SIM --eventcontent RAWSIM --datatier GEN-SIM \
	    --conditions MCRUN2_71_V1::All \
	    --beamspot Realistic50ns13TeVCollision --magField 38T_PostLS1 \
	    --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring \
	    --customise_command "process.source.firstRun = cms.untracked.uint32(${SEED})" \
	    -n SUBNEVT --fileout file:step1.root 
    else 
	echo "Last step must be either GEN or SIM"
	exit 0 
    fi
elif [ ${SOURCE} == "LHE" ]; then 
    if [ ${LASTSTEP} == "GEN" ]; then
	cmsDriver.py SUBSCRIPTDIR/SUBSCRIPTFILE.py --mc --no_exec --python_filename step1.py \
	    --step GEN --eventcontent RAWSIM --datatier GEN \
	    --conditions auto:mc \
	    --customise_command "process.source.firstRun = cms.untracked.uint32(${SEED})" \
	    -n SUBNEVT --filein file:input.lhe --fileout file:step1.root
    else
        echo "Getting SIM from LHE not yet implemented"
        exit 0
    fi
else 
    echo "Source must be either NONE or LHE"
    exit 0
fi	

# adjust random numbers 
LINE=`egrep -n Configuration.StandardSequences.Services_cff step1.py | cut -d: -f1 `
sed -i "${LINE}"aprocess.RandomNumberGeneratorService.generator.initialSeed=${SEED} step1.py  
SEED=`echo "289634+${SGE_TASK_ID}" | bc`
sed -i "${LINE}"aprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${SEED} step1.py  

### markus :
#from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper
#randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)
#randSvc.populate()
#process.RandomNumberGeneratorService.saveFileName =  cms.untracked.string(
#        "RandomEngineState_${ID}.log"
#        )

#Need to set library path to allow job to acces python2.7 libs
#This is needed of the reweighting module
export LIBRARY_PATH=$LD_LIBRARY_PATH



## execute scripts 
echo "Run generation script"
cmsRun step1.py 

# copy output

cp step1.py SUBOUTPUTDIR/step1.py

cp cmsgrid_final.lhe SUBOUTPUTDIR/cmsgrid_final.lhe

cp step1.root SUBOUTPUTDIR/SUBOUTPUTFILE__${ID}.root 

#done 
echo -e "\nJob stoped at "`date`" on "`hostname --fqdn`"\n"

exit 0
