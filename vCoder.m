function vCoder(SUBJECT_in, frameCount_in, frameCountContinue_in, movieExt_in, trialsToCode_in)
%
%Function that allows frame by frame video coding. It reads .mp4 movies,
%and it saves the coding in 3 files: _framesLog.csv, _lookTotal.csv, and a
%Matlab file. 
%
%To use the function, type 'vCoder' in the command window. Then enter the 
%subject number. To jump to a specific frame in the movie, type 
%vCoder(subjectID, frameNumber). 
%
%The program is looking for the indicated video in the 'movies' folder, and 
%it saves the data in the 'data' folder. The movies have to have the format
%ExperimentNane_subjectID.mp4. 
%
%SPACEBAR:      play the movie forward at normal rate
%RightArrow:    pause the movie and advance frame by frame 
%LeftArrow:     pause the movie and rewind frame by frame
%F1 + RightArrow: participant is looking at the screen
%F3 + RightArrow: participant is looking to the LEFT (i.e. coder's left)
%F4 + RightArrow: participant is looking to the RIGHT (i.e. coder's right)
%N:     mark the start of a new tria
%R:     rewind to the frame where the trial started and redo the coding
%ESC:   pause; press SPACEBAR to continue; press Q to quit
%
%Demo: Type vCoder in the Command Window. Then enter subjectID: 699. 
%
%  ========================
% Created by Natasa Ganea, Goldsmiths InfantLab, Jan 2019 (natasa.ganea@gmail.com)
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% ========================

%% EXPERIMENT global variables

global EXPERIMENT;
global BACKCOLOR;
global VIDEOWIN;
global VIDEOWINSIZE;
global CODERWIN;
global CODERWINSIZE;
global SUBJECT;
global s;

EXPERIMENT = 'vCoder';
BACKCOLOR = [0 0 0];                % BACKCOLOR = black
VIDEOWINSIZE = [0 0 1000 700];      % VIDEO window on the left
CODERWINSIZE = [1000 0 1300 700];   % CODER window on the right


%% function variables

% if no subject number given, ask user to enter it
if nargin < 1 || isempty(SUBJECT_in)
    fprintf('\n');
    SUBJECT = input('Subject number: '); % prompt for user input
    fprintf('\n');
else
    SUBJECT = SUBJECT_in; 
end


% if no trial given, start from 0
if nargin < 2 || isempty(frameCount_in)
    frameCount = 0; 
else
    frameCount = frameCount_in;
end

% if no frameCountContinue given, start from 0
if nargin < 3 || isempty(frameCountContinue_in)
    frameCountContinue = []; 
else
    frameCountContinue = frameCountContinue_in;
end

% if no movie extension given, use .mp4
if nargin < 4 || isempty(movieExt_in)
    movieExt = '.mp4'; % movie extentnion fed into vCoder_LoadMov
else
    movieExt = movieExt_in;
end

% if no nr of trials to code given, use 20
if nargin < 5 || isempty(trialsToCode_in)
    trialsToCode = 50;
else
    trialsToCode = trialsToCode_in;
end


%% key controls & videos location

vCoder_Paths %script that defines the keycodes and the paths to the stimuli

%% load videos

[movieName, movieJName] = vCoder_LoadMov(movieExt, moviePath);  % script that loads the stimuli; do not use ';' after

%% initialize experiment variables

lookPerTr = struct('direction', {'Centre', 'Left', 'Right'},...
    'nrFrames', {0, 0, 0});
lookPerTrStr = cell(length(lookPerTr), 1);

lookTotal = struct;
for i = 1:trialsToCode
    lookTotal(i).id = [];
    lookTotal(i).trial = [];
    lookTotal(i).Centre = [];
    lookTotal(i).Left = [];
    lookTotal(i).Right = [];
end

trial = 0;
trialStart = 0;

frameByFrame = 0;
coderTxtSize = 20;
coderTxtColor = [255 255 255];
playbackRate = 1;
loopMov = 0;
soundMov = 0;

%% EXPERIMENT

try
    % start vCoder
    vCoderCtrl('StartCoding');
    
    % select video
    for j = 1:length(movieJName)
        movieJNameTmp = char(movieJName{j});
        jj = strfind(movieJNameTmp, s(3:5));
        flag = strcmp(movieJNameTmp(jj:end), s(3:5)); % compare if the name of the movie matches the subject
        flagContinue = strcmp(movieJNameTmp(jj:end-3), s(3:5));
        if flag == 1
            movieIndex = j; % save movie has to be coded
        elseif flagContinue == 1
            continueCoding = 1;
        end
    end
    
    if ~exist('movieIndex', 'var')
        codingLoop = 1;
        vCoderCtrl('FinishCoding')                                         % if Q is pressed, finish experiment
        fprintf(['ERROR: Subject %d \n'...
            'ERROR: Movie not found. Check MOVIES folder or SUBJECT number!'], SUBJECT);
    else
        % position mov
        [movRectDest] = VIDEOWINSIZE; % movie in top left corner
        
        % open mov
        [mov, dur, fps, movW, movH] = Screen('OpenMovie', VIDEOWIN, movieName{movieIndex}); % open movie
        
        % frame duration
        fpsDur = round(1/fps.*1000)./1000; 
        
        % calculate max number of frames
        frameCountMax = round(dur.*fps);
        
        % set time index to 0, use frames instead of seconds
        Screen('SetMovieTimeIndex', mov, frameCount.*(1/fps));
        
        % display first frame
        movText = Screen('GetMovieImage', VIDEOWIN, mov, 1);                                % get fr0
        Screen('DrawTexture', VIDEOWIN, movText,[], movRectDest, 0);                        % draw fr0
        Screen('Flip', VIDEOWIN);                                                           % flip fr0
        Screen('Close', movText);                                                           % close texture
        
        % record movie name
        fprintf('Movie: %s  %f duration, %f fps, w x h = %i x %i...\n',...
            movieJName{movieIndex}, dur, fps, movW, movH);
        
        % ready to code?
        Screen('TextSize', CODERWIN, coderTxtSize);
        DrawFormattedText(CODERWIN, 'Press SPACE to continue', 0, coderTxtSize * 2, coderTxtColor);
        DrawFormattedText(CODERWIN, 'Press Q to quit', 0, coderTxtSize * 3, coderTxtColor);
        Screen('Flip', CODERWIN);
        
        if vCoderCtrl('WaitSpace')
            Screen('CloseMovie', mov);
            vCoderCtrl('FinishCoding')                                         % if Q is pressed, finish experiment
            codingLoop = 1;
        else
            codingLoop = 0;                                                    % if SPACE is pressed, continue experiment
            
            % create a framesLog
            try
                % try to load a previously coded framesLok and lookTotal 
                filename = sprintf('%s_%s.mat', EXPERIMENT, char(movieJName(movieIndex)));
                dataSaved = load(fullfile(dataPath, filename),'framesLog', 'lookTotal');
                framesLog = dataSaved.framesLog;
                lookTotal = dataSaved.lookTotal;
                trial = framesLog(frameCount).trial;
                
                % calculate lookPerTr
                for i = 1:length(framesLog)
                    if framesLog(i).trial == trial
                        for j = 1:length(lookPerTr)
                            if strcmp(framesLog(i).look, lookPerTr(j).direction)
                                lookPerTr(j).nrFrames = lookPerTr(j).nrFrames + 1;
                            end
                        end
                    end
                end
                    
            catch
                framesLog = struct('frame', cell(frameCountMax, 1),...
                    'trial', cell(frameCountMax, 1),...
                    'look', cell(frameCountMax, 1));
            end
        end
    end
    
    %% start coding
    
    while codingLoop == 0
        
        % start mov playback
        Screen('PlayMovie', mov, playbackRate, loopMov, soundMov);
        
        % while mov is playing
        while 1
            
            %% if SPACE & playbackRate > 0 continue playback
            if playbackRate == 1
                
                % frame by frame
                if frameByFrame == 1
                    playbackRate = 0;
                    Screen('PlayMovie', mov, playbackRate, loopMov, soundMov);
                    WaitSecs(0.05);
                end
                
                % get the next frame
                movText = Screen('GetMovieImage', VIDEOWIN, mov, 0);
                
                % valid texture returned?
                if movText < 0
                    Screen('CloseMovie', mov);
                    if ~exist('continueCoding', 'var')
                        vCoderCtrl('FinishCoding')                                         % if Q is pressed, finish experiment
                    end
                    codingLoop = 1;
                    
                    % save trial LOOKING data into a master file
                    if trial > 0 && trial <= trialsToCode
                        lookTotal(trial).id = SUBJECT;
                        lookTotal(trial).trial = trial;
                        for i = 1:length(lookPerTr)
                            if strcmp(lookPerTr(i).direction,'Centre') == 1
                                lookTotal(trial).Centre = lookPerTr(i).nrFrames .* fpsDur; 
                            elseif strcmp(lookPerTr(i).direction,'Right') == 1
                                lookTotal(trial).Left = lookPerTr(i).nrFrames .* fpsDur; 
                            elseif strcmp(lookPerTr(i).direction,'Left') == 1
                                lookTotal(trial).Right = lookPerTr(i).nrFrames .* fpsDur; 
                            end
                        end
                    end
                    
                    break       % no, there was an error, abort playback loop
                end
                
                % no new frame in polling, try polling it again after a
                % short pause
                if movText == 0
                    WaitSecs('YieldSecs', 0.005);
                    continue
                end
                
                % draw the next texture immediately on screen
                Screen('DrawTexture', VIDEOWIN, movText, [], movRectDest, 0);
                
                % update display
                Screen('Flip', VIDEOWIN);
                
                % release texture
                Screen('Close', movText);
                
                % frameCount
                frameCount = frameCount + 1;
                
                % check for baby looking
                if vCoderCtrl('IsKey', F1)
                    lookOn = 'Centre';
                elseif vCoderCtrl('IsKey', F3)
                    lookOn = 'Left';
                elseif vCoderCtrl('IsKey', F4)
                    lookOn = 'Right';
                else
                    lookOn = 'OFF';
                end
                
                % update framesLog
                framesLog(frameCount).frame = frameCount;
                framesLog(frameCount).trial = trial;
                framesLog(frameCount).look = lookOn;
                
                % display frame number, trial, looking status, and summary
                frameCountStr = sprintf('Frame: %d', frameCount);
                DrawFormattedText(CODERWIN, frameCountStr, 0, coderTxtSize * 5, coderTxtColor);
                
                trialStr = sprintf('Trial: %d', trial);
                DrawFormattedText(CODERWIN, trialStr, 0, coderTxtSize * 6, coderTxtColor);
                
                lookOnStr = sprintf('LOOKING %s', lookOn);
                DrawFormattedText(CODERWIN, lookOnStr, 0, coderTxtSize * 8, coderTxtColor);
                
                for i = 1:length(lookPerTr)
                    lookPerTrStr{i} = sprintf('%s: %d fr', lookPerTr(i).direction, lookPerTr(i).nrFrames);
                    DrawFormattedText(CODERWIN, lookPerTrStr{i}, 0, coderTxtSize * (9+i), coderTxtColor);
                end
                
                if exist('trialStartStr', 'var')
                    DrawFormattedText(CODERWIN, trialStartStr, 0, coderTxtSize * 14, coderTxtColor);
                end
                
                Screen('Flip', CODERWIN);
                
            end
            
            %% increase nrFrames looking
            if frameByFrame == 1
                for j = 1:length(lookPerTr)
                    count = 0;
                    for i = 1:frameCount
                        if ~isempty(framesLog(i).trial) &&...
                                framesLog(i).trial == trial &&...
                                strcmp(framesLog(i).look, lookPerTr(j).direction) == 1
                            count = count + 1;
                        end
                    end
                    lookPerTr(j).nrFrames = count;
                end
            end
            
            %% check for quit vCoder
            if vCoderCtrl('IsKey', ESC)
                DrawFormattedText(CODERWIN, 'Press SPACE to continue', 0, coderTxtSize * 2, coderTxtColor);
                DrawFormattedText(CODERWIN, 'Press Q to quit', 0, coderTxtSize * 3, coderTxtColor);
                Screen('Flip', CODERWIN);
                if vCoderCtrl('WaitSpace')
                    Screen('CloseMovie', mov);
                    if ~exist('continueCoding', 'var')
                        vCoderCtrl('FinishCoding')                                         % if Q is pressed, finish experiment
                    end
                    codingLoop = 1;
                    
                    % save trial LOOKING data into a master file
                    if trial > 0 && trial <= trialsToCode
                        lookTotal(trial).id = SUBJECT;
                        lookTotal(trial).trial = trial;
                        for i = 1:length(lookPerTr)
                            if strcmp(lookPerTr(i).direction,'Centre') == 1
                                lookTotal(trial).Centre = lookPerTr(i).nrFrames .* fpsDur; 
                            elseif strcmp(lookPerTr(i).direction,'Right') == 1
                                lookTotal(trial).Left = lookPerTr(i).nrFrames .* fpsDur; 
                            elseif strcmp(lookPerTr(i).direction,'Left') == 1
                                lookTotal(trial).Right = lookPerTr(i).nrFrames .* fpsDur; 
                            end
                        end
                    end
                    
                    % break the while 1 loop
                    break
                else
                    codingLoop = 0;                                                    % if SPACE is pressed, continue experiment
                end
            end
            
            %% SPACE play video
            if vCoderCtrl('IsKey', SPACE)
                frameByFrame = 0;
                playbackRate = 1;
                Screen('SetMovieTimeIndex', mov, frameCount.*(1/fps));
                Screen('PlayMovie', mov, playbackRate, loopMov, soundMov);
            end
            
            %% Right Arrow advance 1 frame; F9 advance 1000 frames
            if vCoderCtrl('IsKey', RAKEY) || vCoderCtrl('IsKey', F9)
                
                % Advance frame by frame
                frameByFrame = 1;
                
                % Check N frames to advance
                if vCoderCtrl('IsKey', RAKEY)
                    advanceNFrames = 1;
                elseif vCoderCtrl('IsKey', F9)
                    advanceNFrames = 1000;
                else
                    advanceNFrames = 0;
                end
                frameCount = frameCount + advanceNFrames - 1;
                
                % Advance
                if frameCount <= frameCountMax
                    playbackRate = 1;
                    Screen('SetMovieTimeIndex', mov, frameCount.*(1/fps));
                    Screen('PlayMovie', mov, playbackRate, loopMov, soundMov);
                else
                    frameCount = frameCountMax;
                    playbackRate = 0;
                    errorStr = 'End of video!';
                    DrawFormattedText(CODERWIN, errorStr, 0, coderTxtSize * 2, coderTxtColor);
                    Screen('Flip', CODERWIN);
                end
            end
            
            %% Left Arrow rewind 1 frame; F7 rewind 1000 frames
            if vCoderCtrl('IsKey', LAKEY) || vCoderCtrl('IsKey', F7)
                
                % Rewind frame by frame
                frameByFrame = 1;
                
                % Check N frames to rewind
                if vCoderCtrl('IsKey', LAKEY)
                    rewindNFrames = 1;
                elseif vCoderCtrl('IsKey', F7)
                    rewindNFrames = 1000;
                else
                    rewindNFrames = 0;
                end
                
                % update framesLog, empty entered values for those frames
                if rewindNFrames > 0
                    for i = 1:rewindNFrames
                        if frameCount > i
                            framesLog(frameCount-i+1).frame = [];
                            framesLog(frameCount-i+1).trial = [];
                            framesLog(frameCount-i+1).look = [];
                        end
                    end
                end
                frameCount = frameCount - rewindNFrames - 1;
                
                % Rewind
                if frameCount >= 0
                    playbackRate = 1;
                    Screen('SetMovieTimeIndex', mov, frameCount.*(1/fps));
                    Screen('PlayMovie', mov, playbackRate, loopMov, soundMov);
                else
                    frameCount = 0;
                    playbackRate = 0;
                    errorStr = 'Beginning of video!';
                    DrawFormattedText(CODERWIN, errorStr, 0, coderTxtSize * 2, coderTxtColor);
                    Screen('Flip', CODERWIN);
                end
            end
            
            %% update trial number
            
            % next trial
            if frameByFrame == 1 && vCoderCtrl('IsKey', NKEY) == 1
                
                % save trial LOOKING data into a master file
                if trial > 0 && trial <= trialsToCode
                    lookTotal(trial).id = SUBJECT;
                    lookTotal(trial).trial = trial;
                    for i = 1:length(lookPerTr)
                        if strcmp(lookPerTr(i).direction,'Centre') == 1
                            lookTotal(trial).Centre = lookPerTr(i).nrFrames .* fpsDur; 
                        elseif strcmp(lookPerTr(i).direction,'Right') == 1
                            lookTotal(trial).Left = lookPerTr(i).nrFrames .* fpsDur; 
                        elseif strcmp(lookPerTr(i).direction,'Left') == 1
                            lookTotal(trial).Right = lookPerTr(i).nrFrames .* fpsDur; 
                        end
                    end
                end
                
                % reset the number of LOOKING frames when starting a new trial
                for i = 1:length(lookPerTr)
                    lookPerTr(i).nrFrames = 0;
                end
                
                % update trial number
                trial = trial + 1;                                         % jump to next tr
                
                % store the number of trialStart frame
                trialStart = frameCount;
                
                % update display
                trialStartStr = sprintf('Trial: %d    Start: %d fr', trial, trialStart);
                DrawFormattedText(CODERWIN, trialStartStr, 0, coderTxtSize * 13, coderTxtColor);
                Screen('Flip', CODERWIN);
                WaitSecs(0.2);
                
                % subtract one frame in order to recode the trialStart frame
                if frameCount > 0
                    frameCount = frameCount - 1;
                end
                
                % repeat trial
            elseif frameByFrame == 1 && vCoderCtrl('IsKey', RKEY) == 1
                
                % delete already coded data
                for j = 1:(frameCount-trialStart)
                    if frameCount > j
                        framesLog(frameCount-j+1).frame = [];
                        framesLog(frameCount-j+1).trial = [];
                        framesLog(frameCount-j+1).look = [];
                    end
                end
                
                % update trial number
                if trial > 0
                    trial = trial - 1;                                     % repeat tr
                else
                    trial = 0;
                end
                
                % update display
                trialStartStr = sprintf('Trial: %d    Start: %d fr', trial, trialStart);
                DrawFormattedText(CODERWIN, trialStartStr, 0, coderTxtSize * 13, coderTxtColor);
                Screen('Flip', CODERWIN);
                WaitSecs(0.2);
                
                % reset frame number to trialStart frame
                if frameCount > 0
                    frameCount = trialStart - 1;
                else
                    frameCount = trialStart;
                end
                
            end
        end
        
        % save .MAT file
        filename = sprintf('%s_%s.mat', EXPERIMENT, char(movieJName(movieIndex)));
        save(fullfile(dataPath,filename), 'lookTotal', 'framesLog', 'lookPerTr', ...
            'EXPERIMENT', 'movieJName', 'movieIndex', 'dataPath');
        
        % save .CSV file for lookTotal
        tLookTotal = struct2table(lookTotal);
        filename = sprintf('%s_%s_lookTotal.csv', EXPERIMENT, char(movieJName(movieIndex)));
        writetable(tLookTotal, fullfile(dataPath,filename));
        
        % save .CSV file for framesLog
        tFramesLog = struct2table(framesLog);
        filename = sprintf('%s_%s_framesLog.csv', EXPERIMENT, char(movieJName(movieIndex)));
        writetable(tFramesLog, fullfile(dataPath,filename));
        
        % continue if there are more videos for the same baby
        if exist('continueCoding','var') && continueCoding == 1
            
            % update display
            trialStart = 0;
            trialStartStr = sprintf('Trial: %d    Start: %d fr', trial, trialStart);
            DrawFormattedText(CODERWIN, trialStartStr, 0, coderTxtSize * 13, coderTxtColor);
            Screen('Flip', CODERWIN);
            WaitSecs(0.2);
            
            % jump to desired frame in the 2nd video
            if isempty(frameCountContinue)
                frameCount = 0;
            else
                frameCount = frameCountContinue;
            end
            
            vCoder_Continue
        end
        
    end
    
    % clear all global variables
    clearvars -global
    
catch lasterror
    
    rethrow(lasterror);               %if there is an error, rethrow the error
    
end

