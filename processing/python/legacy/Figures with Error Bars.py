# BRDF Data Correction, Averaging, and Plotting
# Written by Max Duque 03/25/2025

# region Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from scipy.integrate import simpson
from scipy.interpolate import UnivariateSpline
import matplotlib.ticker as mtick
from matplotlib.ticker import MaxNLocator
# endregion

# region Section 0: Data collection and conversion

# sample_data = "aeroglaze_final.xls"
# sample_data = "dsb_final.xls"
# sample_data = "singularity_verification_2.xls"

# sample_data = "dsb_final.xls"
# sample_data = "blank_final.xls"

sample_data = "01aeroglaze.xls"
sample_data2 = "02aeroglaze.xls"
sample_data3 = "03aeroglaze.xls"

# sample_data = "01singularity.xls"
# sample_data2 = "02singularity.xls"
# sample_data3 = "03singularity.xls"

# sample_data = "lambertian.xls"
# sample_data = "lambertian2.xls"

# blank_data = "blank_retest.xls"
blank_data = "blank_final_please.xls"

# Degree of the polynomial for polyfit
degree = 8
# Spline smoothing factor
smoothing_factor = .00005

# Determine material name based on selected sample_data file
if "aeroglaze" in sample_data.lower():
    material_name = "Aeroglaze"
elif "dsb" in sample_data.lower():
    material_name = "DSB"
elif "singularity" in sample_data.lower():
    material_name = "Singularity"
elif "lambertian" in sample_data.lower():
    material_name = "Lambertian"
else:
    material_name = "Sample"  # Default case if filename doesn't match expected names


# Load all sheets into a dictionary of DataFrames
data_sheets = pd.read_excel(sample_data, sheet_name=None)
blank_sheets = pd.read_excel(blank_data, sheet_name=None)

# Initialize empty DataFrames to hold the combined data
data_cdf = pd.DataFrame()
blank_cdf = pd.DataFrame()

# Iterate through each sheet and concatenate horizontally for data_cdf
for sheet_name, df in data_sheets.items():
    df.reset_index(drop=True, inplace=True)
    data_cdf = pd.concat([data_cdf, df], axis=1)

# Drop rows with all NaN values in data_cdf
data_cdf = data_cdf.dropna(how='all')
data_cdf = data_cdf.loc[:, data_cdf.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]
# print(data_cdf.iloc[8])

# Iterate through each sheet and concatenate horizontally for blank_cdf
for sheet_name, df in blank_sheets.items():
    df.reset_index(drop=True, inplace=True)
    blank_cdf = pd.concat([blank_cdf, df], axis=1)

# Drop rows with all NaN values in blank_cdf
blank_cdf = blank_cdf.dropna(how='all')
blank_cdf = blank_cdf.loc[:, blank_cdf.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]
# print(blank_cdf.iloc[8])

# Extract unique incidence and receive angles
incidence_row = data_cdf.iloc[7]
unique_incidences = incidence_row.unique()
number_of_incidences = len(unique_incidences)

receive_row = data_cdf.iloc[8][:]  # Skip potential header
unique_receives = [item for item in receive_row.unique() if isinstance(item, (int, float))]
positive_receives = [item for item in unique_receives if item >= 0]
number_of_receives = len(positive_receives)
# endregion

# region Section 1: Subtract blank measurement from RT measurement
# Convert 22nd row data to numeric and filter valid values
data_rt = pd.to_numeric(data_cdf.iloc[21], errors='coerce')
blank_rt = pd.to_numeric(blank_cdf.iloc[21], errors='coerce')

# Filter out NaN values to ensure valid calculations
valid_mask = data_rt.notna()
data_rt = data_rt[valid_mask]
blank_rt = blank_rt[valid_mask]

# Calculate the difference between data_rt and blank_rt
rt = data_rt - blank_rt

# Convert angles in the 9th row to radians and compute cosines
angles = data_cdf.iloc[8].astype(float)
receive_angles_radians = np.radians(angles)  # Ensure numeric
cosine_angles = np.cos(receive_angles_radians)

# Handle NaN values in cosine_angles
valid_cosine_mask = ~np.isnan(cosine_angles)
cosine_angles = cosine_angles[valid_cosine_mask]
rt = rt[valid_cosine_mask]  # Align RT to valid cosine indices

# Get non-shifted BRDF values

# Calculate BRDF denominator and BRDF
brdf_denom = np.pi * cosine_angles # Using the filtered cosine angles
brdf = rt / brdf_denom  # Calculate BRDF
# brdf = rt # for raw data plot

# endregion

# region Section 2: Plot subtracted data on a single graph
plt.figure(figsize=(10, 6))
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through unique incidence angles
for i, incidence in enumerate(unique_incidences):
    # Filter columns corresponding to the current incidence angle
    incidence_mask = (data_cdf.iloc[7] == incidence)

    # Get the receive/emergence angles and corresponding RT values
    receive_angles_i = data_cdf.loc[8, incidence_mask].astype(float)
    valid_mask = incidence_mask & ~np.isnan(rt)  # Ensure valid data points
    rt_i = data_rt[valid_mask]

    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_i) == 0 or len(rt_i) == 0:
        continue

    # Plot data on a single graph
    plt.plot(receive_angles_i, rt_i, 'o', label=f'Incidence {incidence}°', color=colors_raw[i])

# Formatting the plot
plt.title(f"Raw RT Data for {material_name}")
plt.xlabel("Receive Angle (degrees)")
plt.ylabel("Relative Reflectance")
plt.legend()
plt.grid(True)
plt.tight_layout()

# Show the final plot
# plt.show()

# endregion

plt.figure(figsize=(10, 6))
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through unique incidence angles
for i, incidence in enumerate(unique_incidences):
    # Filter columns corresponding to the current incidence angle
    incidence_mask = (data_cdf.iloc[7] == incidence)

    # Get the receive/emergence angles and corresponding RT values
    receive_angles_i = data_cdf.loc[8, incidence_mask].astype(float)
    valid_mask = incidence_mask & ~np.isnan(rt)  # Ensure valid data points
    rt_i = blank_rt[valid_mask]

    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_i) == 0 or len(rt_i) == 0:
        continue

    # Plot data on a single graph
    plt.plot(receive_angles_i, rt_i, 'o', label=f'Incidence {incidence}°', color=colors_raw[i])

# Formatting the plot
plt.title("Blank Measurement RT")
plt.xlabel("Receive Angle (degrees)")
plt.ylabel("Relative Reflectance")
plt.legend()
plt.grid(True)
plt.tight_layout()

# Show the final plot
# plt.show()

plt.figure(figsize=(10, 6))
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through unique incidence angles
for i, incidence in enumerate(unique_incidences):
    # Filter columns corresponding to the current incidence angle
    incidence_mask = (data_cdf.iloc[7] == incidence)

    # Get the receive/emergence angles and corresponding RT values
    receive_angles_i = data_cdf.loc[8, incidence_mask].astype(float)
    valid_mask = incidence_mask & ~np.isnan(rt)  # Ensure valid data points
    rt_i = rt[valid_mask]

    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_i) == 0 or len(rt_i) == 0:
        continue

    # Plot data on a single graph
    plt.plot(receive_angles_i, rt_i, 'o', label=f'Incidence {incidence}°', color=colors_raw[i])

# Formatting the plot
plt.title(f"{material_name} RT Measurement - Blank Measurement RT")
plt.xlabel("Receive Angle (degrees)")
plt.ylabel("Relative Reflectance")
plt.legend()
plt.grid(True)
plt.tight_layout()

# Show the final plot
# plt.show()
#endregion

# region Section 3: Filter BRDF and plot data

# Initialize lists to store results for each incidence angle
brdf_filtered_list = []
receive_angles_filtered_list = []

# Loop through each unique incidence angle and shift the RT values
for incidence in unique_incidences:
    # Filter RT data corresponding to the current incidence angle
    incidence_mask = (data_cdf.iloc[7] == incidence)  
    rt_for_incidence = rt[incidence_mask]  

    # Get the corresponding receive angles
    receive_angles_for_incidence = receive_row[incidence_mask]  
    
    # Shift RT values so that the minimum value becomes 0
    rt_shifted_for_incidence = rt_for_incidence - rt_for_incidence.min()

    # Remove data in the range n-5 to n+5
    min_angle = -incidence - 5
    max_angle = -incidence + 5

    # Apply filter to remove the specified range
    filter_mask = (receive_angles_for_incidence < min_angle) | (receive_angles_for_incidence > max_angle)
    rt_filtered = rt_shifted_for_incidence[filter_mask]
    receive_angles_filtered = receive_angles_for_incidence[filter_mask]

    # Filter cosine angles
    cosine_angles_filtered = cosine_angles[incidence_mask][filter_mask]

    # Compute BRDF
    brdf_filtered = rt_filtered / (np.pi * cosine_angles_filtered)

    # Append filtered data
    brdf_filtered_list.append(brdf_filtered)
    receive_angles_filtered_list.append(receive_angles_filtered)

# Define color map
plt.figure(figsize=(10, 6))
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through filtered BRDF data and plot all on the same figure
for i, (brdf_filtered, receive_angles_filtered) in enumerate(zip(brdf_filtered_list, receive_angles_filtered_list)):
    plt.plot(
        receive_angles_filtered, 
        brdf_filtered, 
        'o', 
        label=f'Incidence {unique_incidences[i]}°', 
        color=colors_raw[i]
    )

# Set title dynamically based on the material name
plt.title(f"Corrected BRDF Data for {material_name}")

# Labels and formatting
plt.xlabel("Receive/Emergence Angle (degrees)")
plt.ylabel("BRDF")
plt.yscale('log')
plt.legend()
plt.grid(True)
plt.tight_layout()

# Show the plot
# plt.show()

#endregion

# region Section 4: Log-Based Spline Fit on a Single Plot

# Initialize a dictionary to store BRDF spline fit values
brdf_spline_fit_values = {}

# Define color map for the plots
plt.figure(figsize=(10, 6))
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Smoothing factor for spline fits
smoothing_factor = 5e-2  # Optimized for stability

# Iterate through the filtered data for each unique incidence angle
for i, incidence in enumerate(unique_incidences):
    if i >= len(brdf_filtered_list) or i >= len(receive_angles_filtered_list):
        continue  # Skip if indices are out of bounds

    brdf_filtered = np.array(brdf_filtered_list[i], dtype=float)
    receive_angles_filtered = np.array(receive_angles_filtered_list[i], dtype=float)

    # Remove NaN and negative BRDF values
    valid_mask = (~np.isnan(brdf_filtered)) & (brdf_filtered > 0) & (~np.isnan(receive_angles_filtered))
    receive_angles_filtered = receive_angles_filtered[valid_mask]
    brdf_filtered = brdf_filtered[valid_mask]

    if len(receive_angles_filtered) == 0 or len(brdf_filtered) == 0:
        print(f"Skipping incidence {incidence}: No valid data.")
        continue

    # Apply log transformation
    log_brdf = np.log10(brdf_filtered)

    # Fit spline to log-transformed data
    spline_log = UnivariateSpline(receive_angles_filtered, log_brdf, s=smoothing_factor)

    # Define full receive angles within valid range
    full_receive_angles = np.linspace(receive_angles_filtered.min(), receive_angles_filtered.max(), 161)

    # Convert back from log scale
    fitted_spline_log = 10**spline_log(full_receive_angles)

    # Store the spline fit values for this incidence angle
    brdf_spline_fit_values[incidence] = fitted_spline_log.tolist()

    # Debugging: Verify that data is being stored correctly
    print(f"Stored spline fit for incidence {incidence}: {len(fitted_spline_log)} points.")


# Show the plot
# plt.show()

# Show the plot
# plt.show()

# endregion

# Load all sheets into a dictionary of DataFrames for sample_data2 and sample_data3
data_sheets2 = pd.read_excel(sample_data2, sheet_name=None)
data_sheets3 = pd.read_excel(sample_data3, sheet_name=None)

blank_sheets2 = pd.read_excel(blank_data, sheet_name=None)
blank_sheets3 = pd.read_excel(blank_data, sheet_name=None)

# Initialize empty DataFrames to hold the combined data for sample_data2 and sample_data3
data_cdf2 = pd.DataFrame()
data_cdf3 = pd.DataFrame()

blank_cdf2 = pd.DataFrame()
blank_cdf3 = pd.DataFrame()

# Iterate through each sheet and concatenate horizontally for data_cdf2
for sheet_name, df in data_sheets2.items():
    df.reset_index(drop=True, inplace=True)
    data_cdf2 = pd.concat([data_cdf2, df], axis=1)

# Drop rows with all NaN values in data_cdf2
data_cdf2 = data_cdf2.dropna(how='all')
data_cdf2 = data_cdf2.loc[:, data_cdf2.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]

# Iterate through each sheet and concatenate horizontally for blank_cdf2
for sheet_name, df in blank_sheets2.items():
    df.reset_index(drop=True, inplace=True)
    blank_cdf2 = pd.concat([blank_cdf2, df], axis=1)

# Drop rows with all NaN values in blank_cdf2
blank_cdf2 = blank_cdf2.dropna(how='all')
blank_cdf2 = blank_cdf2.loc[:, blank_cdf2.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]

# Iterate through each sheet and concatenate horizontally for data_cdf3
for sheet_name, df in data_sheets3.items():
    df.reset_index(drop=True, inplace=True)
    data_cdf3 = pd.concat([data_cdf3, df], axis=1)

# Drop rows with all NaN values in data_cdf3
data_cdf3 = data_cdf3.dropna(how='all')
data_cdf3 = data_cdf3.loc[:, data_cdf3.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]

# Iterate through each sheet and concatenate horizontally for blank_cdf3
for sheet_name, df in blank_sheets3.items():
    df.reset_index(drop=True, inplace=True)
    blank_cdf3 = pd.concat([blank_cdf3, df], axis=1)

# Drop rows with all NaN values in blank_cdf3
blank_cdf3 = blank_cdf3.dropna(how='all')
blank_cdf3 = blank_cdf3.loc[:, blank_cdf3.iloc[8].apply(lambda x: isinstance(x, (int, np.integer)))]

# Extract unique incidence and receive angles for sample_data2 and sample_data3
incidence_row2 = data_cdf2.iloc[7]
unique_incidences2 = incidence_row2.unique()

incidence_row3 = data_cdf3.iloc[7]
unique_incidences3 = incidence_row3.unique()

receive_row2 = data_cdf2.iloc[8][:]  # Skip potential header
receive_row3 = data_cdf3.iloc[8][:]

# Get non-shifted RT values for sample_data2 and sample_data3
data_rt2 = pd.to_numeric(data_cdf2.iloc[21], errors='coerce')
blank_rt2 = pd.to_numeric(blank_cdf2.iloc[21], errors='coerce')

data_rt3 = pd.to_numeric(data_cdf3.iloc[21], errors='coerce')
blank_rt3 = pd.to_numeric(blank_cdf3.iloc[21], errors='coerce')

# Filter out NaN values to ensure valid calculations for sample_data2 and sample_data3
valid_mask2 = data_rt2.notna()
data_rt2 = data_rt2[valid_mask2]
blank_rt2 = blank_rt2[valid_mask2]

valid_mask3 = data_rt3.notna()
data_rt3 = data_rt3[valid_mask3]
blank_rt3 = blank_rt3[valid_mask3]

# Calculate RT for sample_data2 and sample_data3
rt2 = data_rt2 - blank_rt2
rt3 = data_rt3 - blank_rt3

# Convert angles in the 9th row to radians for sample_data2 and sample_data3
angles2 = data_cdf2.iloc[8].astype(float)
angles3 = data_cdf3.iloc[8].astype(float)

receive_angles_radians2 = np.radians(angles2)  # Ensure numeric
receive_angles_radians3 = np.radians(angles3)  # Ensure numeric

# Calculate cosine values for receive angles for sample_data2 and sample_data3
cosine_angles2 = np.cos(receive_angles_radians2)
cosine_angles3 = np.cos(receive_angles_radians3)

# Filter NaN values from cosine angles for sample_data2 and sample_data3
valid_cosine_mask2 = ~np.isnan(cosine_angles2)
cosine_angles2 = cosine_angles2[valid_cosine_mask2]
rt2 = rt2[valid_cosine_mask2]

valid_cosine_mask3 = ~np.isnan(cosine_angles3)
cosine_angles3 = cosine_angles3[valid_cosine_mask3]
rt3 = rt3[valid_cosine_mask3]

# Calculate BRDF for sample_data2 and sample_data3
brdf_denom2 = np.pi * cosine_angles2
brdf_denom3 = np.pi * cosine_angles3

brdf2 = rt2 / brdf_denom2
brdf3 = rt3 / brdf_denom3

# endregion

# region Section 3: Filter BRDF for sample_data2 and sample_data3

# Initialize lists to store results for each incidence angle for sample_data2 and sample_data3
brdf_filtered_list2 = []
receive_angles_filtered_list2 = []

brdf_filtered_list3 = []
receive_angles_filtered_list3 = []

# Loop through each unique incidence angle for sample_data2
for incidence in unique_incidences2:
    # Filter RT data corresponding to the current incidence angle
    incidence_mask2 = (data_cdf2.iloc[7] == incidence)
    rt_for_incidence2 = rt2[incidence_mask2]

    # Get the corresponding receive angles
    receive_angles_for_incidence2 = receive_row2[incidence_mask2]

    # Shift RT values so that the minimum value becomes 0
    rt_shifted_for_incidence2 = rt_for_incidence2 - rt_for_incidence2.min()

    # Remove data in the range n-5 to n+5
    min_angle2 = -incidence - 5
    max_angle2 = -incidence + 5

    # Apply filter to remove the specified range
    filter_mask2 = (receive_angles_for_incidence2 < min_angle2) | (receive_angles_for_incidence2 > max_angle2)
    rt_filtered2 = rt_shifted_for_incidence2[filter_mask2]
    receive_angles_filtered2 = receive_angles_for_incidence2[filter_mask2]

    # Filter cosine angles
    cosine_angles_filtered2 = cosine_angles2[incidence_mask2][filter_mask2]

    # Compute BRDF
    brdf_filtered2 = rt_filtered2 / (np.pi * cosine_angles_filtered2)

    # Append filtered data
    brdf_filtered_list2.append(brdf_filtered2)
    receive_angles_filtered_list2.append(receive_angles_filtered2)

# Loop through each unique incidence angle for sample_data3
for incidence in unique_incidences3:
    # Filter RT data corresponding to the current incidence angle
    incidence_mask3 = (data_cdf3.iloc[7] == incidence)
    rt_for_incidence3 = rt3[incidence_mask3]

    # Get the corresponding receive angles
    receive_angles_for_incidence3 = receive_row3[incidence_mask3]

    # Shift RT values so that the minimum value becomes 0
    rt_shifted_for_incidence3 = rt_for_incidence3 - rt_for_incidence3.min()

    # Remove data in the range n-5 to n+5
    min_angle3 = -incidence - 5
    max_angle3 = -incidence + 5

    # Apply filter to remove the specified range
    filter_mask3 = (receive_angles_for_incidence3 < min_angle3) | (receive_angles_for_incidence3 > max_angle3)
    rt_filtered3 = rt_shifted_for_incidence3[filter_mask3]
    receive_angles_filtered3 = receive_angles_for_incidence3[filter_mask3]

    # Filter cosine angles
    cosine_angles_filtered3 = cosine_angles3[incidence_mask3][filter_mask3]

    # Compute BRDF
    brdf_filtered3 = rt_filtered3 / (np.pi * cosine_angles_filtered3)

    # Append filtered data
    brdf_filtered_list3.append(brdf_filtered3)
    receive_angles_filtered_list3.append(receive_angles_filtered3)

# endregion

# region Section 4: Log-Based Spline Fit for sample_data2 and sample_data3

# Initialize the list for spline fits for sample_data2 and sample_data3
brdf_spline_fit_values2 = {}
brdf_spline_fit_values3 = {}

import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import UnivariateSpline

# Assuming unique_incidences2, brdf_filtered_list2, receive_angles_filtered_list2, etc. are already defined

# Define smoothing factor (adjust as needed)
smoothing_factor = 0.1  # You can change this value depending on the smoothness you want

# Initialize lists to store spline fits
brdf_spline_fit_values2 = {}
brdf_spline_fit_values3 = {}

# Iterate through the filtered data for each unique incidence angle in sample_data2
for i, incidence in enumerate(unique_incidences2):
    if i >= len(brdf_filtered_list2) or i >= len(receive_angles_filtered_list2):
        continue  # Skip if indices are out of bounds

    brdf_filtered2 = np.array(brdf_filtered_list2[i], dtype=float)
    receive_angles_filtered2 = np.array(receive_angles_filtered_list2[i], dtype=float)

    # Remove NaN and negative BRDF values
    valid_mask = (~np.isnan(brdf_filtered2)) & (brdf_filtered2 > 0) & (~np.isnan(receive_angles_filtered2))
    receive_angles_filtered2 = receive_angles_filtered2[valid_mask]
    brdf_filtered2 = brdf_filtered2[valid_mask]

    if len(receive_angles_filtered2) == 0 or len(brdf_filtered2) == 0:
        print(f"Skipping incidence {incidence}: No valid data.")
        continue

    # Apply log transformation
    log_brdf2 = np.log10(brdf_filtered2)

    # Fit spline to log-transformed data
    spline_log2 = UnivariateSpline(receive_angles_filtered2, log_brdf2, s=smoothing_factor)

    # Define full receive angles within valid range
    full_receive_angles2 = np.linspace(receive_angles_filtered2.min(), receive_angles_filtered2.max(), 161)

    # Convert back from log scale
    fitted_spline_log2 = 10**spline_log2(full_receive_angles2)

    # Store the spline fit values for this incidence angle in brdf_spline_fit_values2
    brdf_spline_fit_values2[incidence] = fitted_spline_log2.tolist()

    # Debugging: Verify that data is being stored correctly
    print(f"Stored spline fit for incidence {incidence} in sample_data2: {len(fitted_spline_log2)} points.")

# Iterate through the filtered data for each unique incidence angle in sample_data3
for i, incidence in enumerate(unique_incidences3):
    if i >= len(brdf_filtered_list3) or i >= len(receive_angles_filtered_list3):
        continue  # Skip if indices are out of bounds

    brdf_filtered3 = np.array(brdf_filtered_list3[i], dtype=float)
    receive_angles_filtered3 = np.array(receive_angles_filtered_list3[i], dtype=float)

    # Remove NaN and negative BRDF values
    valid_mask = (~np.isnan(brdf_filtered3)) & (brdf_filtered3 > 0) & (~np.isnan(receive_angles_filtered3))
    receive_angles_filtered3 = receive_angles_filtered3[valid_mask]
    brdf_filtered3 = brdf_filtered3[valid_mask]

    if len(receive_angles_filtered3) == 0 or len(brdf_filtered3) == 0:
        print(f"Skipping incidence {incidence}: No valid data.")
        continue

    # Apply log transformation
    log_brdf3 = np.log10(brdf_filtered3)

    # Fit spline to log-transformed data
    spline_log3 = UnivariateSpline(receive_angles_filtered3, log_brdf3, s=smoothing_factor)

    # Define full receive angles within valid range
    full_receive_angles3 = np.linspace(receive_angles_filtered3.min(), receive_angles_filtered3.max(), 161)

    # Convert back from log scale
    fitted_spline_log3 = 10**spline_log3(full_receive_angles3)

    # Store the spline fit values for this incidence angle in brdf_spline_fit_values3
    brdf_spline_fit_values3[incidence] = fitted_spline_log3.tolist()

    # Debugging: Verify that data is being stored correctly
    print(f"Stored spline fit for incidence {incidence} in sample_data3: {len(fitted_spline_log3)} points.")

# Assuming brdf_spline_fit_values, brdf_spline_fit_values2, and brdf_spline_fit_values3 are already defined

# Define an empty dictionary to store the average spline fit values
brdf_spline_fit_avg = {}
brdf_spline_fit_min = {}
brdf_spline_fit_max = {}

# Define the color map to use for plotting
colors_raw = plt.cm.viridis(np.linspace(0, 1, len(unique_incidences)))

# Iterate through each incidence angle
for i, incidence in enumerate(unique_incidences):
    # Get the spline fits for the current incidence from all three datasets
    if incidence in brdf_spline_fit_values:
        spline_fit1 = np.array(brdf_spline_fit_values[incidence])
    else:
        spline_fit1 = None

    if incidence in brdf_spline_fit_values2:
        spline_fit2 = np.array(brdf_spline_fit_values2[incidence])
    else:
        spline_fit2 = None

    if incidence in brdf_spline_fit_values3:
        spline_fit3 = np.array(brdf_spline_fit_values3[incidence])
    else:
        spline_fit3 = None

    # We only want to average the values if there is data available from all three
    valid_splines = []
    if spline_fit1 is not None:
        valid_splines.append(spline_fit1)
    if spline_fit2 is not None:
        valid_splines.append(spline_fit2)
    if spline_fit3 is not None:
        valid_splines.append(spline_fit3)

    if valid_splines:
        # Calculate the average spline fit across all available splines
        brdf_spline_fit_avg[incidence] = np.mean(valid_splines, axis=0)
        # Calculate the min and max values for the error bars
        brdf_spline_fit_min[incidence] = np.min(valid_splines, axis=0)
        brdf_spline_fit_max[incidence] = np.max(valid_splines, axis=0)
    else:
        print(f"No valid spline fits available for incidence {incidence}.")

# Now plot the average spline fits with error bars for every other receive angle
for i, incidence in enumerate(unique_incidences):
    if incidence in brdf_spline_fit_avg:
        avg_spline = brdf_spline_fit_avg[incidence]
        min_spline = brdf_spline_fit_min[incidence]
        max_spline = brdf_spline_fit_max[incidence]

        # Get every other receive angle and corresponding spline values
        reduced_receive_angles = full_receive_angles[::2]  # Take every other receive angle
        reduced_avg_spline = avg_spline[::2]  # Take the corresponding values for the average spline
        reduced_min_spline = min_spline[::2]  # Same for min
        reduced_max_spline = max_spline[::2]  # Same for max

        # Calculate the error bars (range from min to max)
        yerr = [reduced_avg_spline - reduced_min_spline, reduced_max_spline - reduced_avg_spline]

        # Plot the average spline fit with error bars without markers and with horizontal lines
        plt.errorbar(
            reduced_receive_angles,  # Every other receive angle
            reduced_avg_spline,  # The average of the spline fits
            yerr=yerr,  # The error bars representing the range
            fmt='-',  # Line style only, no markers in the middle
            label=f'Average Spline Fit {incidence}°',
            color=colors_raw[i],  # Color for each incidence angle
            linewidth=2,
            capsize=3,  # Add horizontal lines on the error bars (top and bottom)
            elinewidth=1  # Line width of the error bars
        )

# Set log scale for Y-axis
plt.yscale('log')

# Set title dynamically based on material name
plt.title(f"Average BRDF Fits with Range for {material_name}", fontsize=22)

# Labels and formatting
plt.xlabel("Receive Angle (degrees)", fontsize=18)
plt.ylabel("BRDF", fontsize=18)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.legend(fontsize=16)   # Adjust legend size for clarity
plt.grid(True, which="both", linestyle="--")
plt.tight_layout()

# Show the plot
plt.show()

# Now plot the individual spline fits and the average spline fit without error bars
for i, incidence in enumerate(unique_incidences):
    if incidence in brdf_spline_fit_values and incidence in brdf_spline_fit_avg:
        # Get the individual spline fits and the average spline fit
        individual_spline_1 = brdf_spline_fit_values[incidence]  # First dataset
        individual_spline_2 = brdf_spline_fit_values2[incidence]  # Second dataset
        individual_spline_3 = brdf_spline_fit_values3[incidence]  # Third dataset
        avg_spline = brdf_spline_fit_avg[incidence]  # Average spline fit

        # Get the corresponding reduced receive angles (every other)
        reduced_receive_angles = full_receive_angles[::2]  # Every other receive angle
        reduced_individual_spline_1 = individual_spline_1[::2]  # First dataset spline
        reduced_individual_spline_2 = individual_spline_2[::2]  # Second dataset spline
        reduced_individual_spline_3 = individual_spline_3[::2]  # Third dataset spline
        reduced_avg_spline = avg_spline[::2]  # Average spline fit

        # Plot the individual spline fit for the first dataset
        plt.plot(
            reduced_receive_angles,  # Every other receive angle
            reduced_individual_spline_1,  # First dataset spline fit
            '-',  # Line style only, no markers
            label=f'Individual Fit 1 {incidence}°',
            color=colors_raw[i],  # Color for each incidence angle
            linewidth=2.5
        )

        # Plot the individual spline fit for the second dataset
        plt.plot(
            reduced_receive_angles,  # Every other receive angle
            reduced_individual_spline_2,  # Second dataset spline fit
            '--',  # Dotted line style for the second dataset
            label=f'Individual Fit 2 {incidence}°',
            color=colors_raw[i],  # Color for each incidence angle
            linewidth=2.5
        )

        # Plot the individual spline fit for the third dataset
        plt.plot(
            reduced_receive_angles,  # Every other receive angle
            reduced_individual_spline_3,  # Third dataset spline fit
            ':',  # Dotted line style for the third dataset
            label=f'Individual Fit 3 {incidence}°',
            color=colors_raw[i],  # Color for each incidence angle
            linewidth=2.5
        )

        # Plot the average spline fit
        plt.plot(
            reduced_receive_angles,  # Every other receive angle
            reduced_avg_spline,  # Average spline fit
            '-',  # Solid line style for the average
            label=f'Average Fit {incidence}°',
            color=colors_raw[i],  # Color for each incidence angle
            linewidth=3  # Thicker line for the average fit
        )

# Set log scale for Y-axis
plt.yscale('log')

# Set title dynamically based on material name
plt.title(f"BRDF Fits and Average for {material_name}")

# Labels and formatting
plt.xlabel("Receive/Emergence Angle (degrees)", fontsize=22)
plt.xlabel("Receive Angle (degrees)", fontsize=18)
plt.ylabel("BRDF", fontsize=18)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.legend(fontsize=16)  # Adjust legend size for clarity
plt.grid(True, which="both", linestyle="--")
plt.tight_layout()

# Show the plot
plt.show()
