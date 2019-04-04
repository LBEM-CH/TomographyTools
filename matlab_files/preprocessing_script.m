% Preprocessing script (Stefano Scaramuzza, 2018, stefano.scaramuzza@unibas.ch)
%
% This matlab script does:
% - motion correction using motioncor2Wrapper.m
% - dose weighting using same algorithm from unblur
% - rearrangement of single tilts into one stack ready to be used for imod
%
% Imortant: the tilt angle in the filename is assumed to be correct and is used in the tilt angle file.
%
% - input:
%       - movies (.mrc)
% - output:
%       - aligned AND dose weighted stack
%       - aligned ONLY stack (no wighting)
%       - tilt angle file
%
% This script should be seen as an example and be adapted where needed..
%
% Input parameters for script (other parameters, e.g., motioncor2Wrapper.m inputs,can be set furhter below):
pxSize = 2.73;                     % pixelsize for dose weighting
tID    = [22];                     % tilt series ID (can be a vector, e.g., [1 2 23 31])
fDose  = 0.286;                    % dose per frame (e/a2) for each tilt ID
fN     = 10;                       % Amount of frames per tilt for each tilt ID
tiltTemplate = -60:3:60;	       % set tilt angles in order we want them to be
rd = 0.8;                          % reduce dose by this factor

% start computation
for i = 1:length(tID)
    
    % get tomogram id
    tomo = tID(i);
    
    % initialize new empty stack
    newStack   = zeros(3710,3838,41);
    newStackUW = zeros(3710,3838,41);
    
    % loop through movies (single tilts) of current tomogram
    for tilt = 0:40
        
        % status
        disp(['Processing tilt: ' num2str(tilt+1) '  from tomogram: ' num2str(tomo)])
        
        % generate input filename of movie (tilt) to read
        filnamInW = ['TS' sprintf('%2.2d',tomo) '_' sprintf('%3.3d',tilt) '_*.mrc'];
        filnamInC  = dynamo_regexp2files(filnamInW);
        if length(filnamInC) ~= 1; warning(['More than one file. Processing: ' filnamInC{1}]); end
        filnamIn   = filnamInC{1};
        
        % generate outputfilename
        filnamOut   = ['TS' sprintf('%2.2d',tomo) '_' sprintf('%3.3d',tilt) '_A.mrc'];
        %filnamOutDW = ['TS_' sprintf('%2.2d',tomo) '_' sprintf('%3.3d',tilt) '_A_DW.mrc'];
        
        % read tilt angle
        tiltAngle = cell(41,1);
        tiltAngle{tilt+1,1} = filnamIn(10:end-4); % remove last 4 characters and first 10 characters
        
        % align, DW and bin movie (deactivate DW if already done later)
        [~ , cmdout] = motioncor2Wrapper(filnamIn, filnamOut, ...
            'DW', 0, ...
            'Patch',[5 5], ...
            'Iter',30, ...
            'bft',200, ...
            'Tol',0.5, ...
            'Kv',300, ...
            'PixSize',2.73, ...
            'FmDose',   fDose(i) * rd, ...
            'InitDose', tilt * fN(i) * fDose(i) * rd, ...
            'FtBin', 1 ...
            );
        disp(cmdout)
        
        % read aligned tilt and alignd DW tilt
        alignedFrame  = dread(filnamOut);
        %filteredFrame = dread(filnamOutDW);
        
        
        % DW the aligned tilt (deactivate if already done in motioncor2 previously)
        filteredFrame = applyExposureFilter(alignedFrame, fDose(i) * fN(i) * tilt, pxSize,'reduceFactor', rd);
        
        % where in new stack should tilt be placed
        idForNewStack = find(tiltTemplate==str2num(tiltAngle{tilt+1,1}));
        
        % place aligned frame in new stack
        newStack(:,:,idForNewStack)   = filteredFrame;
        newStackUW(:,:,idForNewStack) = alignedFrame;
        
        % delete aligned tilt
        delete(filnamOut);
        %delete(filnamOutDW);
        
        % status
        disp(['Done with tilt: ' num2str(tilt+1) '  from tomogram: ' num2str(tomo)])
    end
    
    % write new aligned AND dose weighted stack
    filnamStackOut = ['b001ts' sprintf('%3.3d',tomo) '.mrc'];
    dwrite(newStack,filnamStackOut);
    disp(['New File:   ' filnamStackOut ])
    
    % write new aligned only stack
    filnamStackOutUW = ['b001ts' sprintf('%3.3d',tomo) '_UW.mrc'];
    dwrite(newStackUW,filnamStackOutUW);
    disp(['New File:   ' filnamStackOutUW ])
    
    % write tilt angle file in our convention
    filnamTltOut = ['b001ts' sprintf('%3.3d',tomo) '.tlt'];
    dlmwrite(filnamTltOut,tiltTemplate,'\n')
    disp(['New File:   ' filnamTltOut ])
    
    disp(['Done with tomogram: ' num2str(tomo)])
end
