%{
This function computes the azimuthal angle (0 - 360 degrees) of a ray,
assuming that the panel is the xy plane and zero azimuth occurs at the
positive x axis.

    Input:
        ray (3D column vector representing source or view ray)
    Output:
        angle (scalar, angle in degrees)
            or
        NaN (if source ray is normal to panel)

Josie Maxwell, 12 May 2020, RSG
%}
function angle = azimuthal(ray)
% Assuming frame of ref fixed as panel, to get ray projected on panel
% plane, just take x and y components of vector:
ray_x = ray(1);
ray_y = ray(2);
ray2D = [ray_x; ray_y];
x_axis = [1,0];

% Use dot product to find the angle between the 2D source ray and the
% positive x axis:
abs_angle = acosd(dot(x_axis,ray2D)/(norm(x_axis)*norm(ray2D)));

% We want the output angle to range from 0 to 360, but using dot product
% will only give values between 0 and 180. An if statement is required:
if ray_y < 0
    angle = 360 - abs_angle;
else
    angle = abs_angle;
end
