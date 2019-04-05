% Ctffind4 4.1.4 wrapper (Stefano Scaramuzza, 2018, stefano.scaramuzza at unibas.ch)
%
% This is a matlab function that runs Ctffind4. The path to the Ctffind4 executable on your computer has to be changed below.
% Everything else should not be changed.
% It requires Ctffind4 (http://grigoriefflab.janelia.org/ctffind4, Rohou et al., 2015) and Dynamo installed (www.dynamo-em.org, Castaño-Díez et al., 2018).
%
% New: Option to crop the stack prior to estimating the defocus.
%
% Note: Some ctffind4 parameters are hard coded (see below).
%
% Input
% - stack as .mrc file
% - ctffind4 parameters
%
% Example without cropping:
%   ctffind4Wrapper('b001ts089.mrc', 'pixelsize', 2.7)
%
% Example with cropping:
%   ctffind4Wrapper('b001ts022_UW.mrc','pixelsize',2.73,'crop',1,'tltFileName','b001ts022.tlt')
%
% Units:
% - angstrom, rad
%
function ctffind4Wrapper(stackFileName,varargin)

% input parser
p = mbparse.ExtendedInput();
p.addParamValue('volt',300);
p.addParamValue('pixelsize',2.73);
p.addParamValue('minres',50.0);
p.addParamValue('maxres',10.0);
p.addParamValue('mindef',10000.0);
p.addParamValue('maxdef',60000.0);
p.addParamValue('defstep',100.0);
p.addParamValue('imsize',512);

% New options for cropping:
p.addParamValue('crop',0);              % 0 = No cropping, 1 = Crop away on each tilt the "new area" that comes into view due to tilting
p.addParamValue('tltFileName','');      % .tlt filename used to compute the "new area".
p.addParamValue('border',128);          % Additional border around images to remove (in pixels). This border is also adapted depending on the tilt angle.
p.addParamValue('thickness',2000);      % thickness of ice (in angstrom). Used to crop away the extra area that comes into view when tilting due to the thickness of the sample.
p.addParamValue('tltAxisDirection',0);  % 0 = horizontal tilt axis, 1 = vertical tilt axis
p.addParamValue('recompute',1);         % Set this to 0 if you already have a cropped stack (or another stack) and just want to test different ctffind4 parameters
p.addParamValue('skipCtffind',0);       % Set this to 1 if you want to skip ctffind4 and just want to test cropping parameters

q = p.getParsedResults(varargin{:});

% get stackname
[~,stackname,~] = fileparts(stackFileName);


% create a new stack with cropped tilts around tilt axis
if q.crop == 1
    
    % new filename
    cropStackFileName = [stackname '_Crop.mrc'];
    
    disp(['Use/create cropped stack for defocus estimation: ' cropStackFileName])
    
    
    if q.recompute == 1
        
        
        % check tilt file
        if strcmp(q.tltFileName,''); error('Filename of .tlt file must given as input.');  end
        if ~isfile(q.tltFileName); error(['The file: ' q.tltFileName ' does not exist.']); end
        
        % read stack and get dimensions
        stack = dread(stackFileName);
        [xs,ys,zs] = size(stack);
        
        % read tilt file and get dimensions
        tlt  = dread(q.tltFileName);
        zt   = length(tlt);
        
        % check that inputs are correct
        if zs ~= zt; error('Number of tilt angles in .tlt file not equal to number of tilts in stack.'); end
        
        
        %initiate empty stack
        stack_crop = ones(xs,ys,zs);
        
        
        % create new cropped stack in case of vertical tilt axis (not finished)
        if q.tltAxisDirection == 1
            disp('Vertical tilt axis')
            for i = 1:zs
                disp(['Cropping tilt: ' num2str(i)])
                
                % estimating length "extra sample" coming into image during tilt
                extra = abs(sind(tlt(i)) * (q.thickness / q.pixelsize));
                
                % calculating new length of tomogram. Border is set for tilt zero and is then also affected by tilting
                new_length = cosd(tlt(i)) * (xs - q.border*2) - extra;
                center = xs/2;
                xsCrop_min = round(center - new_length/2);
                xsCrop_max = round(center + new_length/2);
                
                if xsCrop_min <= 0;  xsCrop_min = 1;  end
                if xsCrop_max >= xs; xsCrop_max = xs; end
                
                ysCrop_min = 1  + q.border;
                ysCrop_max = ys - q.border;
                
                stack_crop(:,:,i) = stack_crop(:,:,i) * mean(mean(stack(ysCrop_min : ysCrop_max,xsCrop_min : xsCrop_max,i)));
                stack_crop(xsCrop_min : xsCrop_max, ysCrop_min : ysCrop_max,i) = stack(xsCrop_min : xsCrop_max,ysCrop_min : ysCrop_max,i);
                
            end
        end
        
        
        % create new cropped stack in case of horizontal tilt axis
        if q.tltAxisDirection == 0
            disp('Horizontal tilt axis')
            for i = 1:zs
                disp(['Cropping tilt: ' num2str(i)])
                
                % estimating length "extra sample" coming into image during tilt
                extra = abs(sind(tlt(i)) * (q.thickness / q.pixelsize));
                
                % calculating new length of tomogram. Border is set for tilt zero and is then also affected by tilting
                new_length = cosd(tlt(i)) * (ys - q.border*2) - extra;
                center = ys/2;
                ysCrop_min = round(center - new_length/2);
                ysCrop_max = round(center + new_length/2);
                
                if ysCrop_min <= 0;  ysCrop_min = 1;  end
                if ysCrop_max >= ys; ysCrop_max = ys; end
                
                xsCrop_min = 1  + q.border;
                xsCrop_max = xs - q.border;
                
                stack_crop(:,:,i) = stack_crop(:,:,i) * mean(mean(stack(xsCrop_min : xsCrop_max,ysCrop_min : ysCrop_max,i)));
                stack_crop(xsCrop_min : xsCrop_max,ysCrop_min : ysCrop_max,i) = stack(xsCrop_min : xsCrop_max,ysCrop_min : ysCrop_max,i);
                
            end
        end
        
        % save new stack
        disp(['Saving new cropped stack: ' cropStackFileName])
        dwrite(stack_crop, cropStackFileName)
        disp('Done saving')
    end
    
    % update filenames for ctffind run
    stackFileName = cropStackFileName;
    [~,stackname,~] = fileparts(stackFileName);
    
end

if q.skipCtffind == 0
    disp('Run ctffind4:')
    
    % generate input/output filenames
    inputfile  = stackFileName;
    outputfile = [stackname '_diag.mrc'];
    
    % generate bash script
    fileID = fopen('ctffind4_run.sh','w');
    fprintf(fileID,'#!/bin/bash\n');
    fprintf(fileID,'# run ctffind4\n');
    fprintf(fileID,'/usr/local/cina/ctffind/ctffind-4.1.4/ctffind <<EOF\n');    % path to ctffind4 installation (adapt if necessary)
    fprintf(fileID,[inputfile '\n']);
    fprintf(fileID,'no\n');
    fprintf(fileID,[outputfile '\n']);
    fprintf(fileID,[num2str(q.pixelsize) '\n']);
    fprintf(fileID,[num2str(q.volt)  '\n']);
    fprintf(fileID,'2.7\n');
    fprintf(fileID,'0.1\n');
    fprintf(fileID,[num2str(q.imsize)  '\n']);
    fprintf(fileID,[num2str(q.minres)  '\n']);
    fprintf(fileID,[num2str(q.maxres)  '\n']);
    fprintf(fileID,[num2str(q.mindef)  '\n']);
    fprintf(fileID,[num2str(q.maxdef)  '\n']);
    fprintf(fileID,[num2str(q.defstep) '\n']);
    fprintf(fileID,'no\n');
    fprintf(fileID,'no\n');
    fprintf(fileID,'yes\n');
    fprintf(fileID,'300\n');
    fprintf(fileID,'no\n');
    fprintf(fileID,'no\n');
    fprintf(fileID,'EOF\n');
    fprintf(fileID,'done\n');
    fclose(fileID);
    
    % run bash script
    system('bash ctffind4_run.sh')
end

end