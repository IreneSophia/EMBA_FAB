% This function presents the facial attention bias (FAB) task from the
% EMOPRED project. (c) Irene Sophia Plank, irene.plank@med.uni-muenchen.de
% Participants are asked to locate a target square that appears either left
% or right of the fixation cross. Before the target appears, a pair of one
% object and one face are flashed for 100ms. This experiment has been
% modelled after Jakobsen et al. (2020, Attention, Perception, &
% Psychophysics). There are 432 trials.
% This function takes no input but opens an input dialog box for: 
% * subID        :  a string array with the subjects PID
% * eyeTracking  :  0 or 1 to choose eye tracking or not
% The function needs Psychtoolbox to function properly. If eye tracking has
% been chosen, then a LiveTracking Eye Tracker has to be connected and the
% LiveTrackToolbox for MATLAB has to be installed. The function is meant to
% be used without an external monitor. Using a second monitor can seriously
% mess up the timing. 
% The function continually saves behavioural data as well as eye tracking
% data if that option is chosen. Both files will be placed in the "Data"
% folder. 
function taskFAB

% Get all relevant inputs. 
inVar = inputdlg({'Enter PID: ', 'Eye Tracking? 0 = no, 1 = yes'}, 'Input variables', [1 45]);
subID = convertCharsToStrings(inVar{1});
eyeTracking = str2double(inVar{2});

% Get the path of this function. 
path_src = fileparts(mfilename("fullpath")); 
idx  = strfind(path_src, filesep);
path_dat = path_src(1:(idx(end)-1));

% Clear the screen
sca;
close all;

% Initialise some settings
sq  = 90;     % size of target square in pixels
sqd = 205;    % distance of target square from center
pc  = 326;    % size of picture in pixels
tx  = 150;     % text size for fixation cross
fx  = 40;     % size of the size of the arms of our fixation cross
pcdur = 0.2;  % duration of cues in seconds
fxdur = 0.75; % duration of the fixation cross in seconds

% Open a csv file into which you can write information
fid = fopen(path_dat + "\Data\FAB-BV-" + subID + "_" + datestr(datetime(),'yyyymmdd-HHMM') + ".csv", 'w');
fprintf(fid, 'subID,trl,blk,left,right,target,congruent,iti,cue_dur,key,rt\n');

% Add eye tracking stuff, if eyeTracking is set to 1. 
if eyeTracking
    % Initialise LiveTrack
    crsLiveTrackInit;
    % Open a data file to write the data to.
    crsLiveTrackSetDataFilename(char(path_dat + "\Data\FAB-ET-" + subID + "_" + datestr(datetime(),'yyyymmdd-HHMM') + ".csv"));
end

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% This use of the subfunction 'UnifyKeyNames' within KbName()
% sets the names of the keys to be the same across operating systems
% (This is useful for making our experiment compatible across computers):
KbName('UnifyKeyNames');

% Load all the block orders and combine them randomly
border = Shuffle(["1", "2", "3"]);
tbl = [];
for i = border
    t = readtable(path_src+"\b"+i+"_order.csv");
    t.blk = repmat(i,[height(t),1]);
    tbl = [tbl; t];
end
ntrials = height(tbl);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
% For help see: Screen Screens?
screens = Screen('Screens');

% Adjust tests of the system:
%   Screen('Preference','SyncTestSettings' [, maxStddev=0.001 secs][, minSamples=50][, maxDeviation=0.1][, maxDuration=5 secs]);
Screen('Preference','SkipSyncTests', 0);
Screen('Preference','SyncTestSettings', 0.0025);

% Draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen. When only one screen is attached to the monitor we will draw to
% this.
% For help see: help max
screenNumber = max(screens);

% Define white (white will be 1 and black 0).
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% And the function ListenChar(), with the single number input 2,
% stops the keyboard from sending text to the Matlab window.
ListenChar(2);
% To switch the keyboard input back on later we will use ListenChar(1).

% As before we start a 'try' block, in which we watch out for errors.
try

    % Open an on screen window and color it black
    % For help see: Screen OpenWindow?
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);

    % Adjust the default font size.
    Screen('TextSize', window, tx);

    % Hide the mouse cursor
    HideCursor(window);

    % Load all pictures
    pic_files = dir([path_src '\Stimuli\SHINEd_*']);
    pics = nan(length(pic_files),1);
    for i = 1:length(pic_files)
        pic = imread([pic_files(i).folder filesep pic_files(i).name]);
        pics(i) = Screen('MakeTexture', window, pic);
    end
    
    % Get the size of the on screen window in pixels
    % For help see: Screen WindowSize?
%     [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    
    % Get the centre coordinate of the window in pixels
    % For help see: help RectCenter
    [xCenter, yCenter] = RectCenter(windowRect);

    % Query the frame duration
    ifi = Screen('GetFlipInterval', window);

    % Set up alpha-blending for smooth (anti-aliased) lines
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Make a base Rect of 90 by 90 pixels. This is the rect which defines the
    % size of our rectangle in pixels.
    % The coordinates define the top left and bottom right coordinates of our rect
    % [top-left-x top-left-y bottom-right-x bottom-right-y].
    % The easiest thing to do is set the first two coordinates to 0,
    % then the last two numbers define the length of the
    % rect in X and Y. The next line of code then centers the rect on a
    % particular location of the screen.
    tarRect = {[xCenter-sq/2-sqd yCenter-sq/2 xCenter-sqd+sq/2 yCenter+sq/2]... % left target
        [xCenter+sqd-sq/2 yCenter-sq/2 xCenter+sq/2+sqd yCenter+sq/2]};
    rectColor = [0 0 0];

    % Here we set the size of the arms of our fixation cross
    fixCrossDimPix = fx;
    
    % Now we set the coordinates (these are all relative to zero we will let
    % the drawing routine center the cross in the center of our monitor for us)
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Set the line width for our fixation cross
    lineWidthPix = round(fx/10);

    if eyeTracking
        % Start streaming calibrated results
        crsLiveTrackSetResultsTypeCalibrated;
        % Start tracking
        crsLiveTrackStartTracking;
    end
    
    % Go through the trials
    for i = 1:ntrials
    
        % Draw the fixation cross in black, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, black, [xCenter yCenter], 2);

        % Flip the fixation cross to the screen
        t_fix = Screen('Flip', window);
        if eyeTracking
            % Add a comment/trigger to the eye tracking data. 
            crsLiveTrackSetDataComment(sprintf('fix_%i_%i_%i_%i_%i',...
                i,tbl.left(i),tbl.right(i),tbl.target(i),tbl.congruent(i)));
        end
        WaitSecs(fxdur-ifi);
        
        % Draw the cue to the screen. 
        % If we want to put it in a particular position, 
        % we must give a rectangle as the location of the picture.
        % This rectangle follows the 'left, top, right, bottom' convention,
        % and is given as the fourth input to 'DrawTexture'.
        % We do not need the third input, so we leave it empty.
        Screen('DrawTexture', window, pics(tbl.left(i)), [], [xCenter-pc/2-sqd yCenter-pc/2 xCenter-sqd+pc/2 yCenter+pc/2]);
        Screen('DrawTexture', window, pics(tbl.right(i)), [], [xCenter+sqd-pc/2 yCenter-pc/2 xCenter+pc/2+sqd yCenter+pc/2]);

        % Flip the cue to the screen
        t_cue = Screen('Flip', window);
        if eyeTracking
            % Add a comment/trigger to the eye tracking data. 
            crsLiveTrackSetDataComment(sprintf('cue_%i_%i_%i_%i_%i',...
                i,tbl.left(i),tbl.right(i),tbl.target(i),tbl.congruent(i)));
        end
        iti = (t_cue - t_fix) * 1000;
        WaitSecs(pcdur-ifi);
        
        % Draw the square to the screen. For information on the command used in
        % this line see Screen FillRect?
        Screen('FillRect', window, rectColor, tarRect{tbl.target(i)});
      
        % Flip to the screen. This command basically draws all of our previous
        % commands onto the screen. See later demos in the animation section on more
        % timing details. And how to demos in this section on how to draw multiple
        % rects at once.
        % For help see: Screen Flip?
        t_tar = Screen('Flip', window);
        if eyeTracking
            % Add a comment/trigger to the eye tracking data. 
            crsLiveTrackSetDataComment(sprintf('tar_%i_%i_%i_%i_%i',...
                i,tbl.left(i),tbl.right(i),tbl.target(i),tbl.congruent(i)));
        end
        cue_dur = (t_tar - t_cue) * 1000;

        % take a screenshot of the currently shown display and save it
%         imageArray = Screen('GetImage', window);
%         imwrite(imageArray, 'test.jpg')

        WaitSecs(0.1); % buffer so that still pressed keys don't get logged
        
        % Now we start a loop to continually check the keyboard until a key is pressed.
        pressed = 0;
        while ~pressed
            
            % Inside this loop, we use KbCheck to check the keyboard.
            % The first output of KbCheck is just a 0 or 1
            % to say whether or not a key has been pressed.
            % The second output is the time of the key press.
            % And the third output is a vector of 0 and 1 to say which key(s)
            % was/were pressed.
            [pressed,t_press,keyCode] = KbCheck;
            
        end

        key = KbName(keyCode);
        if iscell(key)
            key = key{1};
        end

        % First we check whether the key pressed was the escape key.
        if strcmp(key,'ESCAPE')
            
            % If it was, we generate an error, which will stop our script.
            % This will also send us to the catch section below,
            % where we close the screen and re-enable the keyboard for Matlab.
            error('Experiment aborted.')
            
        end
        
        % We then calculate the participant's reaction time.
        % We do this by subtracting the time of the Screen 'Flip'
        % from the time at which the key was pressed.
        rt = (t_press - t_tar) * 1000; % to get ms

        % Log all information in the log file
        fprintf(fid, '%s,%i,%s,%i,%i,%i,%i,%.0f,%.0f,%s,%.0f\n',subID,i,tbl.blk(i),tbl.left(i),tbl.right(i),tbl.target(i),tbl.congruent(i),iti,cue_dur,key,rt);
    
    end
    
    % If we encounter an error...
catch my_error

    % Close all open objects
    Screen('CloseAll');

    % Show the mouse cursor
    if exist('window', 'var')
        ShowCursor(window);
    end
    
    % Clear the screen (so we can see what we are doing).
    sca;
    
    % In addition, re-enable keyboard input (so we can type).
    ListenChar(1);

    % Close the open csv file 
    fclose(fid);

    % Stop eye tracking. 
    if eyeTracking
        crsLiveTrackStopTracking;
        crsLiveTrackCloseDataFile;
        crsLiveTrackClose;
    end
    
    % Tell us what the error was.
    rethrow(my_error)
    
end

% Draw the fixation cross in black to have for two seconds before ending
Screen('DrawLines', window, allCoords,...
    lineWidthPix, black, [xCenter yCenter], 2);
Screen('Flip', window);
WaitSecs(2);

% At the end, clear the screen and re-enable the keyboard.
Screen('CloseAll');
ShowCursor(window);
sca;
ListenChar(1);
fclose(fid);
if eyeTracking
    crsLiveTrackStopTracking;
    crsLiveTrackCloseDataFile;
    crsLiveTrackClose;
end

end
