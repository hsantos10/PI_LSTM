clear all; clc
Nsubj=24; 
%% load the file
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
    %% calculate the Bio Kinematics
    Ns=12;
    Arm_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    Ns=6;
    Chest_Ang=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    % calculate the joint angle using the specific biostamp data
    DataNum=min(size(Arm_Ang_L),size(Chest_Ang));  % Make two sensor's data into equal length
    Arm_Flex_Bio_temp=-Arm_Ang_L(1:DataNum(1),3)+Chest_Ang(1:DataNum(1),1);
    % Arm_Flex_Bio_temp=Arm_Ang_L(1:DataNum(1),3);
    Arm_Flex_Bio=resample(Arm_Flex_Bio_temp,p,q);
    % Arm_Addu_Bio_temp=Arm_Ang_L(1:DataNum(1),2)+Chest_Ang(1:DataNum(1),3);
    Arm_Addu_Bio_temp=Arm_Ang_L(1:DataNum(1),2);
    Arm_Addu_Bio=resample(Arm_Addu_Bio_temp,p,q);
    Arm_Rot_Bio_temp=Arm_Ang_L(1:DataNum(1),1)+Chest_Ang(1:DataNum(1),2);
    % Arm_Rot_Bio_temp=Arm_Ang_L(1:DataNum(1),1);
    Arm_Rot_Bio=resample(Arm_Rot_Bio_temp,p,q);
    %% load the OpenSim Kinematics
    Arm_Flex_OS=ik_data{Nt,2}(:,32); % 32：Arm_flex_l
    Arm_Addu_OS=ik_data{Nt,2}(:,33); % 9：Arm_add_l
    Arm_Rot_OS=ik_data{Nt,2}(:,34); % 10：Arm_add_l

    p0=num(Nt,5); p5=num(Nt,6); SF=num(Nt,13); EF=num(Nt,15);
    [Arm_Flex_Bio, Arm_Flex_OS]=ScaleSignal(p0,SF,EF,Arm_Flex_OS,Arm_Flex_Bio);
    [Arm_Addu_Bio, Arm_Addu_OS]=ScaleSignal(p0,SF,EF,Arm_Addu_OS,Arm_Addu_Bio);
    [Arm_Rot_Bio, Arm_Rot_OS]=ScaleSignal(p0,SF,EF,Arm_Rot_OS,Arm_Rot_Bio);

    %% flexion
    % vOS=Arm_Flex_OS;    vBio=Arm_Flex_Bio;
    % JN=15;
    %% adduction
    % vOS=Arm_Addu_OS;    vBio=Arm_Addu_Bio;
    % JN=17;
    %% rotation
    vOS=Arm_Rot_OS;    vBio=Arm_Rot_Bio;
    JN=19;
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
plot(Arm_Ang_L);
figure;
plot(Chest_Ang);
figure;
plot(Arm_Flex_OS);