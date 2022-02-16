
clear all 
clc

addpath('/Users/lauracarlton/Dropbox/AUREA_retrieved_v2/METRICS/')
addpath('/Users/lauracarlton/Dropbox/AUREA_retrieved_v2/Signal_Processing/')
addpath('/Users/lauracarlton/Dropbox/AUREA_retrieved_v2/CardioRespiratory_Analysis/')
baseDir = '/Users/lauracarlton/Dropbox/ApnexDetection_Project/';

trials = ["001", "002", "003", "008", "009", "010", "011", "012", "013", "017", "018", "019", "020", "021", "022", "023", "024", "025"];
Ntrials = length(trials);
directions = ["X", "Y", "Z"];
nDir = length(directions);

nb = ["001", "008", "011", "017", "020", "023"];
vb = ["002", "009", "012", "018", "021", "024"];
ob = ["003", "010", "013", "019", "022", "025"];

for n = 1:Ntrials

    ntrial = trials{n};
    load([baseDir, 'trials_data_nldat_v3/ANNE_data_trial' ntrial '_clean'])

    if ismember(ntrial,["001","002","003","008","009","010"])
        ChestSensor = 'C3898'; AbdSensor = 'C3892'; DigitSensor = 'L3572';
    else
        ChestSensor = 'C3900'; AbdSensor = 'C3895'; DigitSensor = 'L3569';
    end

    if ismember(ntrial, nb)
        descrip_path ='normalBreathing'; description = 'normal breathing';
    elseif ismember(ntrial, vb)
        descrip_path ='intermittentBreathing_voluntary'; description = 'intermittent breathing - voluntary';
    elseif ismember(ntrial, ob)
        descrip_path ='intermittentBreathing_obstruction'; description = 'interittent breathing - obstruction';
    else
        error('Unknown trial type')
    end

    filename = string([baseDir ntrial '_' descrip_path '.json']);
    savepath = '/Users/lauracarlton/Dropbox/ApnexDetection_Project/trials_data_nldat_v3/';
    if ~exist(savepath, 'file')
        mkdir(savepath)
    end

    N=251;
    Nb = 101;
    Nmu1 = 101;
    Navg = 21;
    Nr = 251;
    Fs = 50;

    for v = 1:nDir
        dir = directions{v};
        data_chest = ACCEL_chest_clean.dataSet;
        accel_chest = data_chest(:,v);
        data_abd = ACCEL_abd_clean.dataSet;
        accel_abd = data_abd(:,v);

        eval(['[stat.TotPWR_RR_A_' dir ', stat.TotPWR_MV_A_' dir ',stat.MaxPWR_MV_A_' dir ',stat.MaxPWR_RR_A_' dir ',stat.FMAX_A_' dir ',stat.FMAXi_A_' dir '] = filtBankRespir_adult(accel_abd,N,Fs);']);
        eval(['[stat.TotPWR_RR_C_' dir ', stat.TotPWR_MV_C_' dir ',stat.MaxPWR_MV_C_' dir ',stat.MaxPWR_RR_C_' dir ',stat.FMAX_C_' dir ',stat.FMAXi_C_' dir '] = filtBankRespir_adult(accel_chest,N,Fs);']);

        eval(['[stat.PHI_' dir ',stat.FMAXi_AC_' dir '] = asynchStat(accel_chest,accel_abd,N,Fs);']);
        eval(['[stat.RMS_A_' dir '] = rmsStat(accel_abd,accel_abd,Nr,Fs);']);    
        eval(['[stat.RMS_C_' dir '] = rmsStat(accel_chest,accel_chest,Nr,Fs);']);    
        eval(['[stat.RMS_AC_' dir '] = rmsStat(accel_abd,accel_chest,Nr,Fs);']);    
        eval(['[stat.BRC_' dir ',stat.BAB_' dir ',stat.BSU_' dir ',stat.BDI_' dir ',stat.BPH_' dir '] = breathStat(accel_chest,accel_abd,Nb,Nmu1,Navg,Fs);'])

    end
% 
    save([savepath 'features_stats_trial' ntrial], 'stat')
end




