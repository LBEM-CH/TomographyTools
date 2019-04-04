% Motioncor2 wrapper (Stefano Scaramuzza 2018, stefano.scaramuzza@unibas.ch)
%
% This function runs motioncor2. The path to the motioncor2 executable on your computer has to be changed below.
% Everything else should not be changed.
%
% It requires motioncor2 (http://msg.ucsf.edu/em/software/motioncor2.html, Shawn Q. Zheng et al., 2016) and Dynamo installed (www.dynamo-em.org, Castaño-Díez et al., 2018).
%
%
% Input:
% - filename of input movie
% - filename of output movie
% - motioncor2 parameters
%
% Example:
% motioncor2Wrapper('TS_01_000_0.0.mrc','TS_01_000_0.0Corrected.mrc')
%
function [status, cmdout] = motioncor2Wrapper(movieInFilnam,movieOutFilnam, varargin)

% path to motioncor2 executable (change here)
mc2 = '/links/groups/cina/People/Stefano_Scaramuzza/programs/motionCor2/MotionCor2-1.1.0/MotionCor2_1.1.0-Cuda80';

% input parser
p = mbparse.ExtendedInput();
p.addParamValue('Patch',[5 5]);
p.addParamValue('Iter',30);
p.addParamValue('bft',200);
p.addParamValue('Tol',0.5);
p.addParamValue('Kv',300);
p.addParamValue('PixSize',0.675);
p.addParamValue('FmDose',0.3);
p.addParamValue('InitDose',0);
p.addParamValue('FtBin',2);
p.addParamValue('DW',1);
p.addParamValue('OutStack',0);
q = p.getParsedResults(varargin{:});

% input/output filenames
InMrc  = movieInFilnam;
OutMrc = movieOutFilnam;

%run bash script with DW
if q.DW == 1
    [status, cmdout] = system([ mc2 ' -InMrc '              InMrc ... 
                                    ' -OutMrc '             OutMrc ...
                                    ' -Patch '    num2str(q.Patch) ...
                                    ' -Iter '     num2str(q.Iter) ...
                                    ' -bft '      num2str(q.bft) ...
                                    ' -Tol '      num2str(q.Tol) ...
                                    ' -Kv '       num2str(q.Kv) ...
                                    ' -PixSize '  num2str(q.PixSize) ...
                                    ' -FmDose '   num2str(q.FmDose)...
                                    ' -InitDose ' num2str(q.InitDose)...
                                    ' -FtBin '    num2str(q.FtBin)]);
end

%run bash script without DW
if q.DW == 0
    [status, cmdout] = system([ mc2 ' -InMrc '              InMrc ... 
                                    ' -OutMrc '             OutMrc ...
                                    ' -Patch '    num2str(q.Patch) ...
                                    ' -Iter '     num2str(q.Iter) ...
                                    ' -bft '      num2str(q.bft) ...
                                    ' -Tol '      num2str(q.Tol) ...
                                    ' -OutStack ' num2str(q.OutStack) ...
                                    ' -FtBin '    num2str(q.FtBin)]);
end
end