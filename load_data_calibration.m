%% NOTES BEFORE RUNNING
% loading data from the series of calibration trials to visualize 
% Make sure current folder is DropBox 
% Make sure to add all folders in ApnexDetection_Project
% Make sure to add nlid_tools and utility_tools from reklab public

addpath('.../Dropbox/ApnexDetection_Project/MATLAB tools/jsonlab-2.0/jsonlab-2.0/')
addpath('.../GitHub/reklab_public/utility_tools/');
addpath('.../GitHub/reklab_public/nlid_tools/');

%% load raw data from the json file 
clc
clear all

baseDir = '.../ApnexDetection_Project/trials_data_json/ANNE_data_trial';

% chose the desired trial
% descrip_path = 'calibrationC3898_test01'; ntrial = '004';
% descrip_path = 'calibrationC3892_test01'; ntrial = '005';
% descrip_path = 'calibrationC3898_test02'; ntrial = '006';
descrip_path = 'calibrationC3892_test02'; ntrial = '007';

filename = string([baseDir ntrial '_' descrip_path '.json']);
savepath = ['.../Dropbox/ApnexDetection_Project/Export/figures_v3/' ntrial '/'];
if ~exist(savepath, 'file')
    mkdir(savepath)
end
savefigs = 1;
raw_data = loadjson(filename);

fprintf('Data loaded \n')
%% go through each cell in the raw data and assign it to a structure
pkg_gap=[];
package_gap_counter =1;
duplicate_data_counter = 1;
for a = 1:length(raw_data)
    
    cell = raw_data{a};
    datatype = cell.dataType;
    if datatype == "Health"
        continue
    end
    sensor = cell.sensor_name;
    try
        all_data.(sensor).(datatype)(end+1) = cell;
    catch
        all_data.(sensor).(datatype) = cell;
        pkg_gap.(sensor).(datatype) = struct('gap_start', 0, 'gap_end', 0);
    end
    
    if length(all_data.(sensor).(datatype)) >= 2
 
        time_diff = zeros(length(cell.timestamp)-1,1);
        for j = 2:length(cell.timestamp)
            time_diff(j-1) = cell.timestamp(j) - cell.timestamp(j-1);
        end
        Ts = mean(time_diff);
                
        if cell.timestamp >1.5*Ts*length(cell.timestamp)+all_data.(sensor).(datatype)(end-1).timestamp
%             fprintf('GAP in the data - sensor: %s datatype: %s \n', sensor, datatype)
            package_gap_counter = package_gap_counter+1;
            T1=all_data.(sensor).(datatype)(1).timestamp(1,1);
            TS=all_data.(sensor).(datatype)(end-1).timestamp(end);
            if pkg_gap.(sensor).(datatype)(1).gap_start==0
                pkg_gap.(sensor).(datatype)(1).gap_start=TS-T1;
                pkg_gap.(sensor).(datatype)(1).gap_end=cell.timestamp(1,1)-T1;
            else
                pkg_gap.(sensor).(datatype)(end+1).gap_start=TS-T1;
                pkg_gap.(sensor).(datatype)(end).gap_end=cell.timestamp(1,1)-T1;
            end
        elseif cell.timestamp == all_data.(sensor).(datatype)(end-1).timestamp
            vars = fieldnames(cell);
            p = find(vars == "address");
            vars(p:end) = [];
            
            data1 = zeros(length(vars),length(cell.timestamp));
            data2 = zeros(length(vars),length(cell.timestamp));
            for v = 1:length(vars)
                data1(v,:) = cell.(vars{v});
                data2(v,:) = all_data.(sensor).(datatype)(end-1).(vars{v});
            end
            if isequal(data1, data2)
                all_data.(sensor).(datatype)(end) = [];
                duplicate_data_counter = duplicate_data_counter+1;
            else
%                 fprintf('ERROR: different data for same time points - sensor: %s datatype: %s \n', sensor, datatype)
                all_data.(sensor).(datatype)(end) = [];
                duplicate_data_counter = duplicate_data_counter+1;
            end
        end               
    end
end

fprintf('Data converted to structure \n')
%% convert data to nldat
sensor_list = fieldnames(all_data);

for n = 1:length(sensor_list)
    
    sensor = sensor_list{n};
    data_list = fieldnames(all_data.(sensor));
    for d = 1:length(data_list)
        datatype = data_list{d};
        y = all_data.(sensor).(datatype);
        pkg_length = length(y);
       
        vars = fieldnames(all_data.(sensor).(datatype));
        a = find(vars=="address");
        vars(a:end) = [];
 
        for v = 1:length(vars)
            var = vars{v};
            
            data_length = length(all_data.(sensor).(datatype)(1).(var));
            hold_data = zeros(data_length, pkg_length);
            hold_time = zeros(data_length,pkg_length);
            data={all_data.(sensor).(datatype).(var)};
            time={all_data.(sensor).(datatype).timestamp};
            for t = 1:pkg_length
                    hold_data(:,t)=cell2mat(data(1,t));
                    hold_time(:,t)=cell2mat(time(1,t));
            end
            
            hold_data=transpose(reshape(hold_data,1,[]));
            hold_time=transpose(reshape(hold_time,1,[]));
            hold_time=hold_time-hold_time(1,1);
            hold_time = hold_time/1000;
            
            hold_nldat = nldat(hold_data);

            if v > 1
                eval(['nldat_' sensor '_' datatype '=cat(2, nldat_' sensor '_' datatype ', hold_nldat);'])
                
            else
                eval ([ 'nldat_' sensor '_' datatype '= hold_nldat;']);
            end
        end
    end
end
fprintf('Data converted to nldat objects‰ \n')

fs = 416;
names = {"ACCEL X", "ACCEL Y", "ACCEL Z"};
set(nldat_C3898_ACCEL, 'domainIncr', 1/fs, 'domainValues', NaN, 'chanNames',names )
set(nldat_C3892_ACCEL, 'domainIncr', 1/fs, 'domainValues', NaN, 'chanNames', names)

%% analysis 2: generate figues

channels = nldat_C3898_ACCEL.chanNames;
nChans = length(channels);

directions = ["X", "Y", "Z"];
figure(1)
for v = 1:nChans

    dir = directions{v};

    ax1 = subplot(nChans,1,v);
    plot(nldat_C3898_ACCEL(:,v))
    hold on
    plot(nldat_C3892_ACCEL(:,v));
    legend(["Chest Sensor", "Abdomen Sensor"])
    title(['Acceleration in the ' dir ' direction for both sensors'])
    ax1.FontSize = 30;
    hold off
end

set(figure(1), 'Units', 'normalized', 'outerposition', [0 0 1 1])
savefig(figure(1), [savepath, 'accel_' ntrial])

close all