function pipeline = run_extension_pipeline()
%RUN_EXTENSION_PIPELINE
% Run all currently available NIMBY extension experiments and write a
% lightweight markdown summary to extension/results/.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
extension_dir = fileparts(this_dir);
results_dir = fullfile(extension_dir, 'results');
input_dir = fullfile(extension_dir, 'input');

if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
if ~exist(input_dir, 'dir')
    mkdir(input_dir);
end

pipeline = struct();
pipeline.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

pipeline.toy = run_anticipated_demographics_re_toy();
pipeline.export = export_structural_endpoints();
pipeline.structural = run_anticipated_demographics_re_structural();

summary_path = fullfile(results_dir, 'extension_pipeline_summary.md');
write_summary(summary_path, pipeline);

disp(['Extension pipeline summary written to ' summary_path]);
end

function write_summary(summary_path, pipeline)
fid = fopen(summary_path, 'w');
if fid < 0
    error('Could not open summary file for writing: %s', summary_path);
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Extension pipeline summary\n\n');
fprintf(fid, '- Run timestamp: `%s`\n', pipeline.timestamp);
fprintf(fid, '- Toy benchmark: `ok`\n');
fprintf(fid, '- Structural benchmark status: `%s`\n\n', get_status(pipeline.structural));

fprintf(fid, '## Toy benchmark\n\n');
fprintf(fid, '- `theta_ss = %.4f`\n', pipeline.toy.summary.theta_ss);
fprintf(fid, '- `peak_price_myopic = %.4f`\n', pipeline.toy.summary.peak_price_myopic);
fprintf(fid, '- `peak_price_re = %.4f`\n', pipeline.toy.summary.peak_price_re);
fprintf(fid, '- `max_price_gap_re_minus_myopic = %.4f`\n\n', pipeline.toy.summary.max_price_gap_re_minus_myopic);

fprintf(fid, '## Endpoint export\n\n');
fprintf(fid, '- Baseline endpoint export: `%s`\n', pipeline.export.baseline.status);
if ~isempty(pipeline.export.baseline.source_path)
    fprintf(fid, '- Baseline source: `%s`\n', pipeline.export.baseline.source_path);
end
if ~isempty(pipeline.export.baseline.output_path)
    fprintf(fid, '- Baseline endpoint file: `%s`\n', pipeline.export.baseline.output_path);
end
fprintf(fid, '- Boom endpoint export: `%s`\n', pipeline.export.boom.status);
if ~isempty(pipeline.export.boom.source_path)
    fprintf(fid, '- Boom source: `%s`\n', pipeline.export.boom.source_path);
end
if ~isempty(pipeline.export.boom.output_path)
    fprintf(fid, '- Boom endpoint file: `%s`\n', pipeline.export.boom.output_path);
end
fprintf(fid, '\n');

fprintf(fid, '## Structural benchmark\n\n');
if isfield(pipeline.structural, 'status') && strcmpi(pipeline.structural.status, 'ok')
    fprintf(fid, '- Structural run completed.\n');
    fprintf(fid, '- Baseline endpoint source: `%s`\n', pipeline.structural.baseline_path);
    fprintf(fid, '- Boom endpoint source: `%s`\n', pipeline.structural.boom_path);
else
    fprintf(fid, '- Structural run did not complete.\n');
    if isfield(pipeline.structural, 'message')
        fprintf(fid, '- Message: %s\n', pipeline.structural.message);
    end
end
end

function status = get_status(s)
if isfield(s, 'status')
    status = s.status;
else
    status = 'unknown';
end
end
