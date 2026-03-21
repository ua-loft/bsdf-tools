
function [S, I, Az, Rz] = fred_frame_to_zemax(Pi, Ai, Ps, As)
    % Convert angles defined in FRED frame to Zemax frame.    
    % See 2026/03/18 LOFT notebook for derivation.

    % Check domain of I = Pi \in [0, 180]:
    if any(or(Pi < 0, Pi > 180))
        error("Expecting 'Pi' on [0, 180] domain. Enforce domain in FRED coordinates first prior to calling 'fred_frame_to_zemax'.")
    end

    % Define Zemax angles:
    S = -Ai; % 'SampleRotation'
    I = Pi; % 'AngleOfIncidence'

    % Force domain of S \in [0, 360):
    mS = S < 0;
    while any(mS)
        S(mS) = S(mS) + 360;
        mS = S < 0;
    end
    mS = S >= 360;
    while any(mS)
        S(mS) = S(mS) - 360;
        mS = S >= 360;
    end
    
    % Define unit vectors in Cartesian frame:
    spec = fred_to_cartesian(Pi, Ai); % specular ray
    scat = fred_to_cartesian(Ps, As); % scatter ray
    z = [0; 0; 1]; % z-axis
    z = repmat(z, 1, length(Pi)); % expand size to match number of angles

    % Calculate corresponding (Az,Rz) Zemax values:
    Rz = abs(acosd(dot(spec, scat))); % 'ScatterRadial'
    z_proj = z - dot(z, spec) .* spec; % project to plane perp. to specular
    Az_zero = z_proj ./ vecnorm(z_proj); % axis of Az = 0
    Az_perp = cross(spec, Az_zero); % axis of Az = +90
    Az = atan2d(dot(scat, Az_perp), dot(scat, Az_zero)); % 'ScatterAzimuth'

    % Shift (-180, 180] domain (output from atan2d) to [0, 360):
    m = Az < 0;
    Az(m) = Az(m) + 360; % shift (-180, 0) to (180, 360)

    % Make column vector:
    Az = Az';
    Rz = Rz';

end

function xyz = fred_to_cartesian(P, A)
    % Convert unit vector defined by FRED polar and azimuthal angles 
    % [deg] to FRED's Cartesian frame. 'P' and 'A' should be 1 X M.
    if size(P, 2) == 1
        P = P'; % try to handle M X 1 input
    end
    if size(A, 2) == 1
        A = A'; % try to handle M X 1 input
    end
    xyz = [abs(sind(P)) .* cosd(A); ...
           abs(sind(P)) .* sind(A); ...
           cosd(P)];
end

