# bsdf-tools


## About

Tools for processing and converting BSDF/BRDF data, including RT-300S measurement handling and export to optical software formats.


## Repo

- _vendor == contains local (and potentially slightly modified) copies of open-source scripts
- data
  - images
  - processed == formatted files for stray light softwares
  - raw == raw (or nearly-raw) output from RT-300S, Blacklab, or other instruments
  - validation == validation checks of the processed and formatted data
- docs
- processing
  - _legacy
  - converters == scripts to convert files from one stray light software format to another
  - core == scripts to take raw data to a stray light software format (namely, FRED)
  - preprocessing == takes truly raw to nearly-raw (e.g., Blacklab voltages to BRF)
- supplemental == misc. measurements or other, such as surface roughness; not BRDF, but not unrelated
  - blacklab_mount_for_3x6in_samples == CAD for Blacklab sub-mount to support 3"x6" samples
  - csi_surface_roughness == measurements from Zygo NewView 8300
  - reflectance_vs_wavelength == measurements from ASD FieldSpec


## Using the repo

- Upload raw data to ```./data/raw```
- Process raw data into FRED using a script from ```./processing/core```
- Convert FRED file to Zemax using ```./processing/converters/fred_to_zemax.m```
- Convert Zemax file to Speos using ```./processing/converters/zemax_to_speos.py```
- Grab the generated files from ```./data/processed```, and upload to your stray light simulation




















---
---
---

# OLD:

## NOTES ON IN-PROGRESS ANISOTROPIC FRED ROUTINE (2026/03/16):

- 'rt300s_to_bsdf_aniso_devFRED_v1.m' produced 'DEBUG_ANISO_aniso.txt', which is IMX455 but only in measured quadrant of 'rot = [0, 90]'
- 'apply_yz_symm_to_aniso_FRED_data.m' applies BOTH yz and xz plane symmetries to 'DEBUG_ANISO_aniso.txt', to produce 'DEBUG_ANISO_aniso_SYMM.txt', which has mirrored data to 'rot = [0, 360)'
- i believe the code is fine, but it is messy

## RT-300S Data Processing Package

Author: Jacob P. Krell (jacobpkrell@arizona.edu)
Version: 1.0
Release Date: 2025/10/07

Contents:
- "AnoBlackNiTEonINVAR.bsdf" == BSDF file for Zemax Non-Sequential (official)
- "AnoBlackNiTEonSteel.bsdf" == BSDF file for Zemax Non-Sequential (official)
- "dummy.bsdf" == dummy BSDF file used by MATLAB scripts
- "IMX455.bsdf" == BSDF file for Zemax Non-Sequential (preliminary)
- "process_RT300S_data_v1o0.m" == MATLAB script to process measurements of sample with isotropic assumption (official, meaning it is believed to be working as expected without bugs)
- "process_RT300S_data_v1o0_anisotropic.m" == MATLAB script to process measurements of sample without isotropic assumption, i.e., anisotropic (preliminary, meaning it still needs some debugging regarding why some quadrants appear to have no BRDF values but overall seems mostly okay)
- "ValidationTest_of_BRDF_via_MagicBlack.bsdf" == BSDF file intended to validate order-of-magnitude of BRDF values converted from measured RT values of MagicBlack sample against known MagicBlack data provided by default in Zemax
- "ValidationTest_of_TIS_via_BrownVinyl.bsdf" == BSDF file intended to validate TIS calculation using known BRDF values of BrownVinyl provided by default in Zemax
- "ZemaxAnisotropicSampleRotationDefinition.png" == image showing x-axis of "IMX455.bsdf", which is how Zemax defines sample rotation
- "references" == folder of previous work (from Max) used and adapted for making this package
    - "BRDF_Machine_Whitepaper.pdf" == whitepaper of empirical tips for using the RT-300S machine beyond the user manual
    - "Figures with Error Bars.py" == figure-generating script
    - "masterBRDFcode.py" == data processing script
    - "Maxim Duque MS Thesis.pdf" == thesis, with Chapter 4 being specifically relevant
