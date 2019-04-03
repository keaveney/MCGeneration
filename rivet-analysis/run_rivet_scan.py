import os
from subprocess import call
import gzip
import shutil

#cmd = 'rivenv'
#call(['/bin/bash', '-i', '-c', cmd])

os.environ['RIVET_ANALYSIS_PATH'] = "/afs/cern.ch/work/k/keaveney/MCGeneration/MCGeneration/rivet-analysis/"

plugin = "FCCee_1D_DIFF"

#cmd = "rm Rivet" + plugin + ".so"
#call(['/bin/bash', '-i', '-c', cmd])

cmd = "rivet-buildplugin Rivet" + plugin + ".so " + plugin + ".cc"
call(['/bin/bash', '-i', '-c', cmd])

file_stem = "/tmp/4_ops_LO_dim6top_19-03-19_FCCee/Events"
file_tail = "tag_1_pythia8_events.hepmc"
scan_range = 4

for run in range(3,scan_range+1):
    if run < 10:
        run_string = "run_0" + str(run)
    else:
        run_string = "run_" + str(run)

    print "Processing " + run_string

    fin = file_stem + "/" + run_string + "/" + file_tail
    fout = file_stem + "/" + run_string + "/" + file_tail

    if (os.path.isfile(fin)==True):
        print "found unzipped file"
    elif (os.path.isfile(fin+".gz")==True):
        print "unzipping file"
        f_in = gzip.open(fin+".gz", 'rb')
        f_out = open(fout, 'wb') 
        shutil.copyfileobj(f_in, f_out)

    cmd = "rivet --analysis=" + plugin + " " + file_stem + "/" + run_string + "/" + file_tail
    call(cmd, shell=True)
    cmd = run_string + ".yoda"
    call(["cp", "Rivet.yoda", cmd])
