# bsdf-tools
Tools for processing and converting BSDF/BRDF data, including RT-300S measurement handling and export to optical software formats.

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
