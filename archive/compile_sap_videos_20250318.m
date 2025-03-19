
%%% save all videos from UPDRS recordings from SAP project in one place
 

sapdir = '/projectnb/busplab/Experiments/SAP'; % videos within this top level SAP project folder
compile_dir = '/projectnb/busplab/Experiments/ieeg-stut/sap-videos'; % put the sap videos here

mkdir(compile_dir); 

dd = struct2table(dir(sapdir)); dd = dd.name; 
subdirlist = dd(contains(dd,'sub-')); 
nsubdirs = length(subdirlist);

for isubdir = 1:nsubdirs
    subdir = subdirlist{isubdir};
    dd = struct2table(dir(sapdir)); dd = dd.name; 
    seslist = dd(contains(dd,'ses-')); 
    for ses = seslist
        motordir = [sapdir, filesep, subdir, filesep, ses, filesep, 'beh', filesep, 'motor']; 
        % dd = struct2table(dir(motordir)); dd = dd.name; 
        copyfile(motordir, compile_dir);
    end
end




% fprintf(['\n Finished all subjects \n']) 







