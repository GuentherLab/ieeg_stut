'SAPstimListGenerator.m'
Script used to generate run trial/stim lists with no repetitions for the SAP study.
When run the script will generate a ramdomized trial run following certain conditions.
The script also has a section detailing how to combine the newly generated list to the
'master' meta-data strcut containing the other stim lists. 
The following will detail what each section does and their purpose:

%% Generate Condition Order %%
Creates random permutations of the experimental conditions 'A','B','C','D','E','F' and 'G' 
until a run where there are no consecutive repeats of the same conditions is generated.
[NOTE: while the script currently does this for the regular experimantal conditions, it does
not guarentee it for the collapsed conditions ('A','B','C','D'), for now, if this occurs
simply re-run the script (once a 'master' stim list is created, function 'repeatCollapsedCheck()'
can be used to check this for collapsed conditions)]
Variables to note:
	-'ntrialsperrun', determines how many trial are present for each condition in a run.
	-'tuns2gen', determines the number of runs to generate.
	-'maxrepeats', determines the max number of consecutive repeats allowed in a sequence 
                       of conditions.

%% Turn conditions order into arrays %%
Main purpose of this section is to use the condition sequence generated in the previous section
and create the corresponding 'Collapsed' and 'Condition Label' version of the run.
-The 'Collapsed' version of the condition sequence only has 4 experimental conditions 
 'A','B','C' and 'D'. The experimental conditions 'C' and 'D' (F1 related) are treated 
  as 'C' and the conditions 'E' and 'F' (F0 related) are treated as 'D'.
-The 'Condition Label' version condition sequence uses the labels 'Base', 'N0', 'N1', 'U1', 
 'DI', 'U0', and 'D0' for the corresponding conditions 'A', 'B', 'C', 'D', 'E', 'F' and 'G'.
The script then stores the generated sequences in a Matlab structure 'StimLists'.

%% Use condition order to create corresponding stim lists %%
This section of the script uses the condition sequence generated earlier to create a 
stimulus list that adheres the following rules.
-The stims used are 'Beck','Bet','Deck', 'Debt', 'Peck', 'Pep', 'Ted', 'Tech','Met' and 'yyy'
-The stim 'yyy' is only for baseline conditions.
-The same stimulus may not appear right after itself.
-Each condition must have an even distribution of each stimulus.

Due to it's reliance on randomness, this section may re-run multiple times as it is 
possible for the script to reach a state where it is impossible for it to adhere to the mentioned 
rules. For example, say that a stimulus is being randomly chosen for condition D, and that this  
condition has had 6/6 instances of 'BED', 6/6 instances of 'ED' and 5/6 instances of 'HEAD'. The
go to choice would be 'HEAD' as it allows for the even distribution of stimuli, however, say that 
the previous stimulus chosen for a different condition C was also 'HEAD'. This would originally
cause the section to halt as it will either break the subsequent same stimulus rule, or the even
distribution rule. 
When this occurs, the script will automatically display the message 'Was not able to 
satisfy all stimuli conditions for this sequence and re-run until it manages to finish 
and display 'Complete!' message.
Once complete, the code will add the stim list into the Matlab structure 'StimLists' and will 
save this structure under the name chosen on line 466 [>> save('StimList8.mat','StimLists'); ].

%% Converting 'StimLists' into correct text format %%
Section uses the 'StimLists' structure created in the previous section to create a
correctly structured '.txt' version of the stimulus list which has the stimulus in the first column 
and the corresponding condition label in the second.
[NOTE: you will need to make sure to load the same 'StimList' you created in the previous 
section which is named on line 482 (>> filename = 'StimList8.txt';) ].


%% Joining different StimList# structures into %%
Section is used to combine several StimList structures made in the previous sections into one
large 'master' StimList structure which contains metadata on all of the 'StimLists'.