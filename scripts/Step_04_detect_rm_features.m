% This script searches each ground track profile in which the ice front was
% detected for a rampart-moat (R-M) structure (again moving from the ocean 
% to the ice shelf). If an R-M structure is found, it gathers various data 
% on the structure and uses those data to compute dh_RM and dx_RM.
%
% This script implements steps (v) and (vi) described in Subsection 2.3 of 
% Becker et al. (2021).
%
% Susan L. Howard, Earth and Space Research, showard@esr.org
% Maya K. Becker, Scripps Institution of Oceanography, mayakbecker@gmail.com
%
% Last updated April 16, 2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Begin user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load 'ross_front_crossing_data.mat' % *.mat file created in Step 03

out_filename = 'ross_rm_data.mat';  % output filename

ref_time = datenum(2018,01,01); % reference time for all ground track profiles

% Set various criteria that a near-front depression must satisfy in order 
% to be classified as representing an R-M structure by the R-M detection
% algorithm

moat_h_lower_limit = 2;        % lower limit of the height of the moat--must be 
                               % above sea level
                               
moat_search_dist = 2000;       % along-track distance from the detected front over
                               % which to search for a moat
                               
rampart_max_search_dist = 100; % along-track distance from the detected front
                               % over which to search for a higher maximum
                               % than what the algorithm detects as the rampart
                               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate variables for various moat- and rampart-related parameters. Set
% all to NaN; these variables will be populated later on in this script.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

moat_h(1:gt_count) = NaN; % height of the moat minimum
moat_index(1:gt_count) = NaN; % index corresponding to the moat minimum
moat_x(1:gt_count) = NaN; % x-coordinate of the moat minimum location
moat_y(1:gt_count) = NaN; % y-coordinate of the moat minimum location
moat_x_dist(1:gt_count) = NaN; % along-track distance (in x) from the first
                               % ATL06 segment in the ground track profile
                               % to the moat minimum location
moat_x_atc(1:gt_count) = NaN; % along-track x-coordinate of the moat minimum 
                              % location
moat_delta_time(1:gt_count) = NaN; % delta time value of the moat minimum 
                                   % location

rm_flag(1:gt_count) = 0; % whether or not there is a moat/an R-M (0 = no; 1 = yes)

rampart_h(1:gt_count) = NaN; % height of the rampart maximum
rampart_index(1:gt_count) = NaN; % index corresponding to the rampart maximum
rampart_x(1:gt_count) = NaN; % x-coordinate of the rampart maximum location
rampart_y(1:gt_count) = NaN; % y-coordinate of the rampart maximum location
rampart_x_dist(1:gt_count) = NaN; % along-track distance (in x) from the 
                                  % first ATL06 segment in the ground track
                                  % profile to the rampart maximum location
rampart_x_atc(1:gt_count) = NaN; % along-track x-coordinate of the rampart 
                                 % maximum location
rampart_delta_time(1:gt_count) = NaN; % delta time value of the rampart maximum 
                                      % location

% Gather all track node values into a single variable (with 1 representing
% the ascending track node and 2 representing the descending track node).
% Do the same for all cycle values.

track_node(1:gt_count) = 0; % whether the track is ascending or descending
cycle_number(1:gt_count) = 0; % cycle of data acquisition

for i = 1:gt_count
    
    if ross_front_crossing_data(i).direction == 'A' % ascending
        track_node(i) = 1;
    elseif ross_front_crossing_data(i).direction == 'D' % descending
        track_node(i) = 2;
    else
        track_node(i) = 0;
    end
    
    cycle_number(i) = convertCharsToStrings(ross_front_crossing_data(i).cycle);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run the R-M detection algorithm for each ground track profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run the R-M detection algorithm for each ground track profile, sorting by
% ascending and descending tracks as in Step 03. Search for the moat by
% looking for the minimum height value in the first detected depression 
% that is less than 2 km (or the value of 'moat_search_dist' defined in the 
% user input section) along track from the upper, ice-shelf point in the 
% front jump (Point B).

for i = 1:gt_count
    
    disp(['loop 1 = ' num2str(i)])
    
    h_b = ross_front_crossing_data(i).h_b;
    
    rm_h_loop = h_b;
    index_loc = ross_front_crossing_data(i).index_b;
    x_diff = ross_front_crossing_data(i).x_dist_b;
    index_b = ross_front_crossing_data(i).index_b;
    
    % Limit the moat loop indices based on the the value of
    % 'moat_search_dist' specified in the user input section
    
    moat_search_dist_index_count = (moat_search_dist / 20) + 1;
    
    if ~isnan(h_b)
        
        if ross_front_crossing_data(i).direction == 'D' % descending
            
            for j = 1:moat_search_dist_index_count
                
                try
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b + j));
                    
                    if x_dist_near_front < moat_search_dist
                        
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b + j);
                        
                        if rm_h_loop_new < rm_h_loop && rm_h_loop_new > moat_h_lower_limit
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b + j;
                            
                        else
                            
                            % Break out of this loop if a depression that
                            % satisfies the criteria defined in the user input
                            % section is detected
                            
                            break
                            
                        end
                        
                    end
                    
                catch
                    
                    disp('short beam')
                    
                end
                
            end   
            
        else % ascending
            
            for j = 1:moat_search_dist_index_count 
                
                try
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b - j));
                    
                    if x_dist_near_front < moat_search_dist
                        
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b - j);
                        
                        if rm_h_loop_new < rm_h_loop && rm_h_loop_new > moat_h_lower_limit
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b - j;
                        
                        else
                            
                            break
                            
                        end
                        
                    end
                    
                catch
                    
                    disp('short beam')
                    
                end
                
            end
            
        end
        
        moat_h(i) = rm_h_loop;
        moat_index(i) = index_loc;
        
        % If a depression satisfies the criteria defined in the user input
        % section, take it as a moat and gather and report data about it
        
        if ~isnan(h_b)
            
            moat_x(i) = ross_front_crossing_data(i).x(index_loc);
            moat_y(i) = ross_front_crossing_data(i).y(index_loc);
            moat_x_dist(i) = ross_front_crossing_data(i).x_dist(index_loc);
            moat_x_atc(i) = ross_front_crossing_data(i).x_atc(index_loc);
            moat_delta_time(i) = ross_front_crossing_data(i).delta_time(index_loc);

        end
        
        if rm_h_loop ~= h_b 
            
            rm_flag(i) = 1; % a moat has been detected
            
        else   
            
            rm_flag(i) = 0; % a moat has not been detected
            
        end   
    
      
    else  % h_b is NaN for a specific ground track profile.  Re-set all 
          % moat-related variable values to NaN
        
        moat_h(i) = NaN;
        moat_index(i) = NaN;
        moat_x(i) = NaN;
        moat_y(i) = NaN;
        moat_x_dist(i) = NaN;
        moat_x_atc(i) = NaN;
        rm_flag(i) = 0;
        moat_delta_time(i) = NaN;
        
    end
    
end

% If a moat is detected along a ground track profile, make sure that the 
% upper, ice-shelf point in the front jump (Point B) is actually the rampart 
% maximum by searching for the highest point within 100 m (or the value of
% 'rampart_max_search_dist' defined in the user input section) of the front

for i = 1:gt_count
    
    disp(['loop 2 = ' num2str(i)])
    
    h_b = ross_front_crossing_data(i).h_b;
    
    rm_h_loop = h_b;
    index_loc = ross_front_crossing_data(i).index_b;
    x_diff = ross_front_crossing_data(i).x_dist_b;
    index_b = ross_front_crossing_data(i).index_b;
    
    % Limit the rampart loop indices based on the value of
    % 'rampart_max_search_dist' specified in the user input section
    
    rampart_max_search_dist_index_count = (rampart_max_search_dist / 20) + 1;
    
    if ~isnan(h_b)
        
        if rm_flag(i) == 1 % if a moat has been detected
            
            if ross_front_crossing_data(i).direction == 'D' % descending
                
                for j = 1:rampart_max_search_dist_index_count 
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b + j));
                    
                    if x_dist_near_front < rampart_max_search_dist
                                                     
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b + j);
                        
                        if rm_h_loop_new > rm_h_loop
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b + j;
                            
                        end
                        
                    end
                    
                end
                
            else % ascending
                
                for j = 1:rampart_max_search_dist_index_count 
                    
                    x_dist_near_front = abs(x_diff - ross_front_crossing_data(i).x_dist(index_b - j));
                    
                    if x_dist_near_front < rampart_max_search_dist
                                                     
                        rm_h_loop_new = ross_front_crossing_data(i).h_ss(index_b - j);
                        
                        if rm_h_loop_new > rm_h_loop
                            
                            rm_h_loop = rm_h_loop_new;
                            index_loc = index_b - j;
                            
                        end
                        
                    end
                    
                end
                
            end
           
            rampart_h(i) = rm_h_loop;
            rampart_index(i) = index_loc;
            
            % If a high point satisfies the criteria defined in the user input
            % section, take it as the rampart maximum and gather and report 
            % data about it
            
            if ~isnan(h_b)
                
                rampart_x(i) = ross_front_crossing_data(i).x(index_loc);
                rampart_y(i) = ross_front_crossing_data(i).y(index_loc);
                rampart_x_dist(i) = ross_front_crossing_data(i).x_dist(index_loc);
                rampart_x_atc(i) = ross_front_crossing_data(i).x_atc(index_loc);
                rampart_delta_time(i) = ross_front_crossing_data(i).delta_time(index_loc);
                
            end
             
            
        else  % rm_flag is 0 for current ground track profile at index i. 
              % A moat was not detected.  Re-set all rampart-related 
              % variable values for the ground track profile at to NaN 
            
            rampart_h(i) = NaN;
            rampart_index(i) = NaN;
            rampart_x(i) = NaN;
            rampart_y(i) = NaN;
            rampart_x_dist(i) = NaN;
            rampart_x_atc(i) = NaN;
            rampart_delta_time(i) = NaN;
            
        end
    
  
    else  % h_b is NaN for current ground track profile at index i. 
          % Re-set all rampart-related variable values for the ground
          % track profile at to NaN 
             
        
        rampart_h(i) = NaN;
        rampart_index(i) = NaN;
        rampart_x(i) = NaN;
        rampart_y(i) = NaN;
        rampart_x_dist(i) = NaN;
        rampart_x_atc(i) = NaN;
        rampart_delta_time(i) = NaN;
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute specific parameters that describe the R-M feature (if it exists)
% in each ground track profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate variables for three R-M parameters: dh_rm, which is the height
% of the rampart maximum relative to the moat; dx_rm, which is the
% along-track distance from the rampart maximum to the lowest portion of
% the moat; and time_rm, which is the serial date number corresponding to
% the approximate center of the R-M feature. Set all to NaN; these variables 
% will be populated in the loop that follows.

dh_rm(1:gt_count) = NaN;
dx_rm(1:gt_count) = NaN;
time_rm(1:gt_count) = NaN;

for i = 1:gt_count
    
    % Only calculate these values if a moat has been detected
    
    if rm_flag(i) == 1
        
        dh_rm(i) = rampart_h(i) - moat_h(i);
        dx_rm(i) = rampart_x_dist(i) - moat_x_dist(i);
        average_time = (rampart_delta_time(i) + moat_delta_time(i)) / 2; % "average" time of the R-M feature
        time_rm(i) = datenum(ref_time + (average_time / (60*60*24)));
      
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Save relevant R-M parameters to a *.mat file

save(out_filename, '-v7.3', 'moat_h', 'moat_index', 'moat_x', 'moat_y', ... 
    'moat_x_dist', 'moat_x_atc', 'moat_delta_time', 'rm_flag', 'rampart_h', ... 
    'rampart_index', 'rampart_x', 'rampart_y', 'rampart_x_dist', ... 
    'rampart_x_atc', 'rampart_delta_time', 'dh_rm', 'dx_rm', 'time_rm', ... 
    'track_node', 'cycle_number')
