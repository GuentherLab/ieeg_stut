%% Check whether the number of consequtive same collapsed conditions exceeds 2 in the stim lists 

load('StimListsRev2.mat')

for stimList = 1:5
    fprintf('For stim list %d: \n', stimList)
    consecutive = 0;
    for i = 1:(length(StimListsRev2.Collapsed())-1)
        cond1 = StimListsRev2.Collapsed{i,stimList};
        cond2 = StimListsRev2.Collapsed{i+1,stimList};
        %sprintf('comparing %s and %s', cond1, cond2)
        if StimListsRev2.Collapsed{i,stimList} == StimListsRev2.Collapsed{i+1,stimList}
            consecutive = consecutive + 1;
            if consecutive > 1
                disp('More than 3 consecutive collapsed conditions')
                return
            end
        else
            consecutive = 0;
        end
    end
    disp('Clear!')
    disp(" ")
end
disp('All Clear!')