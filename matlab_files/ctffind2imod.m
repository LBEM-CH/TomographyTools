% This function transform ctffind4 txt output to imod compatible defocus file (Stefano Scaramuzza, 2018, stefano.scaramuzza at unibas.ch)
%
% Don’t change anything here.
% It requires Dynamo installed (www.dynamo-em.org, Castaño-Díez et al., 2018).
%
% Input:
%   ctffind4 diagnostic txt file
%   .tlt file
%
% Output:
%   .defocus imod file
%
% Example:
%   ctffind2imod('b001ts089_diag.txt','b001ts089.tlt','b001ts089.defocus')
%
function ctffind2imod(cfilnam, tfilnam, dfilnam)

% read ctffind file
cfilnamID = fopen(cfilnam);
ctffile = textscan(cfilnamID,'%f %f %f %f %f %f %f','CommentStyle','#'); % read file
fclose(cfilnamID);

% read .tlt file
tfilnamID = fopen(tfilnam);
tfile = textscan(tfilnamID,'%f','CommentStyle','#'); % read file
fclose(tfilnamID);

% make header
header = '1  0 0. 0. 0  3';

% get tilt number in column 1 and 2 (integer)
dfile(:,1) = ctffile{1,1};
dfile(:,2) = ctffile{1,1};

% get tilt angle plus/minus half the angle in column 3 and 4 (2 stellen anch komma)
dfile(:,3)   = tfile{1,1}   - 0.5;
dfile(:,4)   = tfile{1,1}   + 0.5;
dfile(1,3)   = dfile(1,3)   + 0.5;
dfile(end,4) = dfile(end,4) - 0.5;

% get smaller defocus angstrom to nano (divided by 10 and digit int)
dfile(:,5) = ctffile{1,3} / 10;

% get larger defocus angstrom to nano (divided by 10 and digit int)
dfile(:,6) = ctffile{1,2} / 10;

% get azimuth of astigmatism (1 nachkommastelle) plus 90 degrees (different convention)
dfile(:,7) = ctffile{1,4} + 90;

% write defocus file
formatSpec = '%d\t%d\t%.2f\t%6.2f\t%.0f\t%.0f\t%0.1f\n';
fileID = fopen(dfilnam,'w');
fprintf(fileID,'%15s\n',header);
fprintf(fileID,formatSpec,dfile');
fclose(fileID);

end

