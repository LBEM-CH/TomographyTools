% This function applies an exposure filter (dose weighting) to a single tilt. (Stefano Scaramuzza, 2018, stefano.scaramuzza@unibas.ch)
%
% Don’t change anything here.
% It requires Dynamo installed (www.dynamo-em.org, Castaño-Díez et al., 2018).
%
% Input:
% - micrograph
% - pixelsize in angstrom
% - accumulated dose in e/a
% - optional factor to reduce actual dose
%
% Output:
% - filtered tilt
% - filter itself
%
% Example on full tilt series:
%     t = [21 22 19 23 18 24 17 25 16 26 15 27 14 28 13 29 12 30 11 31 10 32 9 33 8 34 7 35 6 36 5 37 4 38 3 39 2 40 1 41];
%     uws = dread('b001ts032.mrc');
%     accumulatedDose=0;
%     for i = t
%       accumulatedDose = accumulatedDose + 2.5;
%       dws(:,:,i) = applyExposureFilter(uws(:,:,i),accumulatedDose, 1.7)
%     end
%     dwrite(dws,'b001ts032_DW.mrc')
%
%
function [filteredTilt, FILT]= applyExposureFilter(tilt,accumulatedDose, apix, varargin)

% input parser
p = mbparse.ExtendedInput();
p.addParamValue('reduceFactor',1);
q = p.getParsedResults(varargin{:});

% get sidelengths of micrograph
[x, y]= size(tilt);

% reduce dose by arbitrary factor
accumulatedDose = accumulatedDose * q.reduceFactor;

% calculate distnace for each pixel from center of micrograph in fourier space
cent    = [floor(x./2)+1, floor(y./2)+1];               % center
Dp = sqrt(([1:x].'-cent(1)).^2 + ([1:y]-cent(2)).^ 2);	% distance in pixel
Da = Dp./(x.*apix);                                     % distance in 'inverse angstrom'

% create the filter with formula (5) from unblur paper (Grant & Grigorieff, elife 2015)
a =  0.245; b = -1.665; c =  2.81;      % parameters from paper
Ne   = a.*(Da.^b)+c;                    % Ne described by formula (3)
FILT  = exp(-accumulatedDose./(2.*Ne));	% q described by formula (5)

% apply filter
FILTEREDTILT = fftshift(fft2(tilt)) .* FILT;            % fourier
filteredTilt = real(ifft2(ifftshift(FILTEREDTILT)));    % real

end




