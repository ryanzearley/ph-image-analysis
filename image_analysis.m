    clc
    clear

    a = arduino();

% MOTOR CODE %

    s = servo(a, 'D6', 'MinPulseDuration', 533*10^-6, 'MaxPulseDuration', 2425*10^-6);

    writePosition(s, 0); % Send the smallest pulse to the servo to set it to the lowest position
    pause (1.5);
    writePosition(s, 1); % Send the highest pulse to set it to the highest position
    pause(1.5);

% PICTURE CODE %

    camList = webcamlist;
    
    % create video object (1 or 2)
    cam = webcam(2);
    
    % take a picture with the camera, 
    % place within control structure if timing is important
    img = snapshot(cam);
    
    % show the image
    % color correction might be necessary

% pH ANALYSIS CODE %

    % initialize image
    pHimage = img;
    imshow(img);
    
    % split image into RGB channels
    r_channel = pHimage(:,:,1);
    g_channel = pHimage(:,:,2);
    b_channel = pHimage(:,:,3);
    
    % define RGB ratios
    rg_ratio = double(r_channel) ./ double(g_channel);
    gb_ratio = double(g_channel) ./ double(b_channel);
    br_ratio = double(b_channel) ./ double(r_channel);
    
    % catch NaN ratios
    rg_ratio(isnan(rg_ratio)) = 0;
    gb_ratio(isnan(gb_ratio)) = 0;
    br_ratio(isnan(br_ratio)) = 0;
    
% MASK AND BOUNDING BOX CODE %

    % define region of interest based on RGB values of interest
    % in this case, replace anything with white/black-like RGB ratio with black,
    % keep anything lower than that ratio white and above the black ratio
    % modify this if the black/white mask doesn't look right
    roi = (rg_ratio <= 0.85 | gb_ratio <= 0.85 | br_ratio <= 0.85) & (rg_ratio >= 0.15 | gb_ratio >= 0.15 | br_ratio >= 0.15);
    
    % create black and white mask
    % the value 350 connects all pixel clumps bigger than 350
    % modify 350 if the mask is right but you get more boxes than you want
    bw = bwareaopen(roi, 350);
    
    % create bounding box around white objects in binary image
    bbTable = regionprops('table', bw, 'BoundingBox');
    % transfer tables values to array to make it more manageable
    bbArray = bbTable{:,:};
    
    % transfer each column of bbArray so similar values are grouped together
    % for example, in bb_x, the x values of all the rectangles are saved so
    % they can be looped and drawn
    bb_x = bbArray(:, 1);
    bb_y = bbArray(:, 2);
    bb_width = bbArray(:, 3);
    bb_height = bbArray(:, 4);
    
    % display image
    imshow(pHimage);
    % to show both at once, use: 
    % imshowpair(bw, pHimage, 'montage');
    
    % draw bounding boxes on image
    hold on
    for c = 1:size(bbArray, 1)
        rectangle('Position', [bb_x(c, 1), bb_y(c,1), bb_width(c,1), bb_height(c,1)],...
        'EdgeColor','r', 'LineWidth', 3)
    end
    hold off
    
% FILTERING EXTRA BOUNDING BOXES -- not ready %
   
    % remove all elements that aren't the right RATIO or AREA
    %%for c = 1:size(bbArray, 1)
        %if(bb_width(c, 1) / bb_height(c, 1) < 2 | bb_width(c, 1) / bb_height(c, 1) > 3)
         %   bbArray(c,:) = [];
        %end
    %end
    
    error = false;
    
    if size(bbArray, 1) ~= 16
        error = true;
    end
    
% pH COLOR ANALYSIS %

    % initialize closest color variables
    % set absurd values so it is clear if there is an error
    lowest_difference = 600;
    closest_pH = 15;
    
    try
        % sort boxes in bbArray to match order on pH card
        pH_card_box_array = [sortrows(bbArray(1:8,:),2); sortrows(bbArray(9:15,:),2)];
        
        % display sorted bbArray for debugging
        % disp(pH_card_box_array);
        
        % split pH card box values into related values
        pH_x = pH_card_box_array(:, 1);
        pH_y = pH_card_box_array(:, 2);
        pH_width = pH_card_box_array(:, 3);
        pH_height = pH_card_box_array(:, 4);
        
        % assign pH strip to last (right-most) in the list
        pH_strip_x = round(bb_x(16, 1) + (bb_width(16, 1) / 2)); 
        pH_strip_y = round(bb_y(16, 1) + (bb_height(16, 1) / 2));
        
        % assign RGB value to variables
        pH_strip_red = r_channel(pH_strip_y, pH_strip_x, :);
        pH_strip_green = g_channel(pH_strip_y, pH_strip_x, :);
        pH_strip_blue = b_channel(pH_strip_y, pH_strip_x, :);
        
        % initialize empty array for pH card RGB values as ordered on pH card
        pH_card_rgb_array = [7, 0, 0, 0; 6, 0, 0, 0; 5, 0, 0, 0; 4, 0, 0, 0; 3, 0, 0, 0; 2, 0, 0, 0; 1, 0, 0, 0; 0, 0, 0, 0; 14, 0, 0, 0; 13, 0, 0, 0; 12, 0, 0, 0; 11, 0, 0, 0; 10, 0, 0, 0; 9, 0, 0, 0; 8, 0, 0, 0];
        
        % assign RGB values to each pH
        for c = 1:size(pH_card_box_array, 1)
            pH_card_x = round(pH_x(c, 1) + (pH_width(c, 1) / 2));
            pH_card_y = round(pH_y(c, 1) + (pH_height(c, 1) / 2));
        
            pH_card_red = r_channel(pH_card_y, pH_card_x, :);
            pH_card_green = g_channel(pH_card_y, pH_card_x, :);
            pH_card_blue = b_channel(pH_card_y, pH_card_x, :);
        
            pH_card_rgb_array(c, 2) = pH_card_red;
            pH_card_rgb_array(c, 3) = pH_card_green;
            pH_card_rgb_array(c, 4) = pH_card_blue;
        
        end
    
    catch
        % assign the dipped pH strip to last (right-most) in the list
        pH_strip_x = round(bb_x(size(bb_x, 1), 1) + (bb_width(size(bb_width, 1), 1) / 2)); 
        pH_strip_y = round(bb_y(size(bb_y, 1), 1) + (bb_height(size(bb_height, 1), 1) / 2));

        % get RGB values of pH strip
        pH_strip_red = r_channel(pH_strip_y, pH_strip_x, :);
        pH_strip_green = g_channel(pH_strip_y, pH_strip_x, :);
        pH_strip_blue = b_channel(pH_strip_y, pH_strip_x, :);

        % initialize array for pH card RGB values as ordered on pH card
        % filled with pure HUE values as found on Fisher Scientific website
        % in case there is an error in reading the pixel values in natural
        % lighting conditions
        pH_card_rgb_array = [7, 105, 152, 89; 6, 188, 189, 78; 5, 208, 190, 69; 4, 224, 179, 89; 3, 223, 134, 69; 2, 211, 106, 62; 1, 213, 75, 90; 0, 193, 46, 97; 14, 3, 23, 72; 13, 16, 50, 87; 12, 44, 69, 90; 11, 35, 87, 84; 10, 42, 94, 85; 9, 66, 106, 81; 8, 91, 132, 79];

    end

    % for each RGB value, calculate the difference in color using the
    % Euclidian distance formula and check if it's the closest match
    for c = 1:size(pH_card_rgb_array, 1)
        difference_red = double(pH_strip_red) - double(pH_card_rgb_array(c, 2));
        difference_green = double(pH_strip_green) - double(pH_card_rgb_array(c, 3));
        difference_blue = double(pH_strip_blue) - double(pH_card_rgb_array(c, 4));
    
        dif_red_squared = double(difference_red) * double(difference_red);
        dif_green_squared = double(difference_green) * double(difference_green);
        dif_blue_squared = double(difference_blue) * double(difference_blue);
    
        dif_total = sqrt(double(dif_red_squared + dif_green_squared + dif_blue_squared));
        
        if dif_total < lowest_difference
            closest_pH = pH_card_rgb_array(c, 1);
            lowest_difference = dif_total;
        end
    end

    % display results
    disp('pH Card RGB Array:');
    disp(pH_card_rgb_array);
    disp('The closest pH is:');
    disp(num2str(closest_pH));
    if error
        disp('There was an error in calibration, rearrange camera')
    end
    
% TEMPERATURE CODE %

    % get value from the analog pin and store it
    volts_therm = readVoltage(a,'A0');

    % calculate temperature in Kelvin
    R2 = 10000;

    % reference temperature (25 C), in Kelvin
    temp0 = 298.15;

    % resistance at reference temperature, in Ohms
    res0 = 10000;

    % thermistor B parameter, in Kelvin
    B = 3950;

    % calculate the current using Ohm's law
    current = volts_therm / R2;

    % find the resistance of the thermistor
    Resistance = (5 - volts_therm) / current;

    % Calculate the reciprocal of the TempK
    recip_temp = 1 / temp0 + log(Resistance / res0) / B;

    % Calculate Temp in Kelvin
    TempK = 1./recip_temp;
           
    disp("Thermistor volts:");
    disp(num2str(volts_therm,3));

    % convert to Fahrenheit
    TempF = ((TempK - 273.15) * 1.8) + 32;
    disp("Fahrenheit:");
    disp(num2str(TempF,3));

% LIGHT LEVEL CODE %

    volts_photo = readVoltage(a, 'A1');

    % I use a 0-10 scale for simplicity rather than 0-5
    volts = volts_photo * 2;

    % initialize to "null" to make clear if there is error
    reading = "null";

    if (volts >= 8)
        reading = "bright";
    elseif (volts >= 6)
        reading = "normal";
    else
        reading = "low";
    end

    disp("Photoresistor volts:");
    disp(num2str(volts));
    disp(reading);
