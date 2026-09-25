
## Sample Sets

Control Set
- B1: Z307 on Al, 12x12
- B2: Z307 on Invar, 3x6
- B3: NiTE on Invar,
  - B3a: 12x12
  - B3b: 3x6
- B4: Optical Black Anodize, 12x12
- B5: Titanium Anodize, 12x12

12-Cycle Set
- C1: Z307 on Al, 3x6
- C2: Z307 on Invar, 3x6
- C3: NiTE on Invar, 3x6

~40-Cycle Set
- D1: 
- D2: 
- D3: 

---

## Prior

- measured 365 and 1061 nm of Control Set
- for 3x6, used large FOV
- for B3, measured both B3a (3x6) and B3b (12x12)

## Week of 07 Sep 2026

- All 3x6 measurements are now with radiometer's small FOV
- Validation test of small-FOV 3x6:
    - repeated measurement of 365 and 1061 nm of B3b (but with small FOV)
    - pending data analysis, for comparison to B3a
- New wavelengths:
    - measured 632 and 850 nm of Control Set (minus B3a, B5)
- Acquired 12-Cycle Set
    - measured 365, 632, 850, and 1061 nm of C1, C2, and C3
        - (C2 and C3 measured 14 Sep)

## Week of 14 Sep 2026

- Switched to SWIR
- See table below for plan

| Set | Index | Sample | Dimensions [in] | Wavelengths [nm] | Priority |
|---|---|---|---|---|---|
| Control Set | B1 | Z307 on Al | 12x12 | 1244, 1646 | 1 |
| Control Set | B2 | Z307 on Invar | 3x6 | 1244, 1646 | 1 |
| Control Set | B3a | NiTE on Invar | 12x12 | 1244, 1646 | 1 |
| Control Set | B3b | NiTE on Invar | 3x6 | 1244, 1646 | 2 |
| Control Set | B4 | Optical Black Anodize | 12x12 | none | - |
| Control Set | B5 | Titanium Anodize | 12x12 | none | - |
| 12-Cycle Set | C1 | Z307 on Al | 3x6 | 1244, 1646 | 3 |
| 12-Cycle Set | C2 | Z307 on Invar | 3x6 | 1244, 1646 | 3 |
| 12-Cycle Set | C3 | NiTE on Invar | 3x6 | 1244, 1646 | 3 |
| ~40-Cycle Set | D1 | Z307 on Al | 3x6 | 1244, 1646 | 2 |
| ~40-Cycle Set | D2 | Z307 on Invar | 3x6 | 1244, 1646 | 2 |
| ~40-Cycle Set | D3 | NiTE on Invar | 3x6 | 1244, 1646 | 2 |

\
**Notes:**
- 12x12 uses large FOV; 3x6 uses small FOV
- If same angle set as VNIR, then expecting 28 angles per AOI, 4 AOI per wavelegnth, 2 wavelengths per sample, and 10 samples... plus 2 angles (before and after known NIST angles) per wavelength
  - $\implies (2+28\cdot4)\cdot2 = 228$ angles per sample
  - if Priority 1 and 2, then $(3+4)\cdot228 = 1596$ angles total
  - if also Priority 3, then $(3+4+3)\cdot228 = 2280$ angles total













