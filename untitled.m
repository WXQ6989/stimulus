%% some useful pre-setup

% clear all exist variables and close all graphic buffer
clear all; sca;

% Unify key code for different operating system
KbName('UnifyKeyNames');

% Useful when you program on your laptop
Screen('Preference', 'SkipSyncTests', 1);

% Shuffle seeds for random number generator, otherwise the random number
% sequence would be the same every time when you restart MATLAB.
rng('shuffle');

% Move cursor to command window in case you modify your script while running
commandwindow;

% RestrictKeysForKbCheck(KbName('s'));
%% parameter

% input some information and use them as the name of the log file
subjectName = input('## Please input subject name: ', 's');
sessionNumber = input('## Please input session number: ');

% initialize as empty
params = []; 
% specify which monitor to use
params.screen.SCREEN_NUM = 0 ;  
% stereomode 6 means red-green anaglyph
params.screen.STEREO_MODE = 6;
% background color
params.screen.BACK_COLOR = 0;
% foreground color
params.screen.FOR_COLOR = 200;

%---------------Stimulus and screen size ----------------------------------
% These parameter would determine the stimulus size, please varify them.
params.screen.displayPhysicalWidthMM = Screen('DisplaySize', params.screen.SCREEN_NUM);  %mm
params.screen.viewingDistanceMM = 200;  %mm
% 
params.stim.sizeCubeDeg = 1.53;   % deg in visual angle
params.stim.sizeBarDeg = 1.1;
params.stim.widthBarDeg = 0.12;
params.stim.anchorPointDeg = 0.12;

params.stim.fixationPointDeg = 0.3;
params.stim.anchorPointOn4CornerDeg = 0.5;

%---------------Stimulus spatial parameters -----------------------------------------------------------
% --- Session A (exp 2, search task)
% --- Conditions included in this session, each row indicate a condition
params.stim.conditions = [ 1;    % B(inocular)
                          8;    % M(onocular)
                          6];   % D(ichoptic) C(ongruent)
params.stim.NTrialsPerCondition = 3 ;

%--- for search task (Here, border = target, since dichoptic bardor is dichopic presented target )
params.stim.NBorderSides = 2; % Number of side 1 = left, 2 = right
params.stim.TVerticalPositions = [5 6  7  8  9   10  11  12  13  14  15 16 17 18]; % Target vertical position
% Target horizontal shift from middle, whether it is left or right shift,
% corresponding to each verticaposition 
params.stim.THorizontalShift =   [8 8  9  9  10  10  10  10  10  10  9  9  8  8]; 
NVerticalLocations = length(params.stim.TVerticalPositions); % Number of possible vertical locations of the target;


%% open screen and draw buffers
% Open double-buffered onscreen window with the requested stereo mode,
[windowPtr, windowRect] = PsychImaging('OpenWindow', params.screen.SCREEN_NUM, ...
    params.screen.BACK_COLOR, [], [], [], params.screen.STEREO_MODE);
% return the center point coordinate of the screen
[Screen_center(1),Screen_center(2)]  = RectCenter(windowRect);

%------------------ calculate the pixel size ----------------------
PixelPerDegreeVA = windowRect(3) / (2 * atand(params.screen.displayPhysicalWidthMM / 2 / params.screen.viewingDistanceMM));

Fixationpoint_Pix = round(params.stim.fixationPointDeg * PixelPerDegreeVA);
AnchorpiontOn4corner_Pix = round(params.stim.anchorPointOn4CornerDeg * PixelPerDegreeVA);


% --------------------------------------------------------
% Buffer: Vergence Anchoring (fixation plus four corners)
% --------------------------------------------------------
% Open an offscreen buffer/ canva. We draw five ovals on it and then we can
% quickly display this buffer with patterns during the experiment.
VergenceAnchoringPage = Screen('OpenOffscreenWindow', windowPtr, params.screen.BACK_COLOR);

% draw central oval
Screen('FillOval', VergenceAnchoringPage, params.screen.FOR_COLOR, CenterRect([0 0 Fixationpoint_Pix Fixationpoint_Pix],windowRect));
% Specify the position of four ovals in the 4 corners of the screen
Anchorshift = AnchorpiontOn4corner_Pix * 2;
FourDots_rect = [CenterRectOnPoint([0 0 AnchorpiontOn4corner_Pix AnchorpiontOn4corner_Pix],Anchorshift ,Anchorshift);
    CenterRectOnPoint([0 0 AnchorpiontOn4corner_Pix AnchorpiontOn4corner_Pix],windowRect(3)-Anchorshift ,Anchorshift);
    CenterRectOnPoint([0 0 AnchorpiontOn4corner_Pix AnchorpiontOn4corner_Pix],10,windowRect(4)-Anchorshift);
    CenterRectOnPoint([0 0 AnchorpiontOn4corner_Pix AnchorpiontOn4corner_Pix],windowRect(3)-Anchorshift,windowRect(4)-Anchorshift)];
FourDots_rect = FourDots_rect';
% draw 4 ovals all at once
Screen('FillOval', VergenceAnchoringPage, params.screen.FOR_COLOR, FourDots_rect);

% --------------------------------------------------------
% Buffer: Waiting page
% --------------------------------------------------------
WaitInstructionPage = Screen('OpenOffscreenWindow', windowPtr, params.screen.BACK_COLOR);
% Display some texts on screen
Screen('DrawText',WaitInstructionPage, 'Wait ...', Screen_center(1)-50,Screen_center(2), params.screen.FOR_COLOR);
Screen('FillOval', WaitInstructionPage, params.screen.FOR_COLOR, FourDots_rect);

% --------------------------------------------------------
% Buffer: Instruction page before next trial
% --------------------------------------------------------
NextTrialInstructionPage = Screen('OpenOffscreenWindow', windowPtr, params.screen.BACK_COLOR);
Screen('DrawText',NextTrialInstructionPage,  'Press a button for the next trial',  Screen_center(1)-50,Screen_center(2), params.screen.FOR_COLOR);
Screen('FillOval', NextTrialInstructionPage, params.screen.FOR_COLOR, FourDots_rect);

% --------------------------------------------------------
% Set up the basic stimulus bars
% --------------------------------------------------------
%--- get the basic bar image matrix.
%% stimulus grid parameter

% A choice of grid numbers and cube/bar size.
params.stim.NbX = 30; 
params.stim.NbY = 22;  
SizeCube = round(params.stim.sizeCubeDeg * PixelPerDegreeVA);  
Sizebar = round(params.stim.sizeBarDeg * PixelPerDegreeVA);  
Widthbar = params.stim.widthBarDeg * PixelPerDegreeVA;
AnchorpiontPix = round(params.stim.anchorPointDeg * PixelPerDegreeVA);

%--- The angle of the bar from vertical or horizontal, such that the orientation contrast will be 2* Angle.
params.stim.angleDeg = 25; 

% left and right tilted bars
params.stim.NitemTypes = 2;

%--- the maximum pixel value allocated to stimulus.
maxValue = params.screen.FOR_COLOR;
%--- for half or whole strength bar stimulus, half is used for binocular
%stimulus while whole is used for monocular stimulus 
params.stim.HALF_STRENGTH =0.5; params.stim.WHOLE_STRENGTH = 1; 

%%
% Get the basic Horizontal bars------------------------------
x=linspace(-1,1,Sizebar);
y=linspace(-1,1,Sizebar);
[X Y]=meshgrid(x,y);
% bar=cos(X).^300;
bar = abs(X)<(Widthbar/Sizebar/2);

CubeVertical = bar;
% Normalize the CubeVer to the maxValue we set
CubeVertical=maxValue*CubeVertical/max(max(CubeVertical)); 
CubeHorizental = CubeVertical';
%--- 
%Get the tilted bars-------------------------------------------------
CubeTilted= imrotate(CubeVertical,params.stim.angleDeg,'bicubic','crop');
CubeTilted = (CubeTilted> 0).*CubeTilted;

%--- small angle left and right tilted bar
CubeLeftTiltSmallAngle = CubeTilted;   

% Transpose to make it near horizontal
CubeLeftTiltSmallAngleNearHorizontal = CubeLeftTiltSmallAngle';
% flip horizontally to make right tilted bar
CubeRightTiltSmallAngleNearHorizontal = CubeLeftTiltSmallAngleNearHorizontal(Sizebar:-1:1, :);

AllCubes = zeros(params.stim.NitemTypes, Sizebar, Sizebar);
AllCubes(1, :,:) = CubeLeftTiltSmallAngleNearHorizontal;
AllCubes(2, :,:) = CubeRightTiltSmallAngleNearHorizontal;


%% --------------------------------------------------------
% Buffer: End page
% --------------------------------------------------------
ExperimentFinishPage = Screen('OpenOffscreenWindow', windowPtr, params.screen.BACK_COLOR);
Screen('DrawText',ExperimentFinishPage,  'Trials completed --- Thank you very much!!',  Screen_center(1)-100,Screen_center(2), params.screen.FOR_COLOR);
Screen('DrawText',ExperimentFinishPage,  'please tell the experimenter your comments/observations',  Screen_center(1)-100,Screen_center(2)+30, params.screen.FOR_COLOR);
Screen('FillOval', ExperimentFinishPage, params.screen.FOR_COLOR, FourDots_rect);

%% trial loop
%--------------------------------------------------------------------------
% EXPERIMENT
%--------------------------------------------------------------------------

%--- Set the sequence of trials as randomly interleaving conditions.
NConditions=size(params.stim.conditions,1); % Total number of conditions
NTrials = params.stim.NTrialsPerCondition * NConditions;
TrialSequence = repmat(1:NConditions, 1, params.stim.NTrialsPerCondition);
seq = randperm(NTrials);
TrialSequence = TrialSequence(seq);

% get time information
day = date; clocktime = clock;
% define the log file name
fn =[subjectName, '-r', num2str(sessionNumber), '-', day, '-', num2str(clocktime(4)), '-', num2str(clocktime(5)), '.mat'];

% -- loop for each trial
for iTrial=1:NTrials
%for iTrial=1:1
    % get condition for the current trial
    condition = params.stim.conditions(:);
    %--- do the trial, record responses.
    eslib_DoATrial_novsg;
    FlushEvents('keyDown');	% Discard all the chars from the Event Manager queue.
    
    % save the data..............
    % The lines of data saving for other sessions are commented
    data{iTrial,1} = condition;
    data{iTrial,2} = char;   %--- response button pressed
    data{iTrial,3} = RT;     %--- response RT
    data{iTrial,4} = StimulusContent; %--- the content of the stimulus as matrix arrays of bar indices
    data{iTrial,5} = StimulusPresentationMode; %--- the presentation (binocular, Left eye, or Right eye presentation) of each bar
    data{iTrial,6} = Side;     %--- the side of the border or target, left or right (1, or 2);
%     data{trial,7} = BorderPosition;   %--- the location of the border.
%     data{trial,8} = DichopticBorderPosition;  %--- the location of the dichoptic border
%     data{trial,9} = SegOrSearch;
    data{iTrial,10} = [TargetHorizontalPosition, TargetVerticalPosition];   %--- location of the search target
    data{iTrial,11} = [DichopticTargetHPosition, DichopticTargetVPosition]; %--- location of the dichoptic Target.
%     data{trial,12} =  DichopticBorderSide;      %--- the side of the dichoptic border or target.
   
    data{iTrial,14} = CubeRelativePositionsx;   %--- positions of the bars.
    data{iTrial,15} = CubeRelativePositionsy;
end

%% Finish

Screen('SelectStereoDrawBuffer',windowPtr,0);
Screen('DrawTexture', windowPtr, ExperimentFinishPage);
Screen('SelectStereoDrawBuffer',windowPtr,1);
Screen('DrawTexture', windowPtr, ExperimentFinishPage);
Screen('Flip', windowPtr);
% leave the ending page on the screen until a key press is received
pause(1);
KbWait;

% save all variables into file named fn
save(fn)
% short for "Screen('CloseAll')"
% close all buffers and textures and exit PTB 
sca







