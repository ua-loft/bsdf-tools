%{
This function takes a vector and rotates it about an axis by an angle in
degrees using Rodriques' rotation formula. Rotation follows the right hand 
rule.

    Inputs:
        vector (3D column vector)
        axis (3D column vector)
        angle (scalar - angle of rotation in degrees)
    Output:
        rotated_vector (3D column vector)

Josie Maxwell, 12 May 2020, RSG
%}
function rotated_vector = rodrigues(vector,axis,angle)
rotated_vector = vector.*cosd(angle)...
                + cross(axis,vector).*sind(angle)...
                + axis.*(dot(axis,vector)).*(1-cosd(angle));