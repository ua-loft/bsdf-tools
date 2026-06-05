function angles = stage2angles(stage)
%{
This function takes Black Lab stage settings X, Y, U, and V and
calculates the zenith and azimuth angles for the source and radiometer.
This function does the opposite calculation as 'josies_compute_BL_angles.m'

    Input:
        stage, a vector with components X (radiometer arm), Y (yoke), U 
        (tilt), and V (rotation) describing a Black Lab stage 
        configuration.  All angles in degrees.
    Output:
        angles, a row vector with components zens (source zenith), azis
        (source azimuth), zenv (view zenith), and aziv (view azimuth)
        describing the source/radiometer view angles with respect to the
        panel normal.  All angles in degrees.

This function must be in the same folder as function files:
    rodrigues.m
    zenith.m
    azimuthal.m

Josie Maxwell, 12 May 2020, RSG
%}

% Start with panel facing source and radiometer, and coord sys designed w 
% reference to panel, so z axis is panel normal
p0 = [0;0;1];
s0 = [0;0;1];
v0 = [0;0;1];

% axes:
x = [1;0;0];
y = [0;1;0];
z = [0;0;1];

% stage settings
radiometer = stage(1); %degrees
yoke = stage(2); % degrees
tilt = stage(3); % degrees
rotation = stage(4); % degrees

%%% RADIOMETER & YOKE %%%
% First consider yoke of the panel.  Note that a positive yoke angle yields
% a negative direction rotation of the source ray about the y axis.
s1 = rodrigues(s0,y,-1*yoke);
% The radiometer arm version of yoke is 'radiometer'.  However, moving the
% radiometer arm occurs with reference to the source ray, not the panel.
v0 = s1;
v1 = rodrigues(v0,y,radiometer);

%%% TILT %%%
% When the panel is tilted, the source and view rays appear to rotate
% about the x axis of the panel:
s2 = rodrigues(s1,x,tilt);
v2 = rodrigues(v1,x,tilt);

%%% ROTATION %%%
% Rotation will rotate the source ray about the z axis (panel normal).  
s3 = rodrigues(s2,z,rotation);
v3 = rodrigues(v2,z,rotation);

%%% ZENITHS %%%
zens3 = zenith(p0,s3);
zenv3 = zenith(p0,v3);

%%% AZIMUTHS %%%
azis3 = azimuthal(s3); if azis3 >= 360; azis3 = azis3 - 360; end
aziv3 = azimuthal(v3); if aziv3 >= 360; aziv3 = aziv3 - 360; end

%%% OUTPUT %%%
angles = [zens3 azis3 zenv3 aziv3];