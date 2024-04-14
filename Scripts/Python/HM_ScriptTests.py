from Parameters import *
from EAConnect import *
from HM_Controls import *
import sys


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
input(timestamp + " " + 'Select package in EA and press Enter to continue...')
thePackage = eaRepo.GetTreeSelectedPackage()
printTS('Selected package name: ' + thePackage.Name)

# -------------------------------------------------------------------------------------
# Do something with the package

import pandas as pd
# df = pd.DataFrame(columns=['FullPath','Package','Element','Property','DependentPackage','DependentElement','GUID'])
# df = listClassifiers(eaRepo,thePackage,df)

# noRef = df[df['GUID'].isna()]
# errCount = len(noRef)
# printTS('')
# printTS('Number of errors: ' + str(errCount))

defDf = pd.DataFrame(columns=['Type','PackageName','ElementName','PropertyName','Supplier'])
defDf = listMissingDefinitions(eaRepo,thePackage,defDf)
