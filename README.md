# pH Image Analysis
This code was part of a hydroponics system project I had in an engineering class. My role was the sensor system. My main task was reading/reporting the value of a dipped pH strip. I did this by comparing the RGB values of the pH strip to a color key with all of the color values. This was necessary because differences in lighting can significantly alter the RGB values of different pH's, making reading less accurate. I also wrote code to detect the light level and solution temperature.

![Image of Working Design](https://user-images.githubusercontent.com/96708796/185209064-d6cb1fe0-9c32-4ec2-a373-f7890ea2ecba.jpg)

## Table of contents
* [Features](#features)
* [What I Learned](#what-i-learned)
* [Technologies](#technologies)
* [Special Thanks](#special-thanks)

## Features
* Lower and raise servo motor to dip pH strip
* Take picture of pH strip and color key
* Filter out white background to focus on pH strip and color key
* Grab pixel samples from the pH strip and color key and store in array
* Use Euclidian distance formula to find the closest RGB match between pH strip and color key in given lighting conditions
* Output the result pH level, 0 to 14
* Detect light levels and solution temperature

### Future Features
* Add in code to filter extraneous objects
* Make image analysis more adaptable to different lighting conditions

## What I Learned
* MATLAB syntax
* Integrating my software to hardware (Arduino) for the first time
* Voltage division and splitting power between multiple circuits
	
## Technologies
Project is created with:
* MATLAB
* Arduino
* Fisher Brand pH Strips
	
## Special Thanks
* Thank you to my EGR 215 professor, team, and class for all their help on this project, I couldn't do it without you!
