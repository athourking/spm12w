function roidata = spm12w_roitool(varargin)
% spm12w_roitool('roi_file','sids','coords')
%
% Inputs
% ------
% roi_file: File specifying the parameters for roi analysis and specification
%           (e.g., 'roi_tutorial.m'). If the path is left unspecified,
%           spm12w_roitool will look in the scripts directory.
%
% sids:     A cell array of Subject IDs for roi analysis. If left unspecified
%           a dialog box will appear asking the user to select subjects. Use 
%           the keyword 'allsids' and all subjects in the specified 
%           glm directory will be used for roi analysis. <optional>
%
% coords:   Cell array of coordinates and roi sizes for manually specified ROI. 
%           These will replace any roi specifications in the roi parameters
%           file. <optional> 
%
% Returns
% -------
% roidata:  A structure containing the fields xxxx. 
%
% spm12w_roitool will generate spherical rois or use pre-existing img masks
% to extract parameter estimates from previously generated contrast files during
% 1st level glm analysis. These parameter estimates may then be submitted to
% a number of simple statistcal tests. These are: 
%       - descriptives: means, standard deviations, min/max values.
%       - ttest1: one-sample t-test across participants
%       - ttest2: idependent sample t-test across participants
%       - correl1: correlation between parameter estimates and subject variables
%       - correl2: same as correl1 but split by group.
%
% Variables for each sid are required for ttest2 and correl1 and correl2
% and are to be specified in a variable file references in the roi
% parameters file (i.e., roi.var_file).
%
% The first argument is the name of a roi parameters file (e.g., roi_tutorial.m).
% The second argument (optional) is a cell array of sids (can be left blank to 
% manually select them). The third argument allows the user to manually 
% specify an roi thereby overriding the rois specified in the roi paramters
% file. Parameter estimates for each specified contrast will be saved to a
% tab delimited txt file formatted for importing into any offline
% statistical software (e.g., R, spss, etc.). A seperate text file
% containing results of basic statistics will also be saved to the roi dir.
%
% Note: If you choose to use the sphere rois genereated by spm12w_roitool
% be aware that these are in the space defined by the standard_img_3x3x3.nii
% file. This file is in the same space as our regular pipeline but if you
% decide to resample to a different voxel size or space, the mask will no
% longer be appropriate. You can always verify that the mask is appropriate
% using checkreg with the img files generated by spm8w_roitool.

% Examples:
%
%       >>spm12w_roitool
%       >>spm12w_roitool('roi_file', './scripts/username/roi_tutorial.m', ...
%                        'sids', {'allsids'}, ...
%                        'coords',{[30,30,21],8; [22,22,19],8})
%
% # spm12w was developed by the Wagner, Heatherton & Kelley Labs
% # Author: Dylan Wagner | Created: January, 2010 | Updated: April, 2015
% =======1=========2=========3=========4=========5=========6=========7=========8

% Parse inputs
args_defaults = struct('roi_file','','sids','','coords','');
args = spm12w_args('nargs',0, 'defaults', args_defaults, 'arguments', varargin);

% Load roi parameters
roi = spm12w_getp('type','roi', 'para_file',args.roi_file);

% Setup directories for roi analysis. 
spm12w_dirsetup('dirtype','roi','params',roi);

% Check for cell in case user provided allsids as string.
if ~iscell(args.sids) && ~isempty(args.sids)
    args.sids = cellstr(args.sids);
end

% If sids argument was not provided, open dialog window to get sids.
% If sids argument contained the keyword 'allsids', then get all sids.
% Since we should only do rfx on computed glms, let's look in rfx.glmdir.
if isempty(args.sids)
    args.sids = spm12w_getsid(roi.glmdir);
elseif numel(args.sids) == 1 && strcmp(args.sids,'allsids')
    args.sids = cellstr(ls(fullfile(roi.glmdir,'s*')))';
end

% Check that all appropriate glm dirs and contrasts exist and build up a
% cell array of files per subject per glm condition. Technically this 
% need not be per subject, but just in case different subjects got different
% glms somehow, we should figure out the appropriate con file on a subject
% by subject basis. 
roi.condsfiles = {}; % Init var for confilenames associated with roi.conds
% Verify the glms and build up the roi.condsfiles variable.
spm12w_logger('msg',['[DEBUG] Verifying that glm and contrasts exist for ',...
                    'each subject.'],'level',roi.loglevel)
for sid = args.sids
    if ~exist(fullfile(roi.glmdir,sid{1},'SPM.mat'),'file')           
        spm12w_logger('msg',sprintf(['[EXCEPTION] glm ''%s'' for subject %s ', ...
                      'does not exist or is not estimated.'],roi.glm_name, ...
                      sid{1}),'level',roi.loglevel);
        error(['Glm ''%s'' for subject %s does not exist or is not estimated.',...
              'Aborting...'],roi.glm_name,sid{1})      
    else
        for cond = roi.conds
            % Load the SPM file for the GLM (do this subjectwise)
            SPM_ = load(fullfile(roi.glmdir,sid{1},'SPM.mat'));
            % Find the index of the rfx contrast in the SPM.xCon
            conidx = find(strcmp({SPM_.SPM.xCon.name},cond{1}));
            if ~isempty(conidx)
                % Use the index to get the filename of the con file for that sid
                roi.condsfiles{end+1,1} = sid{1};
                roi.condsfiles{end,2} = cond{1};
                roi.condsfiles{end,3} = fullfile(roi.glmdir,sid{1},...
                                              SPM_.SPM.xCon(conidx).Vcon.fname);
            else
                spm12w_logger('msg',sprintf(['[EXCEPTION] condition ''%s'' ',...
                      'for subject %s is not a part of the glm ''%s''.'],...
                      cond{1},sid{1},roi.glm_name),'level',roi.loglevel);
                error(['Condition ''%s'' for subject %s is not part of ',...
                       'glm ''%s''. Aborting...'],cond{1},sid{1},roi.glm_name);      
            end
        end
    end
end

%
