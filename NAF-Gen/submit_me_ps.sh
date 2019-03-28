#!/bin/bash

### generic settings 
RESUBMIT=0
NJOBS=325       # irrelevant if input source lhe files     
SUBNEVT=20000     

GENERATOR=mg5_amcatnlo # mg5_amcatnlo or powheg
SUBLASTSTEP=GEN   # GEN or SIM
SUBSCRIPTDIR=Configuration/GenProduction/python
MCHI=NONE
MPHI=NONE
SUBGRIDPACK=NONE
SUBSOURCE=NONE
INPUTTAG=files

### ttbar DM MG5_aMC@NLO setup 
LAMBDA=1000      #     1  50    10 
CG=2 # 10000  10   100 

OUTPUTTAG=( ttbar_NLO_nnpdf3p0_4fpdfalhpas_lambda_${LAMBDA}_CG_${CG}_13TeV ) 

#SUBGRIDPACK=( DMScalar_ttbar_mphi_${MPHI}_mchi_${MCHI}_gSM_1p0_gDM_1p0 DMPseudoscalar_ttbar_mphi_${MPHI}_mchi_${MCHI}_gSM_1p0_gDM_1p0 )
SUBGRIDPACK=( EFT_ttbar_NLO_lambda_${LAMBDA}_CG_${CG} )

#SUBSCRIPT=( mg5_aMCatNLO_ttbar )
#SUBSCRIPT=( mg5_aMCatNLO_EFT_tt ) #Hadronizer_TuneCUETP8M1_13TeV_generic_LHE_pythia8_cff )                                                        
SUBSCRIPT=( mg5_aMCatNLO_EFT_tt_noMerging )

FILEBASE=( EFT_TT_TuneCUETP8M1_13TeV_mg5_amcatnlo_pythia8_LHEWeights ) 

echo "Starting job submission"

### start job submission 
JOBID=`echo "scale=0; ${#OUTPUTTAG[@]} -1 " | bc` 
for IJOBID in `seq 0 ${JOBID}`; do
    SUBOUTPUTFILE=${FILEBASE[${IJOBID}]}__GENSIM
#    SUBINPUTDIR=/nfs/dust/cms/user/agrohsje/samples/cms/validation/${GENERATOR}/lhegen/${INPUTTAG[${IJOBID}]}
 #   SUBINPUTDIR=/afs/desy.de/user/k/keaveney/xxl/aMCNLO-Gen/LHE/${INPUTTAG[${IJOBID}]}

    SUBINPUTDIR=/afs/desy.de/user/k/keaveney/xxl/aMCNLO-Gen/genproductions/bin/MadGraph5_aMCatNLO/MG5_aMC_v2_5_2/PROCNLO_ttbar_NLO_0/Events/run_08_decayed_1
    echo "INPUTDIR  = > " $SUBINPUTDIR
    if [ ${SUBSOURCE} == "LHE" ] ; then 
	NJOBS=`ls ${SUBINPUTDIR}/*.lhe.tar.gz | wc -l`
	#agrohsje remove later 
	NJOBS=1
    fi    
    if [ ${SUBLASTSTEP} == "SIM" ] ; then
	#SUBOUTPUTDIR=/nfs/dust/cms/user/agrohsje/samples/cms/validation/${GENERATOR}/gensim/${OUTPUTTAG[${IJOBID}]}
        #SUBOUTPUTDIR=/afs/desy.de/user/k/keaveney/xxl/aMCNLO-Gen/genvalidations/${GENERATOR}/gensim/${OUTPUTTAG[${IJOBID}]}
	 SUBOUTPUTDIR=/nfs/dust/cms/user/keaveney/samples/EFT_tt/rev_0/${GENERATOR}/gensim/${OUTPUTTAG[${IJOBID}]} 
    else
   #     SUBOUTPUTDIR=/afs/desy.de/user/k/keaveney/xxl/aMCNLO-Gen/genvalidations/${GENERATOR}/evgen/${OUTPUTTAG[${IJOBID}]}
#	SUBOUTPUTDIR=/nfs/dust/cms/user/agrohsje/samples/cms/validation/${GENERATOR}/evgen/${OUTPUTTAG[${IJOBID}]}
	 SUBOUTPUTDIR=/nfs/dust/cms/user/keaveney/samples/EFT_tt/rev_0/${GENERATOR}/gensim/${OUTPUTTAG[${IJOBID}]}
    fi
    ### resubmit jobs that failed 
    if [ ${RESUBMIT} == "1" ] ; then
	for IJOB in `seq 1 ${NJOBS}`; do
	    ID="$(printf '%05d' "${IJOB}")"
	    if [ ! -f ${SUBOUTPUTDIR}/${SUBOUTPUTFILE}__${ID}.root ] ; then
		echo "missing file ${SUBOUTPUTDIR}/${SUBOUTPUTFILE}__${ID}.root"
                qsub -N ${OUTPUTTAG[${IJOBID}]} -V -j y -m as -o ${SUBOUTPUTDIR} \
		    -l h_rt=48:00:00 -l h_vmem=8G -l distro=sld6 \
		    -t ${IJOB}:${IJOB}  ${SUBOUTPUTDIR}/scripts/${OUTPUTTAG[${IJOBID}]}.sh
            fi
        done
    ### initial job submission 
    else
        mkdir -p ${SUBOUTPUTDIR}/scripts
	echo "OUTPUT DIR " ${SUBOUTPUTDIR}
	### create temporay python script for hadronizer
        echo "Copying template handronizer script: "   ${CMSSW_BASE}/src/${SUBSCRIPTDIR}/${SUBSCRIPT[${IJOBID}]}.py
	cp ${CMSSW_BASE}/src/${SUBSCRIPTDIR}/${SUBSCRIPT[${IJOBID}]}.py ${SUBOUTPUTDIR}/scripts/${SUBSCRIPT[${IJOBID}]}_${OUTPUTTAG[${IJOBID}]}.py 
	sed -i -e "s#GRIDPACK#${SUBGRIDPACK[${IJOBID}]}#g" ${SUBOUTPUTDIR}/scripts/${SUBSCRIPT[${IJOBID}]}_${OUTPUTTAG[${IJOBID}]}.py 
	
	### create job bash file 
	cp base_me_ps.sh ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBINPUTDIR|${SUBINPUTDIR}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBOUTPUTDIR|${SUBOUTPUTDIR}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBOUTPUTFILE|${SUBOUTPUTFILE}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBSCRIPTDIR|${SUBSCRIPTDIR}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBSCRIPTFILE|${SUBSCRIPT[${IJOBID}]}_${OUTPUTTAG[${IJOBID}]}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBNEVT|${SUBNEVT}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBSOURCE|${SUBSOURCE}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	sed -i -e "s|SUBLASTSTEP|${SUBLASTSTEP}|g" ${OUTPUTTAG[${IJOBID}]}.sh 
	chmod +x ${OUTPUTTAG[${IJOBID}]}.sh
	mv ${OUTPUTTAG[${IJOBID}]}.sh ${SUBOUTPUTDIR}/scripts/.
	echo "Copying job bash file " ${OUTPUTTAG[${IJOBID}]}.sh " to " ${SUBOUTPUTDIR}/scripts/.

	qsub -N ${OUTPUTTAG[${IJOBID}]} -V -j y -m as -o ${SUBOUTPUTDIR} \
	    -l h_rt=24:00:00 -l h_vmem=8G  -l distro=sld6 \
	    -t 1:${NJOBS} ${SUBOUTPUTDIR}/scripts/${OUTPUTTAG[${IJOBID}]}.sh 
	sleep 2s
    fi
done
