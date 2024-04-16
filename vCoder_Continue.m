%% vCoder_Continue
%
%If the video has 2 parts, the second part should be labelled
%ExperimentName_subjectID_01.mp4. This part of the script allows the coder
%to continue coding the 2nd part of the video without loosing track of the
%trial number.
%
%  ========================
% Created by Natasa Ganea, Goldsmiths InfantLab, Jul 2019 (natasa.ganea@gmail.com)
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% ========================

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

if isempty(frameCountContinue)
    frameCount = 0;
else
    frameCount = frameCountContinue;
end

%trial = 0;
trialStart = 0;

frameByFrame = 0;
coderTxtSize = 20;
coderTxtColor = [255 255 255];
playbackRate = 1;
loopMov = 0;
soundMov = 0;

%% call the global variables

global EXPERIMENT;
global VIDEOWIN;
global VIDEOWINSIZE;
global CODERWIN;
global SUBJECT;
global s;

try
    
    % select video
    for j = 1:length(movieJName)
        movieJNameTmp = char(movieJName{j});
        jj = strfind(movieJNameTmp, s(3:5));
        flag = strcmp(movieJNameTmp(jj:end-3), s(3:5)); % compare if the name of the movie matches the subject
        if flag == 1
            movieIndex = j; % save movie has to be coded
        end
    end
    
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
                %Screen('TextSize', CODERWIN, coderTxtSize);
                DrawFormattedText(CODERWIN, 'Press SPACE to continue', 0, coderTxtSize * 2, coderTxtColor);
                DrawFormattedText(CODERWIN, 'Press Q to quit', 0, coderTxtSize * 3, coderTxtColor);
                Screen('Flip', CODERWIN);
                if vCoderCtrl('WaitSpace')
                    Screen('CloseMovie', mov);
                    vCoderCtrl('FinishCoding')                                         % if Q is pressed, finish experiment
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
            
            %% Right Arrow advance 1 frame; Up Arrow advance 10 frames
            if vCoderCtrl('IsKey', RAKEY) || vCoderCtrl('IsKey', F9)
                
                % Advance frame by frame
                frameByFrame = 1;
                
                % Check N frames to advance
                if vCoderCtrl('IsKey', RAKEY)
                    advanceNFrames = 1;
                elseif vCoderCtrl('IsKey', F9)
                    advanceNFrames = 10;
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
            
            %% Left Arrow rewind 1 frame; Down Arrow rewind 10 frames
            if vCoderCtrl('IsKey', LAKEY) || vCoderCtrl('IsKey', F7)
                
                % Rewind frame by frame
                frameByFrame = 1;
                
                % Check N frames to rewind
                if vCoderCtrl('IsKey', LAKEY)
                    rewindNFrames = 1;
                elseif vCoderCtrl('IsKey', F7)
                    rewindNFrames = 10;
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
    end
    
    % save .MAT file
    filename = sprintf('%s_%s.mat', EXPERIMENT, char(movieJName(movieIndex)));
    save(fullfile(dataPath,filename), 'lookTotal', 'framesLog');
    
    % save .CSV file for lookTotal
    tLookTotal = struct2table(lookTotal);
    filename = sprintf('%s_%s_lookTotal.csv', EXPERIMENT, char(movieJName(movieIndex)));
    writetable(tLookTotal, fullfile(dataPath,filename));
    
    % save .CSV file for framesLog
    tFramesLog = struct2table(framesLog);
    filename = sprintf('%s_%s_framesLog.csv', EXPERIMENT, char(movieJName(movieIndex)));
    writetable(tFramesLog, fullfile(dataPath,filename));
    
catch lasterror
    
    rethrow(lasterror);               %if there is an error, rethrow the error
    
end

