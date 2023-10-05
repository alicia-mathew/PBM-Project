% This script outlines all the preprocessing steps for a collection of 
% EEG datasets.

% Preprocessing steps:
%   1. Import .mff file as .set file
%   2. Remove face electrodes: 67, 73, 82, 91, 92, 93, 102, 103, 111, 112, 
%      120, 121, 133, 134, 145, 146, 156, 165, 166, 174, 175, 187, 188, 
%      189, 199, 200, 201, 208, 209, 216, 217, 218, 219, 225, 226, 227, 
%      228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 
%      241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 
%      254, 255, 256
%   4. Resample data: 125 Hz
%   5. High pass filtering: 
%       - 1 Hz for lower edge of frequency pass band
%   6. Decompose using ICA - add weights
%   7. Label components
%   8. Flag components as artifacts
%   9. Remove components that were flagged
%  10. Bad channel rejection
%  11. Plot channel spectra and maps (frequencies to plot as scalp maps:
%      2 6 10 22 40 Hz) 
%  12. Plot channel positions (by name) 

%% Run EEGLAB
clear
clc

cd('/rri_disks/maja/chen_lab/analysis/amathew/eeglab2023.1/');
eeglab;

%% 
% Note: Ensure folders are organized in such a way that the
%       "BeforePreprocessing" folder contains subject folders with 3 .mff
%       files: 40Hz, 10Hz, and 40Hz-Video. Then, the "AfterPreprocessing"
%       folder will contain subject folders with the final respective
%       preprocessed .set files

% Root folder containing subject folders that need to be preprocessed
BeforePreprocessing = '/rri_disks/maja/chen_lab/analysis/amathew/EEG/1-BeforePreprocessing/';
cd(BeforePreprocessing);

% Create root folder to store new preprocessed .set files
AfterPreprocessing = '/rri_disks/maja/chen_lab/analysis/amathew/EEG/2-AfterPreprocessing/';
mkdir(AfterPreprocessing);

% All the subject folders with .mff files that need to be preprocessed
SubjectFolders = dir(fullfile(BeforePreprocessing, 'Subject*'));

%%
% Go through each Subject and preprocess each of its 3 .mff files: 40Hz,
% 10Hz, and 40Hz-Video
for num = 1:length(SubjectFolders)
    % Current subject number
    Subject_Num = SubjectFolders(num).name;
    
    % Go into this specific subject's folder
    SubjectFolder = append(BeforePreprocessing, Subject_Num);
    cd(SubjectFolder);

    % All 3 .mff files for this subject
    MFF_Files = dir(fullfile(SubjectFolder, '*.mff'));
    
    % Create a folder to store this subject's preprocessed .set files
    new_SubjectFolder = append(AfterPreprocessing, Subject_Num);
    mkdir(new_SubjectFolder);

    % Takes each .mff file through the preprocessing pipeline
    for i = 1:length(MFF_Files)
        % Import .mff file and save as .set file
        FileName = MFF_Files(i).name;
        EEG = pop_mffimport(FileName);
        Output_FileName = append(FileName(1:end-4), 'Sept28_Without50HzCutoff_Preprocessed.set');
        
        % Save .set file
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);
        disp(append(Output_FileName, ' has been created.'));
        
        % Load EEG .set file
        EEG = pop_loadset('filename', Output_FileName, 'filepath', new_SubjectFolder);
        
        % Remove last 10 seconds of dataset
        CurrentEnd_Time = (EEG.times(end) / 1000); % (in seconds)
        NewEnd_Time = CurrentEnd_Time - 10;
        EEG = pop_select(EEG, 'time', [0 NewEnd_Time]);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);
        disp('Last 10 seconds of dataset have been removed.')

        % Facial electrodes to remove
        Electrodes = [67, 73, 82, 91, 92, 93, 102, 103, 111, 112, 120, ...
            121, 133, 134, 145, 146, 156, 165, 166, 174, 175, 187, 188, ...
            189, 199, 200, 201, 208, 209, 216, 217, 218, 219, 225, 226, ...
            227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, ...
            239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, ...
            251, 252, 253, 254, 255, 256];

        % Prepend 'E' to each number and store in cell array (EEGLAB format)
        FacialElectrodes = cellfun(@(x) ['E' num2str(x)], ...
            num2cell(Electrodes), 'UniformOutput', false);
        
        % Remove facial electrodes
        EEG = pop_select(EEG, 'nochannel', FacialElectrodes);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);
        disp('Facial electrodes/channels have been removed.')
        
        % Set value for sampling rate (Hz)
        SamplingRate = 125;
        
        % Resample dataset
        EEG = pop_resample(EEG, SamplingRate);
        EEG = eeg_checkset(EEG);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);
        
        % Filter data
        % Perform high pass filtering first - filter out LOW frequencies
        LowerEdge = 1; % lower edge of frequency band pass
        EEG = pop_eegfiltnew(EEG, 'locutoff', LowerEdge, 'plotfreqz', 1);
        EEG = eeg_checkset(EEG);
        
        % Then perform low pass filtering - filter out HIGH frequencies
%         HigherEdge = 50; % higher edge of frequency band pass
%         EEG = pop_eegfiltnew(EEG, 'hicutoff', HigherEdge, 'plotfreqz', 1);
%         EEG = eeg_checkset(EEG);
        
        % High pass filtering data
%         LowerEdge = 1; % lower edge of frequency band pass
%         HigherEdge = 50; % higher edge of frequency band pass
%         EEG = pop_eegfiltnew(EEG, 'locutoff', LowerEdge, 'hicutoff', HigherEdge, 'plotfreqz', 1);
%         EEG = eeg_checkset(EEG);
        
        % Save the plot as PNG image
        plotFileName = fullfile(new_SubjectFolder, append(FileName(1:end-4), ...
            '_filter_frequency_response.png'));
        print('-dpng', plotFileName);
        disp('Plotted frequency response and saved plot.')
        close(gcf); % Close current figure
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', ...
            new_SubjectFolder);
        
        % Decompose using ICA
        EEG = pop_runica(EEG, 'icatype', 'runica', 'options', ...
            {'extended', 1}, 'reorder', 'on');
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);

        % Label components
        EEG = iclabel(EEG, 'default'); % or is it pop_iclabel with 'Default'
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);

        % Flag components as artifacts
        % Here we choose the ranges to flag only "Muscle", "Eye", and "Channel Noise" components
        thresh = [0 0; 0.9 1; 0.9 1; 0 0; 0 0; 0.9 1; 0 0];
        EEG = pop_icflag(EEG, thresh);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);

        % Remove components from data
        rejected_comps = find(EEG.reject.gcompreject > 0);
        EEG = pop_subcomp(EEG, rejected_comps);
        EEG = eeg_checkset(EEG);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', new_SubjectFolder);

        % Reject bad channels
        EEG = pop_clean_rawdata(EEG, 'rmflatsec', 5, 'rmnoiseval', 4, ...
            'rmcorrval', 0.8);
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', ...
            new_SubjectFolder);
        
        % Plot channel spectra
        TimeRange = [0 EEG.times(end)];
        PercentDataToSample = 100;
        FrequenciesToPlot = [2 6 10 22 40];
        PlottingFrequencyRange = [1 55];
        pop_spectopo(EEG, 1, TimeRange, 'EEG', 'percent', ...
            PercentDataToSample, 'freqs', FrequenciesToPlot, ...
            'freqrange', PlottingFrequencyRange);
        
        % Save the plot as PNG image
        plotFileName = fullfile(new_SubjectFolder, append(FileName(1:end-4), ...
            '_channel_spectra_and_maps.png'));
        print('-dpng', plotFileName);
        disp('Saved channel spectra and maps.')
        close(gcf); % Close current figure
        pop_saveset(EEG, 'filename', Output_FileName, 'filepath', ...
            new_SubjectFolder);
        
        disp(append('Preprocessing complete. Saving dataset: ', Output_FileName))
        
        % Plot maps - ask Hannah how we can plot the scalp maps
        %   how to plot the specific frequencies: 2 6 10 22 40
        % topoplot(EEG.data, EEG.chanlocs, 'electrodes', 'off');
    end
    disp(append('Preprocessing complete for all 3 datasets for ', Subject_Num));
end
