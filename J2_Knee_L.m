clear all; clc
Nsubj=24;
%%
if Nsubj<10
    subj=strcat('subj0',num2str(Nsubj));
else subj=strcat('subj',num2str(Nsubj));
end
JointName = ["Ankle Flexion Left"; "Ankle Flexion Right"; "Knee Flexion Left"; "Knee Flexion Right";...
             "Elbow Flexion Left"; "Elbow Flexion Right"; "Forearm Supination Left"; "Forearm Supination Right";...
             "Hip Flexion Left"; "Hip Flexion Right"; "Hip Adduction Left"; "Hip Adduction Right";...
             "Hip Rotation Left"; "Hip Rotation Right";...
             "Arm Flexion Left"; "Arm Flexion Right"; "Arm Adduction Left"; "Arm Adduction Right";...
             "Arm Rotation Left"; "Arm Rotation Right";...
             "Lumbar Flexion"; "Lumbar Lateral Bending"; "Lumbar Rotation"];
% File paths
ExcelPath = 'F:\CYN-TAMU\Research-TAMU\01.OESI Offshore Turbine\Detailed Experimental Data_Local.xlsx';
IKFile = fullfile('F:\CYN-TAMU\Research-TAMU\01.OESI Offshore Turbine\01.Dataset\03.OpenSim', subj, 'IKResults', [subj '_IKResults.mat']);
DriftFile = fullfile('F:\CYN-TAMU\Research-TAMU\01.OESI Offshore Turbine\01.Dataset\01.BioStamp', 'LinearDrift.mat');
[num,txt,raw] = xlsread(ExcelPath,subj);
load(IKFile);
load('BioSignal.mat');
load(DriftFile);
%% calculate the Bio Kinematics
Nt_num=[27:30;31:34;35:38;39:42];
for Nt=Nt_num(4,:)
    [p, q] = rat(50/62.5);
    Ns=9;
    Shank_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns}); % remove the drift
    Ns=3;
    Thign_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    % calculate the joint angle using the specific biostamp data
    DataNum=min(size(Shank_Ang_L),size(Thign_Ang_L));  % Make two sensor's data into equal length
    Knee_Bio_temp=-Thign_Ang_L(1:DataNum(1),3)+Shank_Ang_L(1:DataNum(1),3);
    Knee_Bio_L=resample(Knee_Bio_temp,p,q);
    %% load the OpenSim Kinematics
    Knee_OS_L=ik_data{Nt,2}(:,19); % 19：knee_angle_l
    p0=num(Nt,5);p5=num(Nt,6);SF=num(Nt,13);EF=num(Nt,15);
    [Knee_Bio, Knee_OS]=ScaleSignal(p0,SF,EF,Knee_OS_L,Knee_Bio_L);
    
    vOS=Knee_OS;    vBio=Knee_Bio;
    JN=3;
    %% plot to validate
    [rmse,r]=Getr(vOS, vBio);
    fprintf('Shoulder Flexion: Nt = %d, RMSE = %.2f°, r = %.3f\n', Nt, rmse, r);
    figure;    hold on;
    t = linspace(0, 100, length(vOS)); % in second
    plot(t, vOS,   'b-',  'LineWidth', 2);
    plot(t, vBio,  'b--', 'LineWidth', 1);
    load('BioModel.mat');
    BioKinematics{Nt,JN}=vBio;
    OSKinematics{Nt,JN}=vOS;
    save('BioModel.mat', 'BioKinematics', 'OSKinematics');
end