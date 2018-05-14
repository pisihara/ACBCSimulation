clear all; close all; format long;

%% Set Survey Parameters
surveyfile='ACBC1a4.xlsx'; % Name of Survey Data File
N=10; %%number of respondents
Amin=2; %%min number of attributes to vary from BYO
Amax=2; %%max number of attributes to vary from BYO

%numMCMCiterations=100;  %% number of iterations in MC profile estimation

%% Create a New Survey and Specifiy the Attributes
Survey1=survey;  %% Create  new survey object
Survey1.numberAttributes=4; %% Specify the number of attributes in the survey
for i=1:Survey1.numberAttributes
Survey1Attr(i,1)=attribute; %% Create attributes
Survey1Attr(i,1).numberLevels=3; %% all attributes have 3 levels
end
%% Set Population Partworth Distibution
NA=Survey1.numberAttributes; % NA is abbreviation for Number of attributes
for i=1:NA
    for j=1:Survey1Attr(i,1).numberLevels
    PopAttr(i,j)=populationAttribute;  %% Distribution of ith attribute, jth level
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PART ONE: ACBC SURVEY SIMULATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Specify population means and variances of attribute i level j:  
 PopAttr(1,1).Mean=110;PopAttr(1,2).Mean=100;PopAttr(1,3).Mean=-210;
 PopAttr(1,1).Sd=60;PopAttr(1,2).Sd=60;PopAttr(1,3).Sd=60;
 PopAttr(2,1).Mean=50;PopAttr(2,2).Mean=40;PopAttr(2,3).Mean=-90;
 PopAttr(2,1).Sd=4;PopAttr(2,2).Sd=4;PopAttr(2,3).Sd=4;
 PopAttr(3,1).Mean=20;PopAttr(3,2).Mean=10;PopAttr(3,3).Mean=-30;
 PopAttr(3,1).Sd=2;PopAttr(3,2).Sd=1;PopAttr(3,3).Sd=3;
 PopAttr(4,1).Mean=2;PopAttr(4,2).Mean=1;PopAttr(4,3).Mean=-3;
 PopAttr(4,1).Sd=2;PopAttr(4,2).Sd=1;PopAttr(4,3).Sd=1;
 
 %% Set Respondent Partworth Functions
for n=1:N
    Respondent(n,1)=respondent;  %%create respondents
    for i=1:NA
    Respondent(n,1).revealedMusthave(i,1)=0; %% attribute i's must have level; used in screening stage
    Respondent(n,1).revealedUnaccept(i,1)=0; %% attribute i's totally unacceptable level
    end

%% Randomly assign partworth levels and compute BYO/musthave/ by extremely hi/lo partowrth utilities
    for i=1:NA
    for j=1:Survey1Attr(i,1).numberLevels
    Respondent(n,1).partworth(i,j)=sample(PopAttr(i,j));
    end
    [Max(i,1),Respondent(n,1).BYO(i,1)]=max(Respondent(n,1).partworth(i,:));  %BYO is level with highest utility
    %%if highest attribute level is 10 sd above mean, 
    %%it becomes a "must have" level
    if Max(i,1)>PopAttr(i,1).Mean+1000*PopAttr(i,1).Sd  
       Respondent(n,1).musthave(i,1)=Respondent(n,1).BYO(i,1);
    else
       Respondent(n,1).musthave(i,1)=0;
    end
    %%if lowest attribute level is 5 sd below mean, 
    %%it becomes a "totally unacceptable" level
    [Min(i,1),AYO(i,1)]=min(Respondent(n,1).partworth(i,:));
        if Min(i,1)<PopAttr(i,1).Mean-1000*PopAttr(i,1).Sd
           Respondent(n,1).unaccept(i,1)=AYO(i,1);
        else
             Respondent(n,1).unaccept(i,1)=0;
        end
    end


%% GENERATE SURVEY SIMULATION PROFILES

%% Simulate Screening Stage
clear viewedProfiles;
viewedProfiles(1,1)=0;viewedProfiles(2,1)=0;viewedProfiles(3,1)=0;viewedProfiles(4,1)=0;
T1=8;  %% Number of questions in the screening stage

  for t=1:T1  %%keep track of questions
      q1=NA*(t-1)+1;
      q2=NA*t;
     for i=1:3  %%generate 3 question profiles 
    [viewedProfiles,qlevels(q1:q2,i)]=profile(viewedProfiles,Amin,Amax,NA,Respondent(n,1),Survey1Attr,1);  %%choice 0 allows must have and unacceptable levels
     end
    for i=1:3  %%compute score for ith profile
     score(1,i)=Respondent(n,1).partworth(1,qlevels(q1,i))+Respondent(n,1).partworth(2,qlevels(q1+1,i))+Respondent(n,1).partworth(3,qlevels(q1+2,i))+Respondent(n,1).partworth(4,qlevels(q1+3,i));
     end
    [sum,Respondent(n,1).surveyresponses(t,1)]=max(score);
    Decision=Respondent(n,1).evaluate(qlevels(q1:q2,:),NA,3);
    xlswrite(strcat('temp1',surveyfile),qlevels(q1:q2,:),num2str(n),strcat('A',num2str(q1),':C',num2str(q2)));
    xlswrite(strcat('temp1',surveyfile),Respondent(n,1).surveyresponses(t,1),num2str(n),strcat('D',num2str(q1)));
    xlswrite(strcat('temp1',surveyfile),sum, num2str(n),strcat('E',num2str(q1)));
    xlswrite(strcat('temp1',surveyfile),Decision,num2str(n),strcat('F',num2str(q1),':H',num2str(q2)));
  end



 %% Determine must have / totally unacceptable levels 
 Respondent(n,1).surveydata=xlsread(strcat('temp1',surveyfile),num2str(n),strcat('A1:H',num2str(q2)));  %%specify location of survey data
 Respondent(n,1)=Respondent(n,1).processChoices(NA,3,1,T1); %%Determines revealedMusthave and revealedUnaccept 
 

%% Simulate the Tournament
clear viewedProfiles;
viewedProfiles(1,1)=0;viewedProfiles(2,1)=0;viewedProfiles(3,1)=0;viewedProfiles(4,1)=0;
masterProfiles(1,1)=0; masterProfiles(2,1)=0; masterProfiles(3,1)=0; masterProfiles(4,1)=0; masterProfiles(5,1)=0;
%% Set up the Field of Profiles
T2=8; %% Number of 2 profile matches to begin the tournament

   for t=1:T2
     q1=NA*(t-1)+1;
     q2=NA*t;
     for i=1:2  %% generate question profiles
     [viewedProfiles, qlevels(q1:q2,i)]=profile(viewedProfiles,Amin,Amax,NA,Respondent(n,1),Survey1Attr,1);  %%choice 1 observes must have and unacceptable levels
     end
     for i=1:2  %%compute score for ith profile
     qualscore(1,i)=Respondent(n,1).partworth(1,qlevels(q1,i))+Respondent(n,1).partworth(2,qlevels(q1+1,i))+Respondent(n,1).partworth(3,qlevels(q1+2,i))+Respondent(n,1).partworth(4,qlevels(q1+2,i));
     end
    [sum,Respondent(n,1).surveyresponses(t,1)]=max(qualscore);
    xlswrite(strcat('temp2',surveyfile),qlevels(q1:q2,:),num2str(n),strcat('A',num2str(q1),':B',num2str(q2)));
    xlswrite(strcat('temp2',surveyfile),Respondent(n,1).surveyresponses(t,1),num2str(n),strcat('C',num2str(q1)));
   end   

   
 % Update Profile Rankings
 [masterProfiles,winners0,winners1,winners2,winners3]=addTournament(surveyfile, Respondent(n,1),n,NA,masterProfiles);
  

end

%   winners0=xlsread(strcat('temp2',surveyfile),num2str(n),'A1:C32');
%   winners1=winners(Respondent(n,1),winners0,NA,8);  %% quarters
% %   
%   for profile=2:2:8
%     for i=1:NA
%      windata(4*(profile/2-1)+i,1)=winners0(4*(profile-2)+i,winners0(4*(profile-2)+1,3));
%      windata(4*(profile/2-1)+i,2)=winners0(4*(profile-1)+i,winners0(4*(profile-1)+1,3));       
%     end
%     for i=1:2  %%compute score for ith profile
%      score(1,i)=Respondent.partworth(1,windata(4*(profile/2-1)+1,i))+Respondent.partworth(2,windata(4*(profile/2-1)+2,i))+Respondent.partworth(3,windata(4*(profile/2-1)+3,i))+Respondent.partworth(4,windata(4*(profile/2-1)+4,i));
%     end
%      [~,windata(4*(profile/2-1)+1,3)]=max(score);
%  end 
  


% masterProfiles(:,1)=[];
% sortedProfiles=sort(transpose(masterProfiles),4); %%%%SHOULD THIS 4 BE A 5 OR 6????? ALSO LINE 131 6 BE A 5????
% sortedProfiles=transpose(sortedProfiles);
% for i=1:length(sortedProfiles(1,:))
%   sortedProfiles(5,i)=PopAttr(1,sortedProfiles(1,i)).Mean+PopAttr(2,sortedProfiles(2,i)).Mean+PopAttr(3,sortedProfiles(3,i)).Mean+PopAttr(4,sortedProfiles(4,i)).Mean;
%  end
% %% Record Data   
% xlswrite(surveyfile,transpose(sortedProfiles),'Sorted');
% xlswrite(surveyfile,masterProfiles,'Master');


%% Tournament Profiles
% tournamentProfiles(:,1)=[0;0;0;0];
% tournamentProfiles(:,1)=[];
% winners1(:,3)=[];
% for i=1:4
% tournamentProfiles=[tournamentProfiles,winners1(4*(i-1)+1:4*(i-1)+4,1),winners1(4*(i-1)+1:4*(i-1)+4,2)]
% end
% winners2(:,3)=[];
% for i=1:2
% tournamentProfiles=[tournamentProfiles,winners2(4*(i-1)+1:4*(i-1)+4,1),winners2(4*(i-1)+1:4*(i-1)+4,2)]
% end
% winners3(:,3)=[];
% tournamentProfiles=[tournamentProfiles,winners3(:,1),winners3(:,2)]


 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% PART TWO: MC PARTWORTH ESTIMATION %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  
% %% Record Partworth for each run and each respondent n
%  step11(run,n)=Respondent(n,1).partworth(1,1); step12(run,n)=Respondent(n,1).partworth(1,2); step13(run,n)=Respondent(n,1).partworth(1,3); 
%  step21(run,n)=Respondent(n,1).partworth(2,1); step22(run,n)=Respondent(n,1).partworth(2,2); step23(run,n)=Respondent(n,1).partworth(2,3);
%  step31(run,n)=Respondent(n,1).partworth(3,1); step32(run,n)=Respondent(n,1).partworth(3,2); step33(run,n)=Respondent(n,1).partworth(3,3);
%   step41(run,n)=Respondent(n,1).partworth(4,1); step42(run,n)=Respondent(n,1).partworth(4,2); step43(run,n)=Respondent(n,1).partworth(4,3);
% 
%  for iteration=1:numMCMCiterations
%  x(iteration,1)=iteration;   %% keep track of MCM iteration number
%  end
%    
% %% Initialize Partworth Estimates
% for i=1:3
%  for j=1:Survey1Attr(i,1).numberLevels
%   theta1(i,j,1)=-1+2*rand;
%   theta2(i,j,1)=theta1(i,j,1)-25+50*rand;
%  end
% end
% 
% %% UPDATE PARTWORTH ESTIMATION BY CORRECT TOURNAMENT PREDICTION
% for iteration =1:numMCMCiterations-1  %% work on improving 1 level at a time   
%    for i=1:3
%    for j=1:Survey1Attr(i,1).numberLevels
%    P(1,iteration)=0; P(2,iteration)=0;
%      last1=theta1(:,:,iteration);
%      last2=theta2(:,:,iteration);
%   %% Compute the number of correctly predicted tournament matches
%   for k=1:length(tournamentProfiles(1,:))/2
%    profile1(:,1)=tournamentProfiles(:,2*(k-1)+1);
%    profile2(:,1)=tournamentProfiles(:,2*(k-1)+2);
%   end
%    P(1,iteration)=P(1,iteration)+predict(profile1,profile2,Respondent(n,1).partworth,theta1,iteration);
%    P(2,iteration)=P(2,iteration)+predict(profile1,profile2,Respondent(n,1).partworth,theta2,iteration);
%  %% Update the partworth approximation of attribute i level j
%   if P(1,iteration)==0 | P(2,iteration)> P(1,iteration)
%       theta1(:,:,iteration+1)=last2;   
%   else
%       theta1(:,:,iteration+1)=last1;
%   end
%   new1=theta1(:,:,iteration+1);
%   theta2(:,:,iteration+1)=new1;
%   leveltochange=new1(i,j);
%   theta2(i,j,iteration+1)=leveltochange-25+50*rand;      
%    end
%    end
%    numcorrect(run,n)=P(1,iteration); %% final number of correct tournament predictions
% end
% 
% %% Record Final Partworth Estimates
%   partworth11(run,n)= theta1(1,1,iteration); partworth12(run,n)= theta1(1,2,iteration); partworth13(run,n)= theta1(1,3,iteration); 
%   partworth21(run,n)= theta1(2,1,iteration); partworth22(run,n)= theta1(2,2,iteration); partworth23(run,n)= theta1(2,3,iteration); 
%   partworth31(run,n)= theta1(3,1,iteration); partworth32(run,n)= theta1(3,2,iteration); partworth33(run,n)= theta1(3,3,iteration); 
%     partworth41(run,n)= theta1(4,1,iteration); partworth42(run,n)= theta1(4,2,iteration); partworth43(run,n)= theta1(4,3,iteration); 
% 
% end
%  m11(n,1)=mean(partworth11(:,n));m12(n,1)=mean(partworth12(:,n));m13(n,1)=mean(partworth13(:,n));
% m21(n,1)=mean(partworth21(:,n));m22(n,1)=mean(partworth22(:,n));m23(n,1)=mean(partworth23(:,n));
% m31(n,1)=mean(partworth31(:,n));m32(n,1)=mean(partworth32(:,n));m33(n,1)=mean(partworth33(:,n));
% m41(n,1)=mean(partworth41(:,n));m42(n,1)=mean(partworth42(:,n));m43(n,1)=mean(partworth43(:,n));
% 
% 
% %% Output Plot of Partworth Estimation across runs
%  figure  %% Attribute A plot
%  axis([0 totalruns -30  30]);
%  title('Attribute A Partworth Estimation');
%  plot(Run,numcorrect,'k');
%  hold on;
%  plot(Run,partworth11,'--r'); hold on; plot(Run,.1*step11,'r'); hold on; 
%  plot(Run,partworth12,'--b');  hold on; plot(Run,.1*step12,'b'); hold on;
%  plot(Run,partworth13,'--g');hold on; plot(Run,.1*step13,'g'); hold on;
%  xlabel('run #'); ylabel('scaled utility');
%  legend('Number Correct Tournament Predictions','estimated A1','A1','estimated A2','A2','estimated A3','A3','estimated A4','A4','estimated A5','A5','location','southeastoutside');
%   
%  figure  %% Attribute B plot
%  axis([0 totalruns  -5   18]);
%  title('Attribute B Partworth Estimation');
%  plot(Run,numcorrect,'k');
%  hold on;
%  plot(Run,partworth21,'--r'); hold on;  plot(Run,.1*step21,'r');  hold on; 
%  plot(Run,partworth22,'--g'); hold on;  plot(Run,.1*step22,'g');  hold on;
%  plot(Run,partworth23,'--b'); hold on;  plot(Run,.1*step23,'b');  hold on;
%  xlabel('run #');ylabel('scaled utility');
%  legend('Number Correct Tournament Predictions','estimated B1','B1','estimated B2','B2','estimated B3','B3','estimated B4','B4','location','southeastoutside');
%    
%  figure  %% Attribute C plot
%   axis([0 totalruns -30  30]);
%  title('Attribute C Partworth Estimation');
%  plot(Run,numcorrect,'k');ylabel('scaled utility');
%  hold on;
%  plot(Run,partworth31,'--r'); hold on; plot(Run,.1*step31,'r'); hold on;
%  plot(Run,partworth32,'--b'); hold on; plot(Run,.1*step32,'b'); hold on;
%  plot(Run,partworth33,'--g'); hold on; plot(Run,.1*step33,'g'); hold on;
%  legend('Number Correct Tournament Predictions','estimated C1','C1','estimated C2','C2','estimated C3','C3','location','southeastoutside');
%  
%  figure  %% Attribute D plot
%   axis([0 totalruns -30  30]);
%  title('Attribute D Partworth Estimation');
%  plot(Run,numcorrect,'k');ylabel('scaled utility');
%  hold on;
%  plot(Run,partworth41,'--r'); hold on; plot(Run,.1*step41,'r'); hold on;
%  plot(Run,partworth42,'--b'); hold on; plot(Run,.1*step42,'b'); hold on;
%  plot(Run,partworth43,'--g'); hold on; plot(Run,.1*step43,'g'); hold on;
%  legend('Number Correct Tournament Predictions','estimated D1','D1','estimated D2','D2','estimated D3','CD','location','southeastoutside');
% 
%  
