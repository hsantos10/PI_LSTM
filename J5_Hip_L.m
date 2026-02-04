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
    Ns=11;
    Pelvis_Ang=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns}); % remove the drift
    Ns=3;
    Thign_Ang_L=GetBioAngle(BioGyro{Nt,Ns}(:,2:4),LinearDrift{Nsubj,Ns});% remove the drift
    % calculate the joint angle using the specific biostamp data
    DataNum=min(size(Thign_Ang_L),size(Pelvis_Ang));  % Make two sensor's data into equal length
    Hip_Flex_Bio_temp=-Thign_Ang_L(1:DataNum(1),3)-Pelvis_Ang(1:DataNum(1),1);
    % Hip_Flex_Bio_temp=-Thign_Ang_L(1:DataNum(1),3)+Thign_Ang_L(1:DataNum(1),2)-Pelvis_Ang(1:DataNum(1),1);
    Hip_Flex_Bio_L=resample(Hip_Flex_Bio_temp,p,q);
    % Hip_Addu_Bio_temp=-Thign_Ang_L(1:DataNum(1),2)+Pelvis_Ang(1:DataNum(1),3);
    Hip_Addu_Bio_temp=-Thign_Ang_L(1:DataNum(1),2);
    Hip_Addu_Bio_L=resample(Hip_Addu_Bio_temp,p,q);
    % Hip_Rot_Bio_temp=Thign_Ang_L(1:DataNum(1),1)+Pelvis_Ang(1:DataNum(1),2);
    Hip_Rot_Bio_temp=Pelvis_Ang(1:DataNum(1),2);
    % Hip_Rot_Bio_temp=Thign_Ang_L(1:DataNum(1),1);
    Hip_Rot_Bio_L=resample(Hip_Rot_Bio_temp,p,q);
    %% load the OpenSim Kinematics
    Hip_Flex_OS_L=ik_data{Nt,2}(:,16); % 16：Hip_flex_l
    Hip_Addu_OS_L=ik_data{Nt,2}(:,17); % 17：Hip_add_l
    Hip_Rot_OS_L=ik_data{Nt,2}(:,18); % 17：Hip_add_l

    p0=num(Nt,5); p5=num(Nt,6); SF=num(Nt,13); EF=num(Nt,15);
    [Hip_Flex_Bio, Hip_Flex_OS]=ScaleSignal(p0,SF,EF,Hip_Flex_OS_L,Hip_Flex_Bio_L);
    [Hip_Addu_Bio, Hip_Addu_OS]=ScaleSignal(p0,SF,EF,Hip_Addu_OS_L,Hip_Addu_Bio_L);
    [Hip_Rot_Bio, Hip_Rot_OS]=ScaleSignal(p0,SF,EF,Hip_Rot_OS_L,Hip_Rot_Bio_L);
    %% flexion
    % vOS=Hip_Flex_OS;    vBio=Hip_Flex_Bio;
    % JN=9;
    %% adduction
    % vOS=Hip_Addu_OS;    vBio=Hip_Addu_Bio;
    % JN=11;
    %% rotation
    vOS=Hip_Rot_OS;    vBio=Hip_Rot_Bio;
    JN=13;
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
plot(Thign_Ang_L);
figure;
plot(Pelvis_Ang);
figure;
plot(Hip_Flex_OS);