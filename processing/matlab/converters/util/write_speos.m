
function status = write_speos(S, I, Az, Rz, BRDF, TIS, filepath, ISOTROPIC, OVERWRITE, header_info)
    % DO NOT USE THIS. IT IS UNFINISHED PSEUDOCODE. REFER TO EXTERNAL 
    % PYTHON FUNCTION 'write_speos_anisotropicbsdf_file' FROM CLASS 
    % 'BsdfStructure' OF MODULE 
    % 'ansys_optical_automation.interop_process.BSDF_converter'.
    % 
    % SEE THE FOLLOWING FOR EXAMPLE USE:
    %   - https://github.com/ansys/optical-automation/blob/main/ansys_optical_automation/application/BSDF_converter_example.py
    % 
    % =====================================================================
    % =====================================================================
    % 
    % =====================================================================
    % =====================================================================
    % 
    % =====================================================================
    % =====================================================================
    % 
    % 'filepath' is full filepath of output *.anisotropicbsdf file.
    % Only monochromatic light source is currently supported.
    % Set 'header_info = ""' to leave blank.
    % Function initialized 2026/05/21 using 'write_zemax' as template.

    status = false; % initialize

    % Check if file is available, and open/create if so:
    if exist(filepath, 'file') % if file already exists
        if OVERWRITE % if user specified to overwrite the file
            warning("BSDF file already exists. Overwriting the file.");
        else
            error("BSDF file already exists. Change 'filepath' or set 'OVERWRITE=true'.");
        end
    end
    fid = fopen(filepath, 'wt'); % if no error above, open file

    % For format, see:
        % - https://optics.ansys.com/hc/en-us/articles/18384793374227-Speos-BRDF-BTDF-and-BSDF-Formats

    % Write 'title' of file:
    fprintf(fid, "dummy title\n");

    % Write '0' for non-binary file, i.e., text file:
    fprintf(fid, "0\n");

    % Write comments in single line:
    fprintf(fid, "dummy single-line comments; second comment;\n");

    % Integer number of characters to read for the measurement description:
    measurement_description = "test\ntest2\ntest3"; % do not end with \n
    fprintf(fid, num2str(length(measurement_description)) + "\n");
        
        % will need to subtract length added by \n characters

    % Not needed, but skip line for readability:
    fprintf(fid, "\n");

    % Anisotropy vector in global coordinates:
    fprintf(fid, "1\t0\t0\n");

    % Boolean true if reflection data, boolean true if transmission data:
    fprintf(fid, "1\t0\n");

    % Boolean true if BSDF data or false if intensity data:
    fprintf(fid, "1\n");

    % Number of anisotropy angles in reflection:
    angles_refl = ;
    fprintf(fid, num2str(length(angles_refl)) + "\n");

    % List of anisotropy angles in reflection, as percent (0-100):
    fprintf(fid, "0\t25\t50\t75\t100\n");

        % values above from 'angles_refl' somehow, but divided by
        % max(angles_refl), and x100

    % Number of incident angles in reflection:
    angles_inc = ;
    fprintf(fid, num2str(length(angles_inc)) + "\n");

    % List of incident angles in reflection, as degrees:
    fprintf(fid, "0\t10\t30\t50\t70\n");

        % values above from 'angles_inc' somehow

    % Number of anisotropy angles in transmission:
    angles_trans = ;
    fprintf(fid, num2str(length(angles_trans)) + "\n");

    % List of anisotropy angles in transmission, as degrees:
    fprintf(fid, "0\t10\t30\t50\t70\n");

        % values above from 'angles_trans' somehow

    % Number of incident angles in transmission:
    angles_inc_trans = ;
    fprintf(fid, num2str(length(angles_inc_trans)) + "\n");

    % List of incident angles in transmission, as degrees:
    fprintf(fid, "0\t10\t30\t50\t70\n");

        % values above from 'angles_inc_trans' somehow

    % (\theta, \phi) for each spectrum measurement in reflection, as two
    % floats in degrees:
    fprintf(fid, "blah\n");

    % Reflective Spectrum description (wavelength [nm], coefficient (%)):
    fprintf(fid, "650\t100\n");

    % Number of wavelength measurements in reflection:
    fprintf(fid, "3\n");

    % Wavelength 1 [nm]:
    fprintf(fid, "500\n");

    % Wavelength 2 [nm]:
    fprintf(fid, "600\n");

    % Wavelength 3 [nm]:
    fprintf(fid, "700\n");

    % Wavelength N [nm]:
    % ...

    % (\theta, \phi) for each spectrum measurement in transmission, as two
    % floats in degrees:
    fprintf(fid, "blah\n");

    % Transmission Spectrum description (wavelength [nm], coefficient (%)):
    fprintf(fid, "650\t100\n");

    % Number of wavelength measurements in transmission:
    fprintf(fid, "3\n");

    % Wavelength 1 [nm]:
    fprintf(fid, "500\n");

    % Wavelength 2 [nm]:
    fprintf(fid, "600\n");

    % Wavelength 3 [nm]:
    fprintf(fid, "700\n");

    % Wavelength N [nm]:
    % ...

    % Number of angles measured for (\theta, \phi) in reflection for the 
    % anisotropy-and-incident angle of the anisotropy angle:
    fprintf(fid, "blah\n");

    % Table of BSDF according to (\theta, \phi) angles, in reflection, for 
    % anisotropy-and-incident angle of anisotropy angle:
    fprintf(fid, "blah\tblah\tblah\n");
    fprintf(fid, "blah\tblah\tblah\n");
    fprintf(fid, "blah\tblah\tblah\n");

    % Number of angles measured for (\theta, \phi) in reflection for the 
    % anisotropy-and-SECOND-incident angle of the anisotropy angle:
    fprintf(fid, "blah\n");

    % Table of BSDF according to (\theta, \phi) angles, in reflection, for 
    % anisotropy-and-SECOND-incident angle of anisotropy angle:
    fprintf(fid, "blah\tblah\tblah\n");
    fprintf(fid, "blah\tblah\tblah\n");
    fprintf(fid, "blah\tblah\tblah\n");

    % Number of angles measured for (\theta, \phi) in reflection for the 
    % anisotropy-and-THIRD- ...

    % Repeat pattern.

    % Close file:
    fclose(fid);

    status = true; % success

end


function throw_error_msg1()
    error("Unexpected multiple BRDF entries for same angle. Debug formatting of input arguments prior to function call.");
end

