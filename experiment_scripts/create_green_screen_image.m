%%%%% generate monocolor image file to be used as visual stimulus

% params
% image_height_width_pix = [1050 1680];
    image_height_width_pix = [1050 1050];
image_color = [0 1 0];
file_savepath = 'C:\docs\code\ieeg_stut\stimuli\figures\green_screen_beep.png';

% create and save image
rgb_pix(1,1,1) = image_color(1);
rgb_pix(1,1,2) = image_color(2);
rgb_pix(1,1,3) = image_color(3);;
full_img = repmat(rgb_pix,image_height_width_pix(1),image_height_width_pix(2),1);
imwrite(full_img, file_savepath)