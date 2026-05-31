# MASTER BRDF CODE: Import RT data from BRDF machine, convert to BRDF, subtract detector noise, and fit ABg coefficients
# Written by Max Duque 11/25/2024
# Modified by Jacob P. Krell 2025/11/11.

# region Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from scipy.integrate import simpson
from scipy.interpolate import UnivariateSpline
import copy
# endregion

# region Section 0: Data collection and conversion

# Section 0: Import RT measurement and blank measurement
sample_data1 = "ANOPLATE_AnoBlack_EC1_Alum6061_v1o0_20251115.xls"  # "NiTE_on_invar_v1o0A_20250915.xls"
# sample_data2 = "NiTE_on_invar_v1o0B_20250916.xls"
# sample_data3 = "NiTE_on_invar_v1o0C_20250916.xls"
blank_data = "blank_v2o0_20250911.xls"

# Load all sheets into a dictionary of DataFrames
data_sheets1 = pd.read_excel(sample_data1, sheet_name=None)
# data_sheets2 = pd.read_excel(sample_data2, sheet_name=None)
# data_sheets3 = pd.read_excel(sample_data3, sheet_name=None)
blank_sheets = pd.read_excel(blank_data, sheet_name=None)

# # [IF MORE THAN ONE EXCEL MEASUREMENT FILE] Average measurements:
# def average_pd_frames(df1, df2, df3):
#     df = copy.deepcopy(df1)
#     sheet_names = list(df.keys())[0:-1]  # exclude last sheet because blank
#     for sheet_name in sheet_names:  # df1.keys() == df2.keys() == df3.keys()
#         df[sheet_name].values[21][1::] = (df1[sheet_name].values[21][1::] + df2[sheet_name].values[21][1::] + df3[sheet_name].values[21][1::]) / 3  # average
#     return df
# data_sheets = average_pd_frames(data_sheets1, data_sheets2, data_sheets3)

# [ELSE, IF ONLY ONE EXCEL MEASUREMENT FILE] Redefine variable:
data_sheets = data_sheets1

# Keep only measurements at R-300S azimuth of -90 deg:
def filter_measurements(df_data, df_blank):
    df_data_new = copy.deepcopy(df_data['Sheet1'])
    df_blank_new = copy.deepcopy(df_blank['Sheet1'])
    sheet_names = list(df_data.keys())[0:-1]  # exclude last sheet because blank
    k0 = 1
    for sheet_name in sheet_names:
        mask = df_data[sheet_name].values[6][1::] == -90
        k1 = k0 + sum(mask)
        for j in [6, 7, 8, 21]:
            vals_data = df_data[sheet_name].values[j][1::]
            df_data_new.values[j][k0:k1] = vals_data[mask]
            vals_blank = df_blank[sheet_name].values[j][1::]
            df_blank_new.values[j][k0:k1] = vals_blank[mask]
        k0 = k1
    for j in [6, 7, 8, 21]:
        df_data_new.values[j][k1::] = np.nan
        df_blank_new.values[j][k1::] = np.nan
    return [df_data_new, df_blank_new]
[data_sheets, blank_sheets] = filter_measurements(data_sheets, blank_sheets)

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

brdf_denom_uncorrected = np.pi * cosine_angles
brdf_uncorrected = data_rt / brdf_denom_uncorrected #USE OTHER CODE FOR THESE
brdf_blank = blank_rt / np.pi
# endregion

# region Section 2: Plot subtracted data
fig, axs = plt.subplots(2, 2, figsize=(12, 10), sharex=True, sharey = False)
axs = axs.flatten()
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through unique incidence angles
for i, incidence in enumerate(unique_incidences):
    # Filter columns corresponding to the current incidence angle
    # print(incidence)
    incidence_mask = (data_cdf.iloc[7] == incidence)
    
    # Get the receive/emergence angles and corresponding BRDF values
    receive_angles_i = data_cdf.loc[8, incidence_mask].astype(float)  # Receive angles for current incidence
    # Use the filter mask to ensure alignment
    valid_mask = incidence_mask & ~np.isnan(brdf)  # Mask to filter out NaN values from BRDF
    brdf_i = brdf[valid_mask]  # BRDF values filtered by valid_mask
    # brdf_i = brdf_uncorrected[incidence_mask] # uncorrected check
    # brdf_i = brdf_blank[incidence_mask] # blank check
    
    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_i) == 0 or len(brdf_i) == 0:
        continue

    # # Individually Plot BRDF vs. Receive Angles
    # plt.plot(receive_angles_i, brdf_i, 'o', label=f'Incidence {incidence}°',color=colors_raw[i])
    # # Customize the plot
    # plt.xlabel('Receive/Emergence Angle (degrees)')
    # plt.ylabel('BRDF')
    # plt.title('Anoblack EC1 Raw BRDF vs. Emergence Angle for Each Incidence Angle')
    # plt.legend(title="Incidence Angles")
    # plt.grid(True)
    # # Show the plot
    # plt.show()

    # Subplot data
    axs[i].plot(receive_angles_i, brdf_i, 'o', label=f'Incidence {incidence}°', color=colors_raw[i])
    axs[i].set_title(f'Incidence Angle {incidence}°')
    axs[i].grid(True)
    axs[i].legend()

    # Set individual axis limits for both x and y after plotting
    x_min, x_max = min(receive_angles_i), max(receive_angles_i)

    # Calculate y_min and y_max for this specific subplot, based on brdf_i values
    y_min, y_max = min(brdf_i), max(brdf_i)

    # Add padding to the limits for better visualization
    x_pad = (x_max - x_min) * 0.1
    y_pad = (y_max - y_min) * 0.1

    # Manually set the x and y limits for this specific subplot
    axs[i].set_xlim(x_min - x_pad, x_max + x_pad)
    axs[i].set_ylim(y_min - y_pad, y_max + y_pad)   
    # Add individual axis labels
    axs[i].set_xlabel('Receive/Emergence Angle (degrees)')
    axs[i].set_ylabel('BRDF')

# Adjust layout for better spacing

plt.tight_layout()
# plt.show()
# endregion

# region Section 3: Filter brdf and plot data
# Initialize lists to store results for each incidence angle
brdf_filtered_list = []
receive_angles_filtered_list = []

# Loop through each unique incidence angle and shift the rt values for each
for incidence in unique_incidences:
    # Filter rt data corresponding to the current incidence angle
    incidence_mask = (data_cdf.iloc[7] == incidence)  # Apply mask for current incidence
    rt_for_incidence = rt[incidence_mask]  # Extract the rt data for this incidence angle

    # Get the corresponding receive angles for this incidence angle
    receive_angles_for_incidence = receive_row[incidence_mask]  # Get receive angles for the filtered data
    
    # Shift rt for this incidence so that the minimum value becomes 0
    rt_shifted_for_incidence = rt_for_incidence - rt_for_incidence.min()

    # Remove data in the range n-5 to n+5
    min_angle = -incidence - 5
    max_angle = -incidence + 5
    
    # Filter both rt and receive angles together to maintain alignment
    filter_mask = (receive_angles_for_incidence < min_angle) | (receive_angles_for_incidence > max_angle)
    rt_filtered = rt_shifted_for_incidence[filter_mask]  # Filter rt based on the filter_mask
    receive_angles_filtered = receive_angles_for_incidence[filter_mask]  # Filter receive angles

    # Filter cosine_angles in the same way
    cosine_angles_filtered = cosine_angles[incidence_mask][filter_mask]

    # rt_shifted_for_incidence = rt_filtered - rt_filtered.min()
    brdf_filtered = rt_filtered / np.pi / cosine_angles_filtered

    # Append filtered data to the lists
    brdf_filtered_list.append(brdf_filtered)
    receive_angles_filtered_list.append(receive_angles_filtered)
# print(brdf)

# Subplot each incident angle's filtered BRDF data
fig, axs = plt.subplots(2, 2, figsize=(12, 10), sharex=True, sharey=False)
axs = axs.flatten()

# Define color map for the plots
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Iterate through the filtered data for each unique incidence angle
for i, (brdf_filtered, receive_angles_filtered) in enumerate(zip(brdf_filtered_list, receive_angles_filtered_list)):
    if i >= len(axs):  # Skip if there are more incidences than subplots
        break

    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_filtered) == 0 or len(brdf_filtered) == 0:
        continue

    # Subplot data
    axs[i].plot(
        receive_angles_filtered, 
        brdf_filtered, 
        'o', 
        label=f'Incidence {unique_incidences[i]}°', 
        color=colors_raw[i]
    )
    axs[i].set_title(f'Incidence Angle {unique_incidences[i]}°')
    axs[i].grid(True)
    axs[i].legend()

    # Set individual axis limits for both x and y after plotting
    x_min, x_max = min(receive_angles_filtered), max(receive_angles_filtered)
    y_min, y_max = min(brdf_filtered), max(brdf_filtered)

    # Add padding to the limits for better visualization
    x_pad = (x_max - x_min) * 0.1
    y_pad = (y_max - y_min) * 0.1

    # Manually set the x and y limits for this specific subplot
    axs[i].set_xlim(x_min - x_pad, x_max + x_pad)
    axs[i].set_ylim(y_min - y_pad, y_max + y_pad)

    # Add individual axis labels
    axs[i].set_xlabel('Receive/Emergence Angle (degrees)')
    axs[i].set_ylabel('BRDF')

# Adjust layout for better spacing
plt.tight_layout()
# plt.show()

#endregion

# region Section 4: Polyfit and spline fit the data
# Initialize a dictionary to store BRDF values for each incidence angle
brdf_arrays = {}
brdf_spline_fit_values = {}
brdf_polyfit_values = {}

# Subplot version with both spline and polynomial fit
fig, axs = plt.subplots(2, 2, figsize=(12, 10), sharex=True, sharey=False)
axs = axs.flatten()

# Define color map for the plots
cmap = cm.get_cmap('viridis', len(unique_incidences))
colors_raw = [cmap(i) for i in range(len(unique_incidences))]

# Degree of the polynomial for polyfit
degree = 10
# Spline smoothing factor
smoothing_factor = .0001

# Define the full range of receive angles from -80 to 80
full_receive_angles = np.linspace(-80, 80, 161)

# Iterate through the filtered data for each unique incidence angle
for i, (brdf_filtered, receive_angles_filtered) in enumerate(zip(brdf_filtered_list, receive_angles_filtered_list)):
    if i >= len(axs):  # Skip if there are more incidences than subplots
        break

    # Skip if no valid data exists for this incidence angle
    if len(receive_angles_filtered) == 0 or len(brdf_filtered) == 0:
        continue

    # Convert to numeric types and remove invalid values
    try:
        receive_angles_filtered = np.array(receive_angles_filtered, dtype=float)
        brdf_filtered = np.array(brdf_filtered, dtype=float)
    except ValueError:
        print(f"Skipping incidence {unique_incidences[i]} due to non-numeric data.")
        continue

    # Check for NaN values and filter them out
    valid_mask = ~np.isnan(receive_angles_filtered) & ~np.isnan(brdf_filtered)
    receive_angles_filtered = receive_angles_filtered[valid_mask]
    brdf_filtered = brdf_filtered[valid_mask]

    if len(receive_angles_filtered) == 0 or len(brdf_filtered) == 0:
        print(f"No valid numeric data for incidence {unique_incidences[i]}. Skipping.")
        continue

    # Perform polynomial fit
    coefficients = np.polyfit(receive_angles_filtered, brdf_filtered, degree)
    polynomial = np.poly1d(coefficients)
    fitted_poly_values = polynomial(full_receive_angles)
    brdf_polyfit_values[unique_incidences[i]] = fitted_poly_values.tolist()

    # Perform spline fit
    spline = UnivariateSpline(receive_angles_filtered, brdf_filtered, s=smoothing_factor)
    fitted_spline_values = spline(full_receive_angles)
    brdf_spline_fit_values[unique_incidences[i]] = fitted_spline_values.tolist()

    # Generate data for the fitted curves
    x_fit = np.linspace(receive_angles_filtered.min(), receive_angles_filtered.max(), 500)
    y_poly_fit = polynomial(x_fit)
    y_spline_fit = spline(x_fit)

    # Plot raw data
    axs[i].plot(
        receive_angles_filtered,
        brdf_filtered,
        'o',
        label=f'Raw Data (Incidence {unique_incidences[i]}°)',
        color=colors_raw[i],
        alpha=0.6
    )
    # Plot polynomial fit
    axs[i].plot(
        x_fit,
        y_poly_fit,
        '--',
        label=f'Polyfit (degree {degree})',
        color='blue'
    )
    # Plot spline fit
    axs[i].plot(
        x_fit,
        y_spline_fit,
        '-',
        label=f'Spline Fit (smoothing factor={smoothing_factor})',
        color='red'
    )

    # Customize subplot
    axs[i].set_title(f'Incidence Angle {unique_incidences[i]}°')
    axs[i].grid(True)
    axs[i].legend()

    # Set individual axis labels
    axs[i].set_xlabel('Receive/Emergence Angle (degrees)')
    axs[i].set_ylabel('BRDF')

# Adjust layout for better spacing
plt.tight_layout()
# plt.show()

# Save BRDF values for each receive angle to a JSON file
output_file_poly = "brdf_polyfit_values.json"
output_file_spline = "brdf_spline_fit_values.json"
import json
with open(output_file_poly, "w") as f:
    json.dump(brdf_polyfit_values, f, indent=4)

with open(output_file_spline, "w") as f:
    json.dump(brdf_spline_fit_values, f, indent=4)

print(f"BRDF values for polynomial fit saved to {output_file_poly}.")
print(f"BRDF values for spline fit saved to {output_file_spline}.")
# Print the arrays for each incidence angle
for key, values in brdf_arrays.items():
    print(f"{key} = {values}")

#endregion


# region Section 5: Calculate TIS Using Both Polyfit and Spline Data

# Initialize dictionaries to store TIS values for polyfit and spline
tis_values_polyfit = {}
tis_values_spline = {}

# Loop through each unique incidence angle
for i, incidence in enumerate(unique_incidences):
    # Use the pre-filtered receive angles and BRDF values
    receive_angles = np.array(receive_angles_filtered_list[i], dtype=float)
    brdf_values = np.array(brdf_filtered_list[i], dtype=float)

    # Skip if no valid data exists
    if len(receive_angles) == 0 or len(brdf_values) == 0:
        print(f"No valid data for incidence angle {incidence}. Skipping TIS calculation.")
        continue

    # Convert angles to radians
    receive_angles_radians = np.radians(receive_angles)

    # Generate polynomial fit values
    polynomial = np.poly1d(np.polyfit(receive_angles, brdf_values, degree))
    fitted_poly_values = polynomial(receive_angles)

    # Generate spline fit values
    spline = UnivariateSpline(receive_angles, brdf_values, s=smoothing_factor)
    fitted_spline_values = spline(receive_angles)

    # Calculate the integrand for polyfit
    integrand_poly = fitted_poly_values * np.abs(np.sin(receive_angles_radians)) * np.cos(receive_angles_radians)
    tis_poly = 2 * np.pi * simpson(integrand_poly, x=receive_angles_radians)
    tis_values_polyfit[incidence] = tis_poly

    # Calculate the integrand for spline
    integrand_spline = fitted_spline_values * np.abs(np.sin(receive_angles_radians)) * np.cos(receive_angles_radians)
    tis_spline = 2 * np.pi * simpson(integrand_spline, x=receive_angles_radians)
    tis_values_spline[incidence] = tis_spline

    # print(f"TIS for incidence angle {incidence} (Polyfit): {tis_poly}")
    # print(f"TIS for incidence angle {incidence} (Spline): {tis_spline}")


# Save TIS values for both polyfit and spline to JSON files
tis_output_file_poly = "tis_values_polyfit.json"
tis_output_file_spline = "tis_values_spline.json"

with open(tis_output_file_poly, "w") as f:
    json.dump(tis_values_polyfit, f, indent=4)

with open(tis_output_file_spline, "w") as f:
    json.dump(tis_values_spline, f, indent=4)

print(f"TIS values for polyfit saved to {tis_output_file_poly}.")
print(f"TIS values for spline saved to {tis_output_file_spline}.")

# Plot TIS values for polyfit and spline
fig, ax = plt.subplots(figsize=(10, 6))

# Extract incidence angles and corresponding TIS values
incidence_angles = list(tis_values_polyfit.keys())
tis_polyfit_values = list(tis_values_polyfit.values())
tis_spline_values = list(tis_values_spline.values())

# Plot the TIS values
ax.plot(incidence_angles, tis_polyfit_values, 'o--', label='Polyfit TIS', color='blue')
ax.plot(incidence_angles, tis_spline_values, 's-', label='Spline TIS', color='red')

# Customize the plot
ax.set_title('TIS vs Incidence Angle')
ax.set_xlabel('Incidence Angle (degrees)')
ax.set_ylabel('TIS')
ax.legend()
ax.grid(True)

# Show the plot
plt.tight_layout()
plt.show()

#endregion

# region Section 6: Produce BRDF file - Coordinate system may be incorrect

with open('testbsdf.bsdf', 'w') as f:
    # Write the header information
    f.write("# Data Generated by Radiant Imaging's 'Imaging Sphere'\n")
    f.write("# 9/19/2024\n")
    f.write("# Name: Max\n")
    f.write("# Model #: BRDF of Anoblack\n")
    f.write("Source  Measured\n")
    f.write("Symmetry  PlaneSymmetrical\n")
    f.write("SpectralContent  Monochrome\n")
    f.write("ScatterType  BRDF\n")
    f.write("SampleRotation  1\n")
    f.write("0\n")

    f.write(f"AngleOfIncidence  {number_of_incidences}\n")  # Use f-string here
    f.write("\t".join([str(value) for value in unique_incidences]) + "\n")  # Tab-separated values in one row
    f.write("ScatterAzimuth 2\n")
    f.write("0  180")  # Add an extra newline for spacing
    f.write(f"\nScatterRadial {number_of_receives}\n")  # Use f-string here
    f.write("\t".join([str(value) for value in positive_receives]) + "\n\n")  # Tab-separated values in one row

    f.write("Monochrome\n")
    f.write("DataBegin\n")

    # Write TIS and BRDF values for each incidence angle
    for incidence in unique_incidences:
        tis_poly = tis_values_polyfit.get(incidence, 'N/A')
        tis_spline = tis_values_spline.get(incidence, 'N/A')

        # Retrieve BRDF values for polynomial and spline fits
        brdf_poly_values = brdf_polyfit_values.get(incidence, [])
        brdf_spline_values = brdf_spline_fit_values.get(incidence, [])

        # Split BRDF values into two halves
        mid_index = len(brdf_poly_values) // 2

        poly_first_half_reversed = brdf_poly_values[:mid_index + 1][::-1]  # Reverse the first half
        # need to add first value of second half to beginning of reversed first half
        poly_second_half = brdf_poly_values[mid_index:]  # Second half including the middle value

        spline_first_half_reversed = brdf_spline_values[:mid_index + 1][::-1]  # Reverse the first half
        spline_second_half = brdf_spline_values[mid_index:]  # Second half including the middle value

        # Write TIS values
        f.write(f"TIS {tis_poly}\n")
        f.write(f"\t".join(map(str, poly_first_half_reversed)) + "\n")
        f.write(f"\t".join(map(str, poly_second_half)) + "\n")

        # f.write(f"TIS {tis_spline}\n")
        # f.write(f"\t".join(map(str, spline_first_half_reversed)) + "\n")
        # f.write(f"\t".join(map(str, spline_second_half)) + "\n")

    f.write("DataEnd\n")

#endregion