clear all; clc
Nsubj=24; 
%% load the file
if Nsubj<10
    subj=strcat('subj0',num2str(Nsubj));
else subj=strcat('subj',num2str(Nsubj));
end
JointName = ["Elbow Flexion Left"; "Elbow Flexion Right"; "Elbow Flexion Left"; "Elbow Flexion Right";...
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
for Nt=Nt_num(1,:)
    [p, q] = rat(50/62.5);
    Ns=12;
    Arm_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    Ns=7;
    Forearm_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    % calculate the joint angle using the specific biostamp data
    DataNum=min(size(Arm_Ang_L),size(Forearm_Ang_L));  % Make two sensor's data into equal length
    Elbow_Bio_temp=Arm_Ang_L(1:DataNum(1),3)-Forearm_Ang_L(1:DataNum(1),3);
    % Elbow_Bio_temp=-Forearm_Ang_L(1:DataNum(1),3);
    Elbow_Bio_L=resample(Elbow_Bio_temp,p,q);

    %% load the OpenSim Kinematics
    Elbow_OS_L=ik_data{Nt,2}(:,35); % 35：elbow_flex_l
    p0=num(Nt,5);p5=num(Nt,6);SF=num(Nt,13);EF=num(Nt,15);
    [Elbow_Bio, Elbow_OS]=ScaleSignal(p0,SF,EF,Elbow_OS_L,Elbow_Bio_L);
    
    vOS=Elbow_OS;    vBio=Elbow_Bio;
    JN=5;
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