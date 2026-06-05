Black Lab Angle Conversion Functions (MATLAB)
---------------------------------------------
Background:
---
In the Black Lab, radiometers measure light reflected off of a sample (such as a Spectralon panel) which is illuminated by a source (such as a NIST lamp). 
The goal is usually to characterize the reflectance properties of the sample as a function of four 'radiometry' angles - the source zenith angle, 
the source azimuthal angle, the view zenith angle, and the view azimuthal angle. To measure at all of these angles, the stage in the Black Lab controls the tip, tilt, 
and rotation of the sample, and the angular position of the arm holding the radiometer. These four 'stage' angles can be converted to 'radiometry' angles and vice versa 
using the MATLAB functions included in this folder.
---
Functions:
---
"UI_black_lab_angles.m" - User interface that accepts an input file of solar and view angles and outputs a second file of stage angles.
"stage2angles.m" - MATLAB function file which converts stage angles to their resulting radiometry angles
"compute_BL_angles.m" - MATLAB function file which converts radiometry angles to the stage angles required to obtain them
"azimuthal.m" - supporting function
"rodrigues.m" - supporting function
"zenith.m" - supporting function
---
Warning:
---
Previously, RSG used "nates_compute_BL_angles.m" to calculate the stage angles needed to obtain a specific source/view geometry. That file can be found in "F:\home\josie\Black Lab Stage Angle\Nate's code". This program had a logic error which resulted in incorrect stage angles for some radiometry angle inputs. The input radiometry angles were for uncommon measurement geometries, so the error went unnoticed until we were testing the "stage2angles.m" function. If I remember correctly, the error occured when measurements were taken from roughly the backscatter direction (i.e. the radiometer arm was rotated to one side of the stage and the panel was pointed towards the other).