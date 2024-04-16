vCoder

MATLAB function that allows frame-by-frame video coding. 

It reads .mp4 movies and saves the coding in 3 files: _framesLog.csv, _lookTotal.csv, and a .mat file. 

Toolboxes Required:
    Psychtoolbox (http://psychtoolbox.org/requirements)

To use the function, type 'vCoder' in the command window. Then enter the subject number. To jump to a specific frame in the movie, type vCoder(subjectID, frameNumber). 

The program looks for the indicated video in the 'movies' folder and saves the data in the 'data' folder. The movies have to have the format ExperimentName_subjectID.mp4. 


SPACEBAR:        play the movie forward at a normal playback rate  ||
RightArrow:      pause the movie and advance frame by frame  ||
LeftArrow:       pause the movie and rewind frame by frame  ||
F1 + RightArrow: participant is looking at the screen  ||
F3 + RightArrow: participant is looking to the LEFT (i.e. coder's left)  ||
F4 + RightArrow: participant is looking to the RIGHT (i.e. coder's right)  ||
N:               mark the start of a new trial  ||
R:               rewind to the frame where the trial started and redo the coding  ||
ESC:             pause; press SPACEBAR to continue; press Q to quit 

Demo: Type vCoder in the Command Window. Then enter subjectID: 699. 

Created by Natasa Ganea, Goldsmiths InfantLab, Jan 2019 (natasa.ganea@gmail.com)

Copyright © 2019 Natasa Ganea. All Rights Reserved.
========================

BIO:
My background is in Experimental Psychology - I've conducted many studies on infants' perception and learning. I've learned to code because I wanted to control precisely the timing of my stimuli and easily change the display on the screen when the little ones get bored. Many of my studies have involved recording whether babies are looking at the screen during the experiment (+ recording EEG data). Although I code babies' looking behaviour online, as the experiment is running, I sometimes need to code frame-by-frame where the baby is looking. I wrote this script to allow me frame-by-frame coding (I saved a lot of money by not buying Mangold Interact :)).
