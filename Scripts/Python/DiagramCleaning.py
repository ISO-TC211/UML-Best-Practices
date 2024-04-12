from Parameters import *
from EAConnect import *
import sys

def replace_all_fonts(text, new_font="Cambria"):
  """Replaces all font names in a string with a new font name.
  Args:
      text: The string to modify.
      new_font: The new font name (default: "Cambria").
  Returns:
      The modified string with all font names replaced.
  """
  parts = text.split(';')
  for i, part in enumerate(parts):
    if part.lower().startswith('font='):
      parts[i] = f"font={new_font}"  # Use f-string for direct insertion
  return ';'.join(parts)

def hideLMB(text):
    parts = text.split(';')
    for i, part in enumerate(parts):
        if part.startswith('LMB='):
            subparts = parts[i].split(':')
            for j, subpart in enumerate(subparts):
                if subpart == 'HDN=0':
                    subparts[j] = f"HDN=1"  # Use f-string for direct insertion
            parts[i] = ':'.join(subparts)        
    return ';'.join(parts)

def recPckTraverse(pck):
    #Loop through diagrams in the package
    printTS('Diagram count: ' + str(pck.Diagrams.Count))
    for eaDgr in pck.Diagrams:
        printTS('Diagram: ' + eaDgr.Name)
        printTS('Number of objects: ' + str(eaDgr.DiagramObjects.Count))
        for eaDgrObj in eaDgr.DiagramObjects:
            # Set all fonts to Cambria
            try:
                if 'font=' in eaDgrObj.Style:
                    printTS('Object style: ' + eaDgrObj.Style)
                    new_text = replace_all_fonts(eaDgrObj.Style)
                    printTS('New style: ' + new_text)
                    eaDgrObj.Style = new_text
                    eaDgrObj.Update()
            except:
                printTS('No object style')

        for eaDrgLink in eaDgr.DiagramLinks:
            # Hide the "isSubstitutable" label (Middle Bottom Label, LMB)
            if 'LMB=' in eaDrgLink.Geometry:
                #Check and replace substring HDN=0 with HDN=1
                if 'HDN=0' in eaDrgLink.Geometry:
                    printTS('Diagramlink style: ' + eaDrgLink.Geometry)
                    new_text = hideLMB(eaDrgLink.Geometry)
                    eaDrgLink.Geometry = new_text
                    eaDrgLink.Update()

    #Traverse the package structure
    for sPck in pck.Packages:
        printTS('----------------------------')
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
input(timestamp + " " + 'Select package in EA and press Enter to continue...')
thePackage = eaRepo.GetTreeSelectedPackage()
printTS('Selected package name: ' + thePackage.Name)

# -------------------------------------------------------------------------------------
# Do something with the package

recPckTraverse(thePackage)



