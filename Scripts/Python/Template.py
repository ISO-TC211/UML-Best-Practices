from Parameters import *
from EAConnect import *
import sys

def recPckTraverse(pck):
    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('Package: ' + sPck.Name)
        recPckTraverse(sPck)

# -------------------------------------------------------------------------------------
# Open EA Repository and find Model
eaApp = openEAapp()
eaRepo = openEArepo(eaApp,repo_path)
try:
    omMod = eaRepo.Models.GetByName(modelName)
    printTS('Model "' + modelName + '" found with PackageGUID ' + omMod.PackageGUID )
except Exception as e:
    printTS('Model  "' + modelName + '" not found!')
    closeEA(eaRepo)
    sys.exit()
printTS('Number of main packages: ' + str(omMod.Packages.Count))
timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# -------------------------------------------------------------------------------------
# Select a package to work on
input(timestamp, " ", 'Select package in EA and press Enter to continue...')
thePackage = eaRepo.GetTreeSelectedPackage()
printTS('Selected package name: ' + thePackage.Name)

# -------------------------------------------------------------------------------------
# Do something with the package
recPckTraverse(thePackage)



