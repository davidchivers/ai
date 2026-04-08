function exported = export_structural_endpoints()
%EXPORT_STRUCTURAL_ENDPOINTS
% Export lightweight endpoint .mat files for the extension pipeline from
% raw legacy SS_iter files when they are available locally.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
extension_dir = fileparts(this_dir);
project_dir = fileparts(extension_dir);
input_dir = fullfile(extension_dir, 'input');

if ~exist(input_dir, 'dir')
    mkdir(input_dir);
end

exported = struct();
exported.baseline = export_one(project_dir, input_dir, 'baseline');
exported.boom = export_one(project_dir, input_dir, 'boom');
end

function info = export_one(project_dir, input_dir, label)
info = struct('label', label, 'status', 'missing', 'source_path', '', 'output_path', '');

source_path = locate_source(project_dir, input_dir, label);
if isempty(source_path)
    return;
end

raw = load(source_path);

if isfield(raw, 'price') && isfield(raw, 'vote_support')
    endpoint = struct('price', raw.price, 'vote_support', raw.vote_support);
elseif isfield(raw, 'a_price') && isfield(raw, 'totalvote')
    endpoint = struct('price', raw.a_price, 'vote_support', raw.totalvote);
else
    info.status = 'unrecognized_format';
    info.source_path = source_path;
    return;
end

output_name = [label '_endpoint.mat'];
output_path = fullfile(input_dir, output_name);
price = endpoint.price; %#ok<NASGU>
vote_support = endpoint.vote_support; %#ok<NASGU>
save(output_path, 'price', 'vote_support');

info.status = 'exported';
info.source_path = source_path;
info.output_path = output_path;
end

function source_path = locate_source(project_dir, input_dir, label)
suffix = '';
if strcmpi(label, 'boom')
    suffix = '_boom';
end

candidates = {
    fullfile(input_dir, ['SS_iter' suffix '.mat'])
    fullfile(project_dir, 'code', 'steadystate', ['SS_iter' suffix '.mat'])
    };

source_path = '';
for i = 1:numel(candidates)
    if exist(candidates{i}, 'file')
        source_path = candidates{i};
        return;
    end
end
end
