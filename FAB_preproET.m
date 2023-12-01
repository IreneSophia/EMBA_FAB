% This function preprocesses eye tracking data for the FAB task collected
% with a LiveTrack Lightning Eye Tracker. It takes the filename of the csv
% and the path of the file as input. All data is saved in the same folder
% as the input file. 
% 
% Detection of events (blinks, saccades, glissades and fixations) is based
% on NYSTRÖM & HOLMQVIST (2010).
%
% (c) Irene Sophia Plank 10planki@gmail.com

function FAB_preproET(filename, dir_path)

%% read in data and calculate values

% get subject ID from the filename
subID = convertStringsToChars(extractBefore(filename,"_"));
fprintf('\nNow processing subject %s.\n', extractAfter(subID,'-'));

% set options for reading in the data
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [2, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["timestamp", "trigger", "leftScreenX", "leftScreenY",...
    "rightScreenX", "rightScreenY", "leftPupilMajorAxis", "leftPupilMinorAxis",...
    "rightPupilMajorAxis", "rightPupilMinorAxis", "comment"];
opts.VariableTypes = ["double", "double", "double", "double", "double",...
    "double", "double", "double", "double", "double", "string"];

tbl = readtable([dir_path filesep filename], opts); 
tbl.pupilDiameter = mean([tbl.leftPupilMajorAxis,tbl.leftPupilMinorAxis],2);
tbl.tracked = bitget(tbl.trigger,14-3); 
tbl.pupilDiameterRight = mean([tbl.rightPupilMajorAxis,tbl.rightPupilMinorAxis],2);
tbl.trackedRight = bitget(tbl.trigger,15-3); 

%% add trial information

% total number of trials
not = 432;

% find trial indices
idx = [find(extractBefore(tbl.comment,4) == "fix"),...
    find(extractBefore(tbl.comment,4) == "cue"),...
    find(extractBefore(tbl.comment,4) == "tar")];

if size(idx,1) ~= not
    error("This FAB dataset does NOT have the correct amount of 432 trials!")
end

% add another row at the end
idx(not+1,:) = [idx(end,3)+500 NaN NaN];

% create empty columns to be filled with information
tbl.trialType = strings(height(tbl),1);
tbl.trialNo   = nan(height(tbl),1);
tbl.trialStm  = strings(height(tbl),1);
tbl.trialCue  = strings(height(tbl),1);
tbl.trialTar  = strings(height(tbl),1);
tbl.timeCue   = nan(height(tbl),1);
tbl.timeFix   = nan(height(tbl),1);
tbl.timeTar   = nan(height(tbl),1);

% loop through the trials and add the information from the comment: "type", "trial", "left",
% "right", "target", "face"
for i = 1:not

    % divide string
    trialinfo = strsplit(tbl.comment(idx(i,1)), "_");
    % trial number
    tbl.trialNo(idx(i,1):(idx(i+1,1)-1))   = trialinfo(2);
    % trial type
    tbl.trialType(idx(i,1):(idx(i,2)-1))   = "fix";
    tbl.trialType(idx(i,2):(idx(i,3)-1))   = "cue";
    tbl.trialType(idx(i,3):(idx(i+1,1)-1)) = "tar";
    % trial cue
    if trialinfo(6) == "1"
        tbl.trialCue(idx(i,1):(idx(i+1,1)-1)) = "face";
    else
        tbl.trialCue(idx(i,1):(idx(i+1,1)-1)) = "object";
    end
    % trial target location
    if trialinfo(5) == "2"
        tbl.trialTar(idx(i,1):(idx(i+1,1)-1)) = "right";
    else
        tbl.trialTar(idx(i,1):(idx(i+1,1)-1)) = "left";
    end
    % trial stimulus (face object combination)
    left  = str2double(trialinfo(3));
    right = str2double(trialinfo(4));
    if left < right 
        tbl.trialStm(idx(i,1):(idx(i+1,1)-1)) = trialinfo(3) + "_" + trialinfo(4);
    else
        tbl.trialStm(idx(i,1):(idx(i+1,1)-1)) = trialinfo(4) + "_" + trialinfo(3);
    end
    % add time since onset information
    tbl.timeFix(idx(i,1):(idx(i+1,1)-1)) = 0:2:((length(tbl.timeFix(idx(i,1):(idx(i+1,1)-1)))*2)-1);
    tbl.timeCue(idx(i,2):(idx(i+1,1)-1)) = 0:2:((length(tbl.timeFix(idx(i,2):(idx(i+1,1)-1)))*2)-1);
    tbl.timeTar(idx(i,3):(idx(i+1,1)-1)) = 0:2:((length(tbl.timeFix(idx(i,3):(idx(i+1,1)-1)))*2)-1);

end

%% classification of events

% generate parameters for NH2010 classification code.
ETparams = defaultParameters;
ETparams.screen.resolution              = [2560 1600];   % screen resolution in pixel
ETparams.screen.size                    = [0.344 0.215]; % screen size in m
ETparams.screen.viewingDist             = 0.57;          % viewing distance in m
ETparams.screen.dataCenter              = [ 0 0];        % center of screen has these coordinates in data
ETparams.screen.subjectStraightAhead    = [ 0 0];        % specify the screen coordinate that is straight ahead of the subject. Just specify the middle of the screen unless its important to you to get this very accurate!

% format gaze directions as screen pixel coords for NH2010
tbl.xPixel = tbl.leftScreenX/(ETparams.screen.size(1)*ETparams.screen.resolution(1));
tbl.yPixel = tbl.leftScreenY/(ETparams.screen.size(2)*ETparams.screen.resolution(2));

% run the H2010 classifier code on full data set
[classificationData,ETparams]   = runNH2010Classification(...
    tbl.xPixel,tbl.yPixel,tbl.pupilDiameter,ETparams);

%% create output tables

% glissades
fn = fieldnames(classificationData.glissade);
for k = 1:numel(fn)
    if size(classificationData.glissade.(fn{k}),1) < size(classificationData.glissade.(fn{k}),2)
        classificationData.glissade.(fn{k}) = classificationData.glissade.(fn{k}).';
    end
end
tbl_gli = struct2table(classificationData.glissade);

% fixations
fn = fieldnames(classificationData.fixation);
for k = 1:numel(fn)
    if size(classificationData.fixation.(fn{k}),1) < size(classificationData.fixation.(fn{k}),2)
        classificationData.fixation.(fn{k}) = classificationData.fixation.(fn{k}).';
    end
end
tbl_fix = struct2table(classificationData.fixation);

% saccades
fn = fieldnames(classificationData.saccade);
for k = 1:numel(fn)
    if size(classificationData.saccade.(fn{k}),1) < size(classificationData.saccade.(fn{k}),2)
        classificationData.saccade.(fn{k}) = classificationData.saccade.(fn{k}).';
    end
end
% sometimes offsetVelocityThreshold is too long, then remove excess entries
n_sac = size(classificationData.saccade.on);
classificationData.saccade.offsetVelocityThreshold = ...
    classificationData.saccade.offsetVelocityThreshold(1:n_sac);
classificationData.saccade.peakVelocityThreshold = repmat( ...
    classificationData.saccade.peakVelocityThreshold, ...
    size(classificationData.saccade.peakVelocity,1), ...
    size(classificationData.saccade.peakVelocity,2));
classificationData.saccade.onsetVelocityThreshold = repmat( ...
    classificationData.saccade.onsetVelocityThreshold, ...
    size(classificationData.saccade.peakVelocity,1), ...
    size(classificationData.saccade.peakVelocity,2));
tbl_sac = struct2table(classificationData.saccade);

%% add trial information for on and off to the event tables

% add an index row to the data table
tbl.on  = (1:height(tbl)).';
tbl.off = (1:height(tbl)).';
cols    = ["trialType","trialNo","trialStm","trialCue", ...
    "trialTar","timeCue","timeFix","timeTar"];

% add event info to glissades
tbl_gli = join(tbl_gli,tbl(:,["on",cols]));
newNames = append("on_",cols);
tbl_gli = renamevars(tbl_gli,cols,newNames);
tbl_gli = join(tbl_gli,tbl(:,["off", cols]));
newNames = append("off_",cols);
tbl_gli = renamevars(tbl_gli,cols,newNames);

% add event info to fixations
tbl_fix = join(tbl_fix,tbl(:,["on",cols]));
newNames = append("on_",cols);
tbl_fix = renamevars(tbl_fix,cols,newNames);
tbl_fix = join(tbl_fix,tbl(:,["off", cols]));
newNames = append("off_",cols);
tbl_fix = renamevars(tbl_fix,cols,newNames);

% add event info to saccades
tbl_sac = join(tbl_sac,tbl(:,["on",cols]));
newNames = append("on_",cols);
tbl_sac = renamevars(tbl_sac,cols,newNames);
tbl_sac = join(tbl_sac,tbl(:,["off", cols]));
newNames = append("off_",cols);
tbl_sac = renamevars(tbl_sac,cols,newNames);

%% save data to disk

% save data structure and classification parameters to .mat file
save([dir_path filesep subID '_prepro.mat'], 'classificationData', 'ETparams');

% save event tables for further analyses
writetable(tbl_sac, [dir_path filesep subID '_saccades.csv']);
writetable(tbl_fix, [dir_path filesep subID '_fixations.csv']);
writetable(tbl_gli, [dir_path filesep subID '_glissades.csv']);

end