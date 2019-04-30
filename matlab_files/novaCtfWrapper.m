% Wrapper for novactf (Stefano Scaramuzza, 2018, stefano.scaramuzza at unibas.ch)
%
% This matlab function runs novactf.
%
% It requires novactf (https://github.com/turonova/novaCTF, Turoňová et al., 2017) and Dynamo installed (www.dynamo-em.org, Castaño-Díez et al., 2018).
% 
% The path to the novactf executable on your computer has to be changed below.
% Also, sometimes, the c++ standard library path has to be given to matlab. Change below if necessary.
% Everything else should not be changed.
%
% See the code below and the corresponding comments in case you want to do
% the CTF correction using phaseflip instead of multiplication. Same goes
% for the case where you want to use the imod defocus file instead of the
% ctffind4 defocus file.
%
%
% Make sure that all input files are of the format: <stackname>.<extension>
% For example, the tilt series number 89 of batch number 1 could have the 
% stack name 'b001ts089' and the corresponding input files would have to be:
%    b001ts089.ali
%    b001ts089.tlt
%    b001ts089_diag.txt
%
%
% All outputs are generated in the directory where this wrapper is run.
%
%
% Mandatory inputs and example values:
%    'stackname'   = 'b001ts089'       % batch/stack
%    'tsize'       = [3838 3710 1674]  % tomogram size (dimension), pixel x,y,z
%    'pixelsize'   = 0.1695            % nm/pixel
%    'defocusstep' = 15                % nm
%
% optional inputs are:
%    'shift'       = 0                 % in case a z shift has to be applied, default 0
%    'wsCTF'       = 12                % number of matlab workers for CTF correction, default 12, set to 0 if no parallel computing is supported
%    'wsFilt'      = 12                % number of matlab workers for filterin, default 12, set to 0 if no parallel computing is supported
%
%
% Example use of this wrapper:
% novaCtfWrapper('b001ts089', [3838 3710 1674], 0.1695, 15,'shift', 17)
%
%
% Files that need to be present:
%   - aligned stack from IMOD (<stackname>.ali)
%   - fefocus file in imod format (.defocus) or ctffind4 format (<stackname>_diag.txt)
%   - tilt angle file in imod format (<stackname>.tlt)
%
function novaCtfWrapper(stackname, tsize, pixelsize, defocusstep, varargin)

% Input parser
p = mbparse.ExtendedInput();
p.addParamValue('shift',0);     % in case a z shift has to be applied
p.addParamValue('wsCTF',12);    % number of matlab workers for CTF correction
p.addParamValue('wsFilt',12);   % number of matlab workers for filtering
q = p.getParsedResults(varargin{:});

% parse input
fullimage = tsize(1:2);
thickness = tsize(3);

%parallel computing
workers_in_pool_ctfcorr   = q.wsCTF;
workers_in_pool_filtering = q.wsFilt;


% path to novactf executable (change here if needed)
nova = '/home/stefasca/Downloads/novaCTF-master/novaCTF';

% set library path to c++ standard library in matlab if needed (change here if needed)
setenv('LD_LIBRARY_PATH',['/usr/lib/x86_64-linux-gnu:',getenv('LD_LIBRARY_PATH')]);
getenv('LD_LIBRARY_PATH')

% generate defocus files
fileID = fopen('setup_defocus.com','w');
fprintf(fileID,'# Command file to run novaCTF\n');
fprintf(fileID,'Algorithm defocus\n');
fprintf(fileID,['InputProjections ' stackname '.ali \n']);
fprintf(fileID,['FULLIMAGE ' num2str(fullimage) '\n']);
fprintf(fileID,['THICKNESS ' num2str(thickness) '\n']);
fprintf(fileID,['TILTFILE ' stackname '.tlt\n']);
fprintf(fileID,'SHIFT 0.0 0.0\n');
fprintf(fileID,'CorrectionType multiplication\n');        % or fprintf(fileID,'CorrectionType phaseflip\n');n
fprintf(fileID,'DefocusFileFormat ctffind4\n');           % or fprintf(fileID,'DefocusFileFormat ctffind4\n');
fprintf(fileID,['DefocusFile ' stackname '_diag.txt\n']); % or fprintf(fileID,['DefocusFile ' stackname '.defocus\n']);
fprintf(fileID,['PixelSize ' num2str(pixelsize) '\n']);
fprintf(fileID,['DefocusStep ' num2str(defocusstep) '\n']);
fprintf(fileID,'CorrectAstigmatism 1\n');
fprintf(fileID,'# DefocusShiftFile file_with_additional_defocus.txt\n');
fclose(fileID);
%
disp('start: setup_defocus.com')
system([nova ' -param setup_defocus.com']);
disp('done:  setup_defocus.com')

% get amount and id of defocus files
def_files = dir([ stackname '_diag.txt_*']);               % or def_files = dir([ stackname '.defocus_*']);
stacks = 0:length(def_files)-1;
if length(stacks) <= 0; error('no defocus files found'); end

% open parallel pool
parpool(workers_in_pool_ctfcorr);

% ctf correction on all stacks in parallel
parfor n = stacks
    % ctf correction
	fileID = fopen(['setup_ctfCorrection' num2str(n) '.com'],'w');
    fprintf(fileID,'# Command file to run novaCTF\n');
    fprintf(fileID,'Algorithm ctfCorrection\n');
    fprintf(fileID,['InputProjections ' stackname '.ali\n']);
    fprintf(fileID,['DefocusFile ' stackname '_diag.txt_' num2str(n) '\n']);	% or fprintf(fileID,['DefocusFile ' stackname '.defocus_' num2str(n) '\n']);
    fprintf(fileID,['OutputFile corrected_' stackname '.ali_' num2str(n) '\n']);
    fprintf(fileID,['TILTFILE ' stackname '.tlt\n']); 
    fprintf(fileID,'CorrectionType multiplication\n');
    fprintf(fileID,'DefocusFileFormat ctffind4\n');                             % or fprintf(fileID,'DefocusFileFormat imod\n');
    fprintf(fileID,['PixelSize ' num2str(pixelsize) '\n']);
    fprintf(fileID,'AmplitudeContrast 0.07\n');
    fprintf(fileID,'Cs 2.7\n');
    fprintf(fileID,'Volt 300\n');
    fprintf(fileID,'CorrectAstigmatism 1\n');
    fclose(fileID);
    %
    disp(['start: setup_ctfCorrection' num2str(n) '.com'])
    system([nova ' -param setup_ctfCorrection' num2str(n) '.com']);
    disp(['done:  setup_ctfCorrection' num2str(n) '.com'])
end

% delete pool
delete(gcp('nocreate'))


% flipping all stacks in serial
for n = stacks
    % flipping stacks
    disp(['start: clip flipyz corrected_' stackname '.ali_' num2str(n)])
    system(['clip flipyz corrected_' stackname '.ali_' num2str(n) ' corrected_flipped_' stackname '.ali_' num2str(n)]);
    disp(['done:  clip flipyz corrected_' stackname '.ali_' num2str(n)])
end


% open parallel pool
parpool(workers_in_pool_filtering);

% filtering of all stacks in parallel
parfor n = stacks
    % filtering
    fileID = fopen(['setup_filter' num2str(n) '.com'],'w');
    fprintf(fileID,'# Command file to run novaCTF\n');
    fprintf(fileID,'Algorithm filterProjections\n');
    fprintf(fileID,['InputProjections corrected_flipped_' stackname '.ali_' num2str(n) '\n']);
    fprintf(fileID,['OutputFile filtered_' stackname '.ali_' num2str(n) '\n']);
    fprintf(fileID,['TILTFILE ' stackname '.tlt\n']);
    fprintf(fileID,'StackOrientation xz\n');
    fprintf(fileID,'# RADIAL 0.3 0.05\n');
    fclose(fileID);
    %
    disp(['start: setup_filter' num2str(n) '.com'])
    system([nova ' -param setup_filter' num2str(n) '.com']);
    disp(['done:  setup_filter' num2str(n) '.com'])
end

% delete pool
delete(gcp('nocreate'))

% reconstruction
fileID = fopen('setup_reconstruction.com','w');
fprintf(fileID,'# Command file to run novaCTF\n');
fprintf(fileID,'Algorithm 3dctf\n');
fprintf(fileID,['InputProjections filtered_' stackname '.ali\n']);
fprintf(fileID,['OutputFile ' stackname '_full_not_flipped.rec  \n']);
fprintf(fileID,['TILTFILE ' stackname '.tlt\n']);
fprintf(fileID,['THICKNESS ' num2str(thickness) '\n']);
fprintf(fileID,['FULLIMAGE ' num2str(fullimage) '\n']);
%fprintf(fileID,'SHIFT 0.0 0.0\n');
fprintf(fileID,['SHIFT 0.0 ' num2str(q.shift) '\n']);
fprintf(fileID,['PixelSize ' num2str(pixelsize) '\n']);
fprintf(fileID,['DefocusStep ' num2str(defocusstep) '\n']);
fprintf(fileID,'Use3DCTF 1\n');
fclose(fileID);
%
disp('start: setup_reconstruction.com')
system([nova ' -param setup_reconstruction.com']);
disp('done : setup_reconstruction.com')

% flipping tomogram (with imod command "clip"
disp(['start: clip flipyz ' stackname '_full_not_flipped.rec ' stackname '.rec'])
system(['clip flipyz ' stackname '_full_not_flipped.rec ' stackname '.rec']);
disp(['done:  clip flipyz ' stackname '_full_not_flipped.rec ' stackname '.rec'])


% delete temporary files (everything not directly needed by reconstruction)
disp('start: deleting intermediate files')
for n = stacks
    system(['rm ' 'setup_ctfCorrection' num2str(n) '.com']);
    system(['rm ' stackname '_diag.txt_' num2str(n)]);
    system(['rm ' 'corrected_' stackname '.ali_' num2str(n)]);
    system(['rm ' 'filtered_' stackname '.ali_' num2str(n)]);
    system(['rm ' 'corrected_flipped_' stackname '.ali_' num2str(n)]);
    system(['rm ' 'setup_filter' num2str(n) '.com']);
end
disp('done:  deleting intermediate files')
disp('done:  everything')

end
