% This script builds and saves a MATLAB structure with all relevant information
% from the HDF5 files downloaded in Step 01 and plots the approximate ice-
% shelf front location for each ground track profile over the mask from Depoorter 
% et al. (2013). The user should specify the location of (1) the HDF5 files
% with the variable 'data_dir,' which should match the path specified at the 
% end of the Step 01 Jupyter Notebook, and (2) the location of the *.mat file 
% containing the Depoorter et al. (2013) mask data.
%
% This script implements part of Step (i) described in Subsection 2.3 of 
% Becker et al. (2021).
%
% NOTE: This script calls the Antarctic Mapping Tools 'll2ps' function
% (Greene et al., 2017), which can be downloaded from the MathWorks File
% Exchange:
% https://www.mathworks.com/matlabcentral/fileexchange/47638-antarctic-mapping-tools.
%
% Susan L. Howard, Earth and Space Research, showard@esr.org
% Maya K. Becker, Scripps Institution of Oceanography, mayakbecker@gmail.com
%
% Last updated April 16, 2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Begin user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

work_path = pwd;
out_filename = 'ross_files.mat';   % output filename
data_dir = 'D:\ICESat2\ross_data_download\'; % change to match the path 
                                             % specified at the end of 
                                             % the Step 01 Jupyter Notebook
                                           
load 'Depoorter_et_al_2013_mask.mat'; % load mask from Depoorter et al. (2013)
                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                  
                  
cd(data_dir)
all_files = dir('*.h5');
number_of_files = length(all_files);

% Create variables for the approximate front locations in the ground track
% profiles. For each front crossing, we keep track of the x and y locations 
% on either side of the crossing (determined by the change in mask value
% from ocean to ice shelf, described below).

front_x = zeros(number_of_files,6,2);
front_y = zeros(number_of_files,6,2);
front_x(:,:,:) = NaN;
front_y(:,:,:) = NaN;

cd(work_path)

beams = ['1r'; '1l'; '2r'; '2l'; '3r'; '3l'];

% Plot the Depoorter et al. (2013) mask as a basemap. Mask values are as
% follows: 0 = ocean, 1 = land and grounded ice, and 2 = ice shelf.

[SM.X,SM.Y] = meshgrid(SM.x,SM.y);

pcolor(SM.x(1:5:end,1:5:end),SM.y(1:5:end,1:5:end),SM.mask(1:5:end,1:5:end))
shading flat
colorbar
axis('equal')
axis([-700 550 -1550 -1075])
hold on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the relevant variables from each beam of each ATL06 file, check for 
% a front crossing based on the mask, and store the variables in the structure
% 'ross_files'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ross_files = struct;
structure_entry = 0;

for i = 1:number_of_files
    
    % Loop through all six beams of each file, pulling all relevant
    % variables--refer to ATL06 data dictionary for variable/attribute
    % description: 
    % https://nsidc.org/sites/nsidc.org/files/technical-references/ATL06-data-dictionary-v001.pdf
    
    for j = 1:length(beams)
        
        try
            
            lat = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/latitude']);
            lon = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/longitude']);
            h_li = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/h_li']);
            quality_summary_flag = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/atl06_quality_summary']);
            delta_time = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/delta_time']);
            geoid_h = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/dem/geoid_h']);
            tide_ocean = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/geophysical/tide_ocean']);
            dac = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/geophysical/dac']);
            cloud_flag_asr = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/geophysical/cloud_flg_asr']);
            cloud_flag_atm = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/geophysical/cloud_flg_atm']);
            dem_h = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/dem/dem_h']);
            dem_flag = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/dem/dem_flag']);           
            sc_orient = h5read([data_dir '/' all_files(i).name], '/orbit_info/sc_orient'); 
                % spacecraft orientation parameter values: ['0', '1', '2']; value meanings: ['backward', 'forward', 'transition']
            x_atc = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/ground_track/x_atc']);
            y_atc = h5read([data_dir '/' all_files(i).name], ['/gt' beams(j,:) '/land_ice_segments/ground_track/y_atc']);
            product = all_files(i).name(11:15);
            track = all_files(i).name(32:35);
            cycle = all_files(i).name(36:37);
            region = all_files(i).name(38:39);
            
            % Determine the beam type, i.e., whether it is strong or weak,
            % using the value of 'sc_orient'
            
            if sc_orient == 1
                
                if beams(j,2) == 'r'
                    beam_type = 'strong';
                elseif beams(j,2) == 'l'
                    beam_type = 'weak';
                else
                    disp('something is wrong')
                end
                
            elseif sc_orient == 0
                
                if beams(j,2) == 'r'
                    beam_type = 'weak';
                elseif beams(j,2) == 'l'
                    beam_type = 'strong';
                else
                    disp('something is wrong')
                end
                
            else
                
                disp('sc orient = 2')
                beam_type = 'Transition';
                
            end
            
            % Convert latitude and longitude coordinates to polar stereographic
            % map coordinates using the 'll2ps' function (Greene et al., 2017)
            
            [x,y] = ll2ps(lat,lon);
            
            % Interpolate the Depoorter et al. (2013) mask values (with
            % their corresponding locations converted to m) at the (x,y) 
            % values
            
            SM_x_m = SM.x * 1000;
            SM_y_m = SM.y * 1000;
            
            mask_interp = interp2(SM_x_m,SM_y_m,SM.mask,x,y,'nearest');
            [a,b] = size(mask_interp);
            
            % Set the ellipsoidal height data ('h_li' in the ATL06 data 
            % dictionary and here) values greater than 3e38, and their
            % corresponding locations, to NaN
            
            nan_idx = find(h_li > 3.e+38);
            
            h_li(nan_idx) = NaN;
            x_N = x;
            y_N = y;
            x_N(nan_idx) = NaN;
            y_N(nan_idx) = NaN;
            
            % Loop through the interpolated mask values, calculating the
            % difference between each value and the next. A difference value
            % greater than 1 denotes an ice-shelf front crossing (because
            % the ocean mask value is 0 and the ice-shelf mask value is 2); 
            % there should only be one ice-shelf front crossing per 
            % beam/ground track profile. Only information from beams that
            % show a transition from ice shelf to ocean is included in the
            % structure.
            
            for k = 1:a-1
                
                diff = abs(mask_interp(k) - mask_interp(k + 1));
                
                if diff > 1
                    
                    % Print the file and beam number
                    
                    disp(['file ' num2str(i) ' beam ' num2str(j)])
                    
                    structure_entry = structure_entry + 1;
                    
                    % Determine if the track node is ascending or descending
                    
                    direction_check = lat(2) - lat(1);
                    
                    if direction_check > 0
                        direction = 'A'; % ascending
                    else
                        direction = 'D'; % descending
                    end
                    
                    ross_files(structure_entry).mask = mask_interp;
                    ross_files(structure_entry).h_li = h_li;
                    ross_files(structure_entry).geoid_h = geoid_h;
                    ross_files(structure_entry).tide_ocean = tide_ocean;
                    ross_files(structure_entry).dac = dac;
                    ross_files(structure_entry).cloud_flag_asr = cloud_flag_asr;
                    ross_files(structure_entry).cloud_flag_atm = cloud_flag_atm;
                    ross_files(structure_entry).dem_h = dem_h;
                    ross_files(structure_entry).dem_flag = dem_flag;
                    ross_files(structure_entry).x = x;
                    ross_files(structure_entry).y = y;
                    ross_files(structure_entry).lat = lat;
                    ross_files(structure_entry).lon = lon;
                    ross_files(structure_entry).x_N = x_N;
                    ross_files(structure_entry).y_N = y_N;
                    ross_files(structure_entry).beam = ['gt' beams(j,:)];
                    ross_files(structure_entry).file = all_files(i).name;
                    ross_files(structure_entry).m_loc_x = x(k);
                    ross_files(structure_entry).m_loc_xp1 = x(k+1);
                    ross_files(structure_entry).m_loc_y = y(k);
                    ross_files(structure_entry).m_loc_yp1 = y(k+1);
                    ross_files(structure_entry).quality_summary_flag = quality_summary_flag;
                    ross_files(structure_entry).delta_time = delta_time;
                    ross_files(structure_entry).sc_orient = sc_orient;
                    ross_files(structure_entry).x_atc = x_atc;
                    ross_files(structure_entry).y_atc = y_atc;
                    ross_files(structure_entry).cycle = cycle;
                    ross_files(structure_entry).region = region;
                    ross_files(structure_entry).track = track;
                    ross_files(structure_entry).product = product;
                    ross_files(structure_entry).direction = direction;
                    ross_files(structure_entry).beam_type = beam_type;
                    
                    front_x(i,j,1) = x(k);
                    front_x(i,j,2) = x(k + 1);
                    front_y(i,j,1) = y(k);
                    front_y(i,j,2) = y(k + 1);
                    
                    break
                    
                end
                
            end
            
            % Plot the location of the beam data, as well as the location
            % of the front crossing and the point just after the front
            % crossing, over the Depoorter et al. (2013) mask basemap
            
            plot(x/1000,y/1000,'.r')
            plot(squeeze(front_x(i,j,1)/1000),squeeze(front_y(i,j,1)/1000),'*g')
            plot(squeeze(front_x(i,j,2)/1000),squeeze(front_y(i,j,2)/1000),'*c')
            hold on
        
        % If the beam/ground track profile shows no ice-shelf front crossing, 
        % print that there are no usable data (for our purposes)
            
        catch
            
            disp(['no data beam: gt' beams(j,:)])
            
        end
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gt_count = structure_entry;

% Save final 'ross_files' structure and other relevant parameters to a
% *.mat file

save(out_filename, '-v7.3', 'ross_files', 'gt_count', 'front_y', 'front_x')
