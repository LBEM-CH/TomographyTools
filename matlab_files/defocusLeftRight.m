% This function estimates the defocus on the left and right side of images in tomographic tilt series (Stefano Scaramuzza, 2018, stefano.scaramuzza@unibas.ch)
%
% It requires Dynamo installed (www.dynamo-em.org, Castaño-Díez et al.,2018) and the function ctffind4Wrapper.m
%
% Important:
% Make sure that the tilt axis of your tilt series is more or less
% vertical through the center. If this is not the case, the function has to be
% run on the aligned stack.
% 
% Example:
% defocusLeftRight('b001ts054.ali','pixelsize',1.35)
%
function defocusLeftRight(stackFileName, varargin)

% input parser
p = mbparse.ExtendedInput();
p.addParamValue('pixelsize',1.35);  % in angstrom
p.addParamValue('just_plot',0);     % 1 if you only want to plot previously computed results
q = p.getParsedResults(varargin{:});
[~,stackname,~] = fileparts(stackFileName);

% copy .ali file to .mrc file (ctffind4 can only read .mrc)
disp(['Creating file: ' stackname '_ali_FULL.mrc'])
copyfile(stackFileName, [stackname '_ali_FULL.mrc'])


if q.just_plot == 0
    
    % read stack file
    orig = dread(stackFileName);
    
    % get dimesnions
    dimensions = size(orig);
    sidelength =dimensions(1);
    
    % define arbitrary gap through center
    gap = sidelength/12;
    
    % create left and right stack
    left  = orig(                       1 : round((sidelength/2-gap)),:,:);
    right = orig(round((sidelength/2+gap) : end)                     ,:,:);
    dwrite(left, [stackname '_LEFT.mrc' ])
    dwrite(right,[stackname '_RIGHT.mrc'])
    
    % run ctffind4 on full, left and right stack
    ctffind4Wrapper([stackname '_ali_FULL.mrc'] ,'pixelsize',q.pixelsize,'imsize',512)
    ctffind4Wrapper([stackname '_LEFT.mrc']     ,'pixelsize',q.pixelsize,'imsize',512)
    ctffind4Wrapper([stackname '_RIGHT.mrc']    ,'pixelsize',q.pixelsize,'imsize',512)
    
end % if just_plot == 0

% read ctffind4 results of full left and right stack
fidFull  = fopen([ stackname '_ali_FULL_diag.txt']);
fidLeft  = fopen([ stackname '_LEFT_diag.txt']);
fidRight = fopen([ stackname '_RIGHT_diag.txt']);

dataFull  = textscan(fidFull,  '%f %f %f %f %f %f %f', 'CommentStyle','#');
dataLeft  = textscan(fidLeft,  '%f %f %f %f %f %f %f', 'CommentStyle','#');
dataRigth = textscan(fidRight, '%f %f %f %f %f %f %f', 'CommentStyle','#');

dataFull  = cell2mat(dataFull);
dataLeft  = cell2mat(dataLeft);
dataRigth = cell2mat(dataRigth);

fclose(fidFull);
fclose(fidLeft);
fclose(fidRight);


% plot defocus of full left and right stack
figure;
hold on
plot(dataFull(:,1),(dataFull(:,2)/10 + dataFull(:,3)/10)/2)     % full  mean defocus
plot(dataLeft(:,1),(dataLeft(:,2)/10 + dataLeft(:,3)/10)/2)     % left  mean defocus
plot(dataRigth(:,1),(dataRigth(:,2)/10 + dataRigth(:,3)/10)/2)  % right mean defocus
xlabel('Tilt')
ylabel('Defocus [nm]')
ylim([0 6000])
title('50 to 5')
legend('Full','Left','Right')


end

