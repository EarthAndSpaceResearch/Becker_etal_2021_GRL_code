% This script cleans up the structure from Step 02; applies various
% filters, flags, and geophysical corrections; and removes outliers. Then,
% for each ground track profile, it searches for the ice-shelf front moving
% from the ocean to the ice shelf; if the front is found, the script gathers
% various data on the front crossing.
%
% This script implements part of Step (i) and steps (ii)-(iv) described in 
% Subsection 2.3 of Becker et al. (2021). This text also describes choices 
% for cleaning up the data, specifically assessed for Ross Ice Shelf.    
%
% Susan L. Howard, Earth and Space Research, showard@esr.org
% Maya K. Becker, Scripps Institution of Oceanography, mayakbecker@gmail.com
%
% Last updated April 16, 2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Begin user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load 'ross_files.mat' % *.mat file created in Step 02

out_filename = 'ross_front_crossing_data.mat'; % output filename

ref_time = datenum(2018,01,01); % reference time for all ground track profiles

mdt = -1.4; % constant value to use for the MDT  correction

h_ss_low = -5;   % lowest allowable instantaneous sea surface (h_ss) value 
h_ss_high = 100; % highest allowable h_ss value

% Set various criteria that a ground track profile jump must satisfy in 
% order to be classified as representing the ice front by the
% front-detection algorithm

h_a_upper_limit = 2;          % upper limit of the height of the ocean 
                              % point in the front jump
                              
h_diff_lower_limit = 10;      % lower limit of the height increase that
                              % constitutes a front jump
                              
h_diff_upper_limit = 100;     % upper limit of the height increase that 
                              % constitutes a front jump 
                              
jump_x_dist_upper_limit = 80; % upper limit of the along-track distance over
                              % which a front jump could occur
                                                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up the structure and apply geophysical corrections to the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clean up the structure from Step 02. Looping through each structure entry/
% ground track profile, first set the h_li values to NaN for segments for 
% which the interpolated Depoorter et al. (2013) mask values indicate that 
% they occur over grounded ice, and then do the same for segments for which 
% the quality summary parameter ('atl06_quality_summary' in the ATL06 data 
% dictionary) values indicate data-quality issues.

ross_files_clean = ross_files;

for i = 1:gt_count
    
    grounded_ice_inds = find(ross_files_clean(i).mask == 1);
        % mask value of 1 indicates grounded ice
    ross_files_clean(i).h_li(grounded_ice_inds) = NaN;
    
    bad_quality_inds = find(ross_files_clean(i).quality_summary_flag == 1); 
        % parameter value of 1 indicates some potential data-quality problem
    ross_files_clean(i).h_li(bad_quality_inds) = NaN;
    
end

% Convert all h_li values to height relative to the instantaneous sea 
% surface (h_ss) by referencing them to the EGM2008 geoid and correcting for 
% ocean tides, inverted barometer effects (IBE), and mean dynamic topography 
% (MDT). Obtain values for the geoid height and ocean tides and IBE corrections 
% from the ATL06 product itself; apply a constant value for the MDT
% correction (which was set in the user input section).

for i = 1:gt_count
    
    ross_files_clean(i).h_ss = ross_files_clean(i).h_li - ... 
        ross_files_clean(i).geoid_h - ... 
        ross_files_clean(i).tide_ocean - ... 
        ross_files_clean(i).dac - mdt; % 'dac' = MOG2D dynamic atmosphere correction (DAC) for IBE
    
end

% For each ground track profile, remove outliers of h_ss (the limits for 
% which were set in the user input section), and generate a new variable, 
% 'x_dist,' which gives the difference in along-track x-coordinate between 
% the first ATL06 segment and each successive segment

for i = 1:gt_count
    
    low_h_ss_inds = find(ross_files_clean(i).h_ss < h_ss_low);
    ross_files_clean(i).h_ss(low_h_ss_inds) = NaN;
    
    high_h_ss_inds = find(ross_files_clean(i).h_ss > h_ss_high);
    ross_files_clean(i).h_ss(high_h_ss_inds) = NaN;
    
    ross_files_clean(i).x_dist = ross_files_clean(i).x_atc - ... 
        ross_files_clean(i).x_atc(1);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a new structure, 'ross_front_crossing_data,' for the ice-front 
% crossings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create a new structure that expands upon the cleaned-up version of the
% structure from Step 02 to include information about the ice-front
% crossing in each ground track profile. Mark all variables relating to the
% ocean point in the front jump with an 'a' and all variables relating to
% the ice-shelf point in the front jump with a 'b.' Set all variables
% associated with the front crossing to NaN; these variables will be
% populated later on in this script.

ross_front_crossing_data = ross_files_clean;

for i = 1:gt_count
    
    ross_front_crossing_data(i).found = 0; % 0 = front not found; 1 = front found
    ross_front_crossing_data(i).h_a = NaN;
    ross_front_crossing_data(i).h_b = NaN;
    ross_front_crossing_data(i).h_diff = NaN;
    ross_front_crossing_data(i).index_a = NaN;
    ross_front_crossing_data(i).index_b = NaN;
    ross_front_crossing_data(i).x_gap = NaN;
    ross_front_crossing_data(i).x_dist_a = NaN;
    ross_front_crossing_data(i).x_dist_b = NaN;
    ross_front_crossing_data(i).x_atc_a = NaN;
    ross_front_crossing_data(i).x_atc_b = NaN;
    ross_front_crossing_data(i).lat_a = NaN;
    ross_front_crossing_data(i).lat_b = NaN;
    ross_front_crossing_data(i).lon_a = NaN;
    ross_front_crossing_data(i).lon_b = NaN;
    ross_front_crossing_data(i).x_a = NaN;
    ross_front_crossing_data(i).x_b = NaN;
    ross_front_crossing_data(i).y_a = NaN;
    ross_front_crossing_data(i).y_b = NaN;    
    ross_front_crossing_data(i).delta_time_a = NaN;
    ross_front_crossing_data(i).delta_time_b = NaN;
    ross_front_crossing_data(i).time_a = NaN;
    ross_front_crossing_data(i).time_b = NaN;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run the front-detection algorithm for each ground track profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:gt_count
    
    disp(i)
    
    % In order to accurately calculate the along-track distance between the 
    % ocean and ice-shelf points in a would-be front jump, get rid of NaNs 
    % but keep track of non-NaN indices
    
    gt_x_inds = [1:length(ross_files(i).x)];
    non_NaN_inds = find(~isnan(ross_files_clean(i).h_ss));
    h_ss_non_NaN_inds = ross_files_clean(i).h_ss(non_NaN_inds);
    gt_x_non_NaN_inds = gt_x_inds(non_NaN_inds);
    [c,d] = size(h_ss_non_NaN_inds);
    
    % Determine if the track node is ascending or descending, and always
    % move landward from the most seaward ocean point
    
    if ross_files(i).direction == 'D' % descending
        
        disp('D')
        
        for j = 1:length(h_ss_non_NaN_inds) - 1
            
            % Calculate 'h_diff,' the difference between adjacent values of 
            % h_ss. If a pair of points meets the height, height difference,
            % and along-track distance criteria defined in the user input 
            % section, take the pair as representing a front jump and gather
            % data about the front crossing. Break out of this loop once 
            % the front is detected.
            
            h_diff = abs(h_ss_non_NaN_inds(j + 1) - h_ss_non_NaN_inds(j));
            
            if h_diff > h_diff_lower_limit && h_diff < h_diff_upper_limit && ...
                    h_ss_non_NaN_inds(j) < h_a_upper_limit

                jump_x_dist = abs(ross_files_clean(i).x_atc(gt_x_non_NaN_inds(j + 1)) - ... 
                    ross_files_clean(i).x_atc(gt_x_non_NaN_inds(j)));

                if jump_x_dist < jump_x_dist_upper_limit
                    
                    ross_front_crossing_data(i).found = 1;
                    ross_front_crossing_data(i).h_a = h_ss_non_NaN_inds(j);
                    ross_front_crossing_data(i).h_b = h_ss_non_NaN_inds(j + 1);
                    ross_front_crossing_data(i).h_diff = h_diff; 
                        % Set the front h_diff value as h_diff in the structure
                    ross_front_crossing_data(i).index_a = gt_x_non_NaN_inds(j);
                    ross_front_crossing_data(i).index_b = gt_x_non_NaN_inds(j + 1);
                    ross_front_crossing_data(i).x_dist_a = ... 
                        ross_files_clean(i).x_dist(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).x_dist_b = ... 
                        ross_files_clean(i).x_dist(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).x_atc_a = ... 
                        ross_files_clean(i).x_atc(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).x_atc_b = ... 
                        ross_files_clean(i).x_atc(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).lat_a = ... 
                        ross_files_clean(i).lat(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).lat_b = ... 
                        ross_files_clean(i).lat(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).lon_a = ... 
                        ross_files_clean(i).lon(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).lon_b = ... 
                        ross_files_clean(i).lon(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).x_a = ... 
                        ross_files_clean(i).x(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).x_b = ... 
                        ross_files_clean(i).x(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).y_a = ... 
                        ross_files_clean(i).y(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).y_b = ... 
                        ross_files_clean(i).y(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).delta_time_a = ... 
                        ross_files_clean(i).delta_time(gt_x_non_NaN_inds(j));
                    ross_front_crossing_data(i).delta_time_b = ... 
                        ross_files_clean(i).delta_time(gt_x_non_NaN_inds(j + 1));
                    ross_front_crossing_data(i).time_a = ... 
                        datenum(ref_time + (ross_front_crossing_data(i).delta_time_a) / (60*60*24));
                    ross_front_crossing_data(i).time_b = ... 
                        datenum(ref_time + (ross_front_crossing_data(i).delta_time_b) / (60*60*24));
                    
                    disp('front found')
                    
                end
                
                ross_front_crossing_data(i).x_gap = jump_x_dist;
                
                break
                
            end
            
        end
        
    else  % ascending
        
        for j = 1:length(h_ss_non_NaN_inds) - 1
            
            ascending_count = [length(h_ss_non_NaN_inds):-1:1];
            
            h_diff = abs(h_ss_non_NaN_inds(ascending_count(j)) - ... 
                h_ss_non_NaN_inds(ascending_count(j + 1)));
            
            if h_diff > h_diff_lower_limit && h_diff < h_diff_upper_limit && ... 
                    h_ss_non_NaN_inds(ascending_count(j))< h_a_upper_limit

                jump_x_dist = abs(ross_files_clean(i).x_atc(gt_x_non_NaN_inds(ascending_count(j + 1))) - ... 
                    ross_files_clean(i).x_atc(gt_x_non_NaN_inds(ascending_count(j))));
                
                if jump_x_dist < jump_x_dist_upper_limit
                    
                    ross_front_crossing_data(i).found = 1;
                    ross_front_crossing_data(i).h_a = h_ss_non_NaN_inds(ascending_count(j));
                    ross_front_crossing_data(i).h_b = h_ss_non_NaN_inds(ascending_count(j + 1));
                    ross_front_crossing_data(i).h_diff = h_diff;
                    ross_front_crossing_data(i).index_a = gt_x_non_NaN_inds(ascending_count(j));
                    ross_front_crossing_data(i).index_b = gt_x_non_NaN_inds(ascending_count(j + 1));
                    ross_front_crossing_data(i).x_dist_a = ... 
                        ross_files_clean(i).x_dist(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).x_dist_b = ... 
                        ross_files_clean(i).x_dist(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).x_atc_a = ... 
                        ross_files_clean(i).x_atc(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).x_atc_b = ... 
                        ross_files_clean(i).x_atc(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).lat_a = ... 
                        ross_files_clean(i).lat(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).lat_b = ... 
                        ross_files_clean(i).lat(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).lon_a = ... 
                        ross_files_clean(i).lon(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).lon_b = ... 
                        ross_files_clean(i).lon(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).x_a = ... 
                        ross_files_clean(i).x(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).x_b = ... 
                        ross_files_clean(i).x(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).y_a = ... 
                        ross_files_clean(i).y(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).y_b = ... 
                        ross_files_clean(i).y(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).delta_time_a = ... 
                        ross_files_clean(i).delta_time(gt_x_non_NaN_inds(ascending_count(j)));
                    ross_front_crossing_data(i).delta_time_b = ... 
                        ross_files_clean(i).delta_time(gt_x_non_NaN_inds(ascending_count(j + 1)));
                    ross_front_crossing_data(i).time_a = ... 
                        datenum(ref_time + (ross_front_crossing_data(i).delta_time_a) / (60*60*24));
                    ross_front_crossing_data(i).time_b = ... 
                        datenum(ref_time + (ross_front_crossing_data(i).delta_time_b) / (60*60*24));
                    
                    disp('front found')
                    
                end
                
                ross_front_crossing_data(i).x_gap = jump_x_dist;
                
                break
                
            end
            
        end
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot the range of h_diff values for all detected front crossings as a
% sort of sanity check

figure

for k = 1:gt_count
    
    plot(k,ross_front_crossing_data(k).h_diff(1),'*b','MarkerSize',10)
    set(gca,'FontSize',20)
    hold on
    
end

% Save the final 'ross_front_crossing_data' structure and other relevant 
% parameters to a *.mat file

save(out_filename, '-v7.3', 'ross_front_crossing_data', 'gt_count', ... 
    'h_a_upper_limit', 'h_diff_lower_limit', 'h_diff_upper_limit', ... 
    'jump_x_dist_upper_limit')
