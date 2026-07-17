

Notes for Blacklab operation
2026/05/23


Checklist:
- Leave 2 powered on if measuring overnight
- Power on lamp (below the 2)
- Power on actuators (3 stages) - ensemble
- Power on 4th axis (stage rotation)
- Inside Blacklab room is specific to radiometer
- VNIR:
    - Power on bottom left — leave on overnight
    - Power on lambda 10-2 (top), to control 2 filter wheels
- Middle box specific to SWIR

Software:
    - First step:
        - PCSRad - right click , run as admin
        - DXW, turn on —- will ramp up physical lamp box
    - Second step (log for lamp):
        -  Lab view — run pinned RSG_VNIR
        - Grid means not running, click run (top left)
        - Use stop in grid area GUI, not drop down GUI
    - Third step (log file for temperature and humidity gauge; independent from other log lab view ):
        - Second lab view … run pinned sample_record
        - Use stop in grid area GUI, not drop down GUI
    - Fourth step:
        - Visual studio (older version)
        - Open ucla script for vnir
        - Where raw data from VNIR gets saved: VS folder - projects - ucla - ucla (where angle set, and other c code lives)
        - note to define which filters to use, change 'filters_to_do[]' variable and look at 'che_gain_wavel.txt' file to get filter index, gain exponent value, filter nm
    
- Angle sets:
    - Very roughly, 19 angles per 5 minutes (50 mins, 19x11 angles) —> 500 angles per 2 hours 
    - (for lamp stability) Sub angle sets should be ~90 mins, ~120 mins max



