function state = vCoderCtrl(command,varargin)
%
%This function provides some basic tasks for vCoder: defines the
%VideoWindow, CodingWindow, it clears up the CodingWindow between trials, 
%it clears all the windows when coding is done. 
%
%  ========================
% Created by Natasa Ganea, Goldsmiths InfantLab, Jul 2019 (natasa.ganea@gmail.com)
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% ========================

state = false;

global BACKCOLOR;
global VIDEOWINSIZE;


switch lower(command)
    
    case 'startcoding'
        state = StartCoding();
        
    case 'finishcoding'
        FinishCoding();
        
    case 'erasescreen'
        
        % backcolor
        if nargin < 2
            color = BACKCOLOR;
        else
            color = varargin{1};
        end
        
        if nargin < 3
            colorW = VIDEOWINSIZE(3);
        else
            colorW = varargin{2};
        end
        
        % EXPWIN size height
        if nargin < 4
            colorH = VIDEOWINSIZE(4);
        else
            colorH = varargin{3};
        end
        
        % EXPWIN size width
        if nargin < 5
            flipWhen = GetSecs();
        else
            flipWhen = varargin{4};
        end
        
        % erase screen
        EraseScreen(color, colorW, colorH, flipWhen);
        
    case 'iskey'
        if nargin < 2
            key = 0;
        else
            key = varargin{1};
            if ~isnumeric(key)
                key = KbName(key);
            end
        end
        
        state = IsKey(key);
        
    case 'waitspace'
        state = WaitSpace();
        
    otherwise
        error('Invalid command. Call "help vCoderCtrl" to find out the available commands.');       
end

return

function state = StartCoding()

global KEYBOARD;
global SUBJECT;
global EXPERIMENT;
global VIDEOWIN;
global VIDEOWINSIZE;
global CODERWIN;
global CODERWINSIZE;
global s;

%% KEYBOARD

if isempty(KEYBOARD)
    kb = GetKeyboardIndices;            % based on PsychHID('Devices') struct
    if length(kb) > 1
        fprintf('\n PRESS ANY KEY TO DETERMINE KEYBOARD! \n');
        while isempty(KEYBOARD)         % WHILE is needed to restart the FOR loop
            for kbNum = 1:length(kb)
                t0 = clock;
                while etime(clock, t0) < 0.03       % check every 30 ms; etime = MATLAB function
                    isKeyDown = KbCheck(kb(kbNum));
                    if isKeyDown == 1               % if a key is pressed
                        KEYBOARD = kb(kbNum);
                        fprintf('\n Keyboard determined. \n');
                        break         % break the WHILE, but continue the FOR
                    end
                end
            end
        end
    else
        KEYBOARD = kb(1);
    end
end

% make sure keyboard mapping is the same on all supported operating systems
KbName('UnifyKeyNames');

%% SUBJECT

if isempty(SUBJECT) || (SUBJECT == 0)
    fprintf('\n');
    SUBJECT = input('Subject number: '); % prompt for user input
    fprintf('\n');
end

%% EXPERIMENT

if isempty(EXPERIMENT)
    EXPERIMENT = 'TEST'; % if no experiment name, used 'TEST'
end

%% MATLAB .LOG FILE
% Save Command Window text into a text file (e.g. TEST_001.log)

s = sprintf('%5.3f', SUBJECT/1000);
if SUBJECT > 0
    diary([EXPERIMENT '_' s(3:5) '.log']); % save text of Matlab session
end

%% SCREEN SYNC TESTS & STIMULI DISPLAY

% do Screen Sync Tests
Screen('Preference','SkipSyncTests', 1);
% To skip the Screen Sync Tests (NOT RECOMMENDED!): Screen('Preference','SkipSyncTests',1);

% identify number of displays
screens = Screen('Screens');
% screens = 0 (one display); screens = [0, 1, 2] (two displays)

% use display 2 as stimuli display
screenNum = max(screens);


%% Debugging Psychtoolbox

if screenNum == 0
    PsychDebugWindowConfiguration(0, 0.99) % debug psychtoolbox
end

%% Open EXPWIN

[VIDEOWIN] = Screen('OpenWindow', screenNum, 0, VIDEOWINSIZE);
[CODERWIN] = Screen('OpenWindow', screenNum, 0, CODERWINSIZE);

%% BACKCOLOR - backgrond color

%vCoderCtrl('EraseScreen'); % change the EXPWIN background (for the entire window)

%% SESSION INFO

fprintf('**************************************** \n');
fprintf('Experiment %s \n',EXPERIMENT); % Experiment name
fprintf('%s \n',datestr(now));          % Date
fprintf('Subject %s \n \n',s(3:5));     % Subject

%% state

state = false;

return

function FinishCoding()

global VIDEOWIN;
global CODERWIN;

% Turn off Matlab log
diary off;

% close VIDEOWIN and show cursor
if VIDEOWIN >= 0
    EraseScreen(VIDEOWIN);
    Screen('Close', VIDEOWIN);
    VIDEOWIN = -1;
    ShowCursor();
end

% close CODERWIN and show cursor
if CODERWIN >= 0
    EraseScreen(CODERWIN);
    Screen('Close', CODERWIN);
    CODERWIN = -1;
    ShowCursor();
end

Screen('CloseAll');
ShowCursor();

return

function EraseScreen(window, color, colorW, colorH, flipWhen)

global VIDEOWIN;
global VIDEOWINSIZE;
global CODERWIN;
global CODERWINSIZE;
global BACKCOLOR;

if nargin < 1 || isempty(window)
    window = CODERWIN; 
end

if nargin < 2 || isempty(color)   % if color is omitted or empty, make background BACKCOLOR
    color = BACKCOLOR;
end

if nargin < 3 || isempty(colorW)  % if color width is omitted or empty, use display width
    if window == CODERWIN
        colorW = CODERWINSIZE(3);
    elseif window == VIDEOWIN
        colorW = VIDEOWINSIZE(3);
    end
end

if nargin < 4 || isempty(colorH)  % if color height is omitted or empty, use display height
    if window == CODERWIN
        colorH = CODERWINSIZE(4);
    elseif window == VIDEOWIN
        colorH = VIDEOWINSIZE(4);
    end
end

if nargin < 5 || isempty(flipWhen)  % if flipWhen is omitted or empty, flip at the next available refresh rate
    flipWhen = GetSecs();
end

% experiment window size and height
if window == CODERWIN
    winW = CODERWINSIZE(3);
    winH = CODERWINSIZE(4);
elseif window == VIDEOWIN
    winW = VIDEOWINSIZE(3);
    winH = VIDEOWINSIZE(4);
end

% place colorRect in the centre of screen
colorRect = [(winW-colorW)/2, (winH-colorH)/2, (winW+colorW)/2, (winH+colorH)/2];

% check colorRect size, and adjust it if necessary
if window == CODERWIN
    if colorRect(1) <= 0
        colorRect(1) = CODERWINSIZE(1);
    elseif colorRect(2) <= 0
        colorRect(2) = CODERWINSIZE(2);
    elseif colorRect(3) <= 0
        colorRect(3) = CODERWINSIZE(3);
    elseif colorRect(4) <= 0
        colorRect(4) = CODERWINSIZE(4);
    end
elseif window == VIDEOWIN
    if colorRect(1) <= 0
        colorRect(1) = VIDEOWINSIZE(1);
    elseif colorRect(2) <= 0
        colorRect(2) = VIDEOWINSIZE(2);
    elseif colorRect(3) <= 0
        colorRect(3) = VIDEOWINSIZE(3);
    elseif colorRect(4) <= 0
        colorRect(4) = VIDEOWINSIZE(4);
    end
end


% fill the colorRect with the desired color
if window == CODERWIN
    Screen('FillRect', CODERWIN, color, colorRect);
elseif window == VIDEOWIN
    Screen('FillRect', VIDEOWIN, color, colorRect);
end

% flip the colorRect on the screen

if window == CODERWIN
    Screen('Flip', CODERWIN, flipWhen, 1); % allow additional writing on top
elseif window == VIDEOWIN
    Screen('Flip', VIDEOWIN, flipWhen, 1);
end

return

function state = WaitSpace()

KbName('UnifyKeyNames');
QKEY = KbName('q');
SPACEKEY = KbName('space');

while 1 % loop until condition is met (i.e. either Q or SPACE is pressed)
    if IsKey(QKEY)
        state = true;       % stop experiment if Q is pressed
        break
    elseif IsKey(SPACEKEY)  % continue experiment if SPACE is pressed
        state = false;
        break
    end
end

return

function ctrl = IsKey(key) 
    
global KEYBOARD

KbName('UnifyKeyNames');
[~,~,keyCode] = KbCheck(KEYBOARD); % KbCheck = PTB function; keyCode = matrix of key presses (1 = pressed)

if ~isnumeric(key)
    kc = KbName(key); % if function input is a key, find its corresponding keyCode
else
    kc = key;         % if function input is a keyCode, use it
end

if length(kc) > 1     % ENTER/RETURN has 2 keyCodes (i.e. 40, 158), use first keyCode
    kc = kc(1);
end

ctrl = keyCode(kc);   % index input into the keyCode matrix

return