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
for Nt=Nt_num(4,:)
    [p, q] = rat(50/62.5);
    Ns=5;
    T12_Ang=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    Ns=11;
    Pelvis_Ang=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    % calculate the joint angle using the specific biostamp data
    DataNum=min(size(T12_Ang),size(Pelvis_Ang));  % Make two sensor's data into equal length
    % Lumbar_Flex_Bio_temp=-T12_Ang(1:DataNum(1),1)+Pelvis_Ang(1:DataNum(1),1);
    Lumbar_Flex_Bio_temp=Pelvis_Ang(1:DataNum(1),1);
    Lumbar_Flex_Bio=resample(Lumbar_Flex_Bio_temp,p,q);
    Lumbar_Addu_Bio_temp=-T12_Ang(1:DataNum(1),3)-Pelvis_Ang(1:DataNum(1),3);
    % Lumbar_Addu_Bio_temp=-Pelvis_Ang(1:DataNum(1),3);
    Lumbar_Addu_Bio=resample(Lumbar_Addu_Bio_temp,p,q);
    % Lumbar_Rot_Bio_temp=T12_Ang(1:DataNum(1),2)-Pelvis_Ang(1:DataNum(1),2);
    % Lumbar_Rot_Bio_temp=-T12_Ang(1:DataNum(1),2);
    Lumbar_Rot_Bio_temp=-Pelvis_Ang(1:DataNum(1),2);
    Lumbar_Rot_Bio=resample(Lumbar_Rot_Bio_temp,p,q);
    %% load the OpenSim Kinematics
    Lumbar_Flex_OS=ik_data{Nt,2}(:,24); % 24：Lumbar_flex_l
    Lumbar_Addu_OS=ik_data{Nt,2}(:,25); % 25：Lumbar_add_l
    Lumbar_Rot_OS=ik_data{Nt,2}(:,26); % 26：Lumbar_rot_l

    p0=num(Nt,5); p5=num(Nt,6); SF=num(Nt,13); EF=num(Nt,15);
    [Lum_Fle_Bio, Lum_Fle_OS]=ScaleSignal(p0,SF,EF,Lumbar_Flex_OS,Lumbar_Flex_Bio);
    [Lum_Add_Bio, Lum_Add_OS]=ScaleSignal(p0,SF,EF,Lumbar_Addu_OS,Lumbar_Addu_Bio);
    [Lum_Rot_Bio, Lum_Rot_OS]=ScaleSignal(p0,SF,EF,Lumbar_Rot_OS,Lumbar_Rot_Bio);

    %% Flexion
    % vOS=Lum_Fle_OS;    vBio=Lum_Fle_Bio;
    % JN=21;
    %% adduction
    % vOS=Lum_Add_OS;    vBio=Lum_Add_Bio;
    % JN=22;
    %% rotation
    vOS=Lum_Rot_OS;    vBio=Lum_Rot_Bio;
    JN=23;
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

%% identify the axis
figure;
plot(T12_Ang);
figure;
plot(Pelvis_Ang);
figure;
plot(Lum_Fle_OS);