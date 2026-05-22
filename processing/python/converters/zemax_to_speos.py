# =========================================================================
# =========================================================================
# 
# zemax_to_speos.m
# 
# Description:
#   - Convert Zemax *.bsdf file to SPEOS *.anisotropicbsdf file.
# 
# Assumptions:
#   1) Uses Python module like example in [1].
# 
# Developer(s):
#   - Jacob P. Krell (JPK)
#       - LOFT research assistant
#       - MS Optomechanical Engineering, 
#         Wyant College of Optical Sciences, University of Arizona
#       - jacobpkrell@arizona.edu, jakepkrell@gmail.com
#
# Development History:
# | Date       | Dev. | Comment(s)                                        |
# |------------|------|---------------------------------------------------|
# | 2026.05.22 | JPK  | Initialized;                                      |
# 
# References:
# [1] https://github.com/ansys/optical-automation/blob/main/ansys_optical_automation/application/BSDF_converter_example.py
# 
# =========================================================================
# =========================================================================
# =========================================================================
# =========================================================================

# =========================================================================
# [BEGIN] IMPORT MODULES:

# Add local libraies to path:
from pathlib import Path
import sys
REPO_ROOT = Path(__file__).resolve().parents[4]
VENDOR_ROOT = REPO_ROOT / "_vendor" / "ansys" / "optical-automation"
if str(VENDOR_ROOT) not in sys.path:
    sys.path.insert(0, str(VENDOR_ROOT))

# Import modules:
from ansys_optical_automation.interop_process.BSDF_converter import BsdfStructure

# [END] IMPORT MODULES.
# =========================================================================
# =========================================================================
# [BEGIN] USER INPUTS:

filepath_zemax = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\MagicBlackOnAlum.bsdf"  # filepath to Zemax *.bsdf file

# [END] USER INPUTS.
# =========================================================================
# =========================================================================
# [BEGIN] CONVERT FILE:

def main(filepath_zemax):
    """Convert Zemax *.bsdf file to SPEOS *.anisotropicbsdf file."""
    
    bsdf_data = BsdfStructure()  # init class
    bsdf_data.filename_input = filepath_zemax  # specify Zemax *.bsdf file
    bsdf_data.import_data(0)
    bsdf_data.output_choice = 3  # output to *.anisotropicbsdf file; *.brdf file not yet supported by Python module
    bsdf_data.write_speos_anisotropicbsdf_file()  # write to new SPEOS file
    
    return


if __name__ == "main":
    main(filepath_zemax)

