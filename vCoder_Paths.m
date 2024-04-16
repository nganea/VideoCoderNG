%% vCoder_Paths
% 
%This script loads the keycode and the stimuli paths for the vCoder script. 
%It checkes whether it is a Mac or Windows platform and it defines the 
%paths accordingly. 
%
%  ========================
% Created by Natasa Ganea, Goldsmiths InfantLab, Jul 2019 (natasa.ganea@gmail.com)
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% ========================

%% keycodes

KbName('UnifyKeyNames');    % keyboard mapping same on all supported operating systems
ESC = KbName('escape');     % pause experiment
SPACE = KbName('space');    % continue experiment
QKEY = KbName('q');         % quit experiment 

F1 = KbName('f1');          % looking Centre
F3 = KbName('f3');          % looking Left
F4 = KbName('f4');          % looking Right

RKEY = KbName('r');         % repeat trial 
NKEY = KbName('n');         % next trial 

RAKEY = KbName('RightArrow');
LAKEY = KbName('LeftArrow');

F9 = KbName('f9');          % advance 10 frames
F7 = KbName('f7');          % rewind 10 frames

RSKEY = KbName('RightShift');

%% paths

if ismac || ispc
%     moviePath = '/Users/ngane001/Desktop/VideoCoderNG/movies';
%     dataPath = '/Users/ngane001/Desktop/VideoCoderNG/data';
    moviePath = fullfile(pwd, 'movies');
    dataPath  = fullfile(pwd, 'data');
else
    disp('Platform not supported') 
end



