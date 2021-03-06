% spm12w r6225
% Parameters file for 1st level glm analysis and 2nd level rfx analysis
% Last updated: April, 2015
% =======1=========2=========3=========4=========5=========6=========7=========8

% User name
glm.username = 'ddw';

% Paths and names
glm.study_dir = '/lab/neurodata/ddw/tutorial_data';
glm.prep_name = 'epi_norm';
glm.glm_name = 'glm_tutorial_para';
glm.ons_dir  = 'tutorial';

% GLM Conditions (seperate by commas)
glm.events     = {'human','animal','vegetable','mineral'};
glm.blocks     = {};
glm.regressors = {};

% GLM Parametric modualtors - Special keyword: 'allthethings'
glm.parametrics = {'humanxattract','humanxlike'}; 

% GLM Model Inclusions - 1=yes 0=no
glm.include_run = 'all'; % Specify run to model: 'all' or runs (e.g. [1,3])

% GLM Contrasts - Numeric contrasts should sum to zero unless vs. baseline
%               - String contrasts must match Condition names.
%               - String contrast direction determine by the placement of 'vs.'
%               - Special keywords: 'housewine' | 'fir_bins' | 'fir_hrf'
% Note that the housewine's allVSbaseline will skip pmods but is not savy
% to complex designs (i.e., where you want all conditions VS baseline but
% not your user supplied regressors under glm.regressors, so in those cases
% you should create your own allVSbaseline and refuse the housewine). 
glm.con.housewine = 'housewine';
glm.con.humVSveg  = [1 0 0 0 -1];
glm.con.aniVSmin  = [0 0 0 1 0 -1];
glm.con.minANDhum = 'mineral human';
glm.con.humVSall  = 'human vs. animal vegetable mineral';

% RFX Specification
glm.rfx_name = 'rfx_tutorial_para';
glm.rfx_conds = {'allVSbaseline','humVSall'};