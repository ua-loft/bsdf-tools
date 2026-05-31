%{
This function calculates the zenith angle (angle between panel normal and
ray vector) using the dot product formula.

    Inputs:
        panel_normal (3D column vector)
        ray_normal (3D column vector)
    Output:
        angle (scalar - angle in degrees)

Note: swapping positions of input variables has no effect on output

Josie Maxwell, 12 May 2020, RSG
%}
function angle = zenith(panel_normal,ray)
angle = acosd(dot(panel_normal,ray)/(norm(panel_normal)*norm(ray)));