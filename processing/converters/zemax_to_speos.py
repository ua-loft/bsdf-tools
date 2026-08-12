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
REPO_ROOT = Path(__file__).resolve().parents[2]  # ../processing/converters/zemax_to_speos.py --> ../_vendor/ansys/optical-automation
VENDOR_ROOT = REPO_ROOT / "_vendor" / "ansys" / "optical-automation"
if str(VENDOR_ROOT) not in sys.path:
    sys.path.insert(0, str(VENDOR_ROOT))

print(VENDOR_ROOT)

# Import modules:
from ansys_optical_automation.interop_process.BSDF_converter import BsdfStructure  # local module

# [END] IMPORT MODULES.
# =========================================================================
# =========================================================================
# [BEGIN] USER INPUTS:

filepath_zemax = "C:\\Users\\jakep\\Documents\\Optics_local\\UofA\\bsdf-tools\\data\\processed\\zemax\\Z306_from_FRED_20260811\\tabulated_FRED_Z306_TIS0o04_specAzi0d.bsdf"  # filepath to Zemax *.bsdf file
filepath_speos = "C:\\Users\\jakep\\Documents\\Optics_local\\UofA\\bsdf-tools\\data\\processed\\speos\\Z306_from_FRED_20260811\\tabulated_FRED_Z306_TIS0o04_specAzi0d.anisotropicbsdf"  # filepath to SPEOS *.anisotropicbsdf file

# [END] USER INPUTS.
# =========================================================================
# =========================================================================
# [BEGIN] CONVERT FILE:

def main(filepath_zemax, filepath_speos):
    """Convert Zemax *.bsdf file to SPEOS *.anisotropicbsdf file."""
    
    bsdf_class = BsdfStructure()  # init class
    bsdf_class.filename_input = filepath_zemax  # specify Zemax *.bsdf file
    bsdf_class.import_data(0)
    bsdf_class.output_choice = 3  # output to *.anisotropicbsdf file; *.brdf file not yet supported by Python module
    bsdf_class.filename_output = filepath_speos  # specify SPEOS *.anisotropicbsdf file
    bsdf_class.write_speos_anisotropicbsdf_file()  # write to new SPEOS file
    
    return


if __name__ == "__main__":
    main(filepath_zemax, filepath_speos)

