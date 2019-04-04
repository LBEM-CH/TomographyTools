% Plot the ctffind4 (http://grigoriefflab.janelia.org/ctffind4, Rohou et
% al., 2015) output diagnostic file (with the ending '_diag.txt') (Stefano Scaramuzza, 2018, stefano.scaramuzza@unibas.ch)
%
% Example:
% plot_ctffindFile('b001ts022_UW_Crop_diag.txt')
%
function meanDefTot = plot_ctffindFile(filnam)

fid = fopen(filnam);
data = textscan(fid, '%f %f %f %f %f %f %f', 'CommentStyle','#');
data = cell2mat(data);
fclose(fid);

meanDef    = (data(:,2)/10 + data(:,3)/10) / 2;
meanDefTot = mean(meanDef);

figure;
hold on
plot(data(:,1),data(:,2)/10)
plot(data(:,1),data(:,3)/10)
plot(data(:,1),(data(:,2)/10 + data(:,3)/10)/2)

xlabel('Tilt')
ylabel('Defocus [nm]')
ylim([1000 6000])
title(filnam)
legend('d1','d2','average')

end

