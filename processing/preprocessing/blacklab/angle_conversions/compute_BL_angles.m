function outputs = compute_BL_angles(inputs)
%{
This function computes stage angles for the black lab given source/view
zenith/azimuth angles as input.  This function replaces Nathan Leisso's
code 'nates_compute_BL_angles.m'.  This function does the opposite
calculation as 'stage2angles.m'.

    Input:
        inputs (4 element vector of source/view zenith/azimuth angles in
        degrees)
    Output:
        outputs (4 element row vector of stage configuration angles in
        degrees)

This function must be in the same folder as function file:
    rodrigues.m

Josie Maxwell, 12 May 2020, RSG

% =========================================================================

% JPK == Jacob P. Krell, 2026/06/08-2026/xx/xx, LOFT;

%}

% For debugging, paste zenith/azimuth angles here and comment out function
% header
% inputs = [20	150	45	252];

% phi means zenith and theta is azimuth
s_zen = inputs(1); s_azi = inputs(2); v_zen = inputs(3); v_azi = inputs(4);

% axes of panel; azimuth measured from +x axis, zenith from +z axis
X = [1, 0, 0];
Y = [0, 1, 0];
Z = [0, 0, 1];

% Compute Source and View vectors
S = [sind(s_zen)*cosd(s_azi), sind(s_zen)*sind(s_azi), cosd(s_zen)];
V = [sind(v_zen)*cosd(v_azi), sind(v_zen)*sind(v_azi), cosd(v_zen)];

% [JPK] Check if source and view are nearly collinear:
if norm(cross(S,V)) < 1e-12
    warning("S and V are collinear. Manually setting stage angles to 0, which is not true coordinate transformation but will be filtered out later regardless since radiometer shades source.");
    outputs = [0 0 0 0];
    return
end

% Compute Horizontal and Up vectors (describing west and up in black lab)
U = normr_internal(cross(S, V));
if U(3) < 0
    U = -U;
end
H = normr_internal(cross(U, S));

% Define rotation matrix to switch from panel to room coord system
R = [S; H; U];

% Transform panel vectors into room coordinate system
x = R*X'; y = R*Y'; z = R*Z';
s = R*S'; v = R*V';

% Calculate radiometer angle
rad_ang = acosd(dot(S, V)); % angle between source and view vectors
if v(2) < 0 % if radiometer is to the east of the stage
    rad_ang = -rad_ang;
end

% Compute tilt angle
tilt_ang = abs(asind(z(3))); % tilt is always positive bc panel only tilts back

% Compute yoke angle
z2 = normr_internal([z(1) z(2) 0]); % projection of panel normal onto horizontal plane
yoke_ang = acosd(dot(z2,s)); 
if z2(2) < 0 % if panel is facing east of the stage
    yoke_ang = -yoke_ang;
end

% Compute panel rotation angle
yy = rodrigues(Y',Z',yoke_ang); % find axis about which panel is tilted
pan_rot_ang = acosd(dot(x,yy)); % angle between panel 'x' and its home position
if x(3) > 0
    pan_rot_ang = - pan_rot_ang; % panel rotates clockwise
end

% [JPK] Snap values:
tol = 1e-5; % threshold of what is considered 'numerical error'
for snap_target = [-180, -90, 0, 90, 180]
    pan_rot_ang(abs(pan_rot_ang - snap_target) < tol) = snap_target;
end

outputs = [rad_ang yoke_ang tilt_ang pan_rot_ang];

function v_out = normr_internal(v)
    % [JPK] Added to handle 'normr' failing to return zero vector.
    if all(v == 0) % if zero vector
        v_out = v; % return zero vector, not [0.57, 0.57, 0.57]
    else
        v_out = v / norm(v); % normalize
    end
end

end