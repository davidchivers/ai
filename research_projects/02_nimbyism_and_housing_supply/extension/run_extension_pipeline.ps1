$matlabScript = @"
addpath('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extension/matlab');
pipeline = run_extension_pipeline();
if isfield(pipeline, 'structural') && isfield(pipeline.structural, 'status')
    disp(['STRUCTURAL_STATUS=' pipeline.structural.status]);
end
"@

matlab -batch $matlabScript
