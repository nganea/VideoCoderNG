function [movieName, movieJName] = vCoder_LoadMov(movieExt_in, moviePath_in) 
%
%This function loads the movie requested by the user, or it uses a default
%movie.
%
%  ========================
% Created by Natasa Ganea, Goldsmiths InfantLab, Jul 2019 (natasa.ganea@gmail.com)
%
% Copyright © 2019 Natasa Ganea. All Rights Reserved.
% ========================

% if no movie extension given, use .mp4
if nargin < 1 || isempty(movieExt_in)
    movieExt = '.mp4';
else
    movieExt = movieExt_in;
end

% if no moviePath given, use default
if nargin < 2 || isempty(moviePath_in)
    if ismac || ispc
        moviePath = fulfile(pwd, 'movies');
    else
        disp('Platform not supported')
    end
else
    moviePath = moviePath_in;
end


%load movies - 4 movie______________________________________________________________________________
path = moviePath;
DD = dir(path);
DDlength = 0;
for i = 1:length(DD)
    if ~strcmp(DD(i).name(1),'.')    
        DDlength = DDlength + 1;     
    end
end
count = 1;
movieName = cell(1, DDlength);    % store full name of the movie file
movieJName = cell(1, DDlength);   % store abbreviated name of the movie
for j=1:length(DD)
    largename = DD(j).name;
    [~, name, ext] = fileparts([path largename] );
    if strcmp(ext, movieExt) && ~strcmp(largename(1),'.')
        movieFil = fullfile(path,largename);
        %store_name
        movieName{count} = movieFil;              %movie name full path
        movieJName{count} = name(7:length(name)); %movie name abreviated
        count = count+1;
    end
end
%movieNum = length(movieName);

