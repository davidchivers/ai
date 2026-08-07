/*==============================================================================
    Project:    [project name]
    Purpose:    [one-sentence transformation]
    Input:      [raw file, never modified]
    Output:     [stable processed file]
==============================================================================*/

* Match this to the oldest Stata version the project supports.
* Repository default: StataNow 19.
version 19
clear all
set more off
capture log close _all

* Supply the project root as the first argument:
* do stata_cleaning_template.do "C:/path/to/project"
args project_root
if `"`project_root'"' == "" {
    display as error "Supply the project root as the first argument."
    exit 198
}

local raw_dir       "`project_root'/data/raw"
local processed_dir "`project_root'/data/processed"
local log_dir       "`project_root'/logs"

capture mkdir "`processed_dir'"
capture mkdir "`log_dir'"
log using "`log_dir'/data_cleaning.log", text replace

* 1. Load and inspect the immutable input.
use "`raw_dir'/[raw_input].dta", clear
describe
count
misstable summarize

* Declare and verify the expected raw-data key before transformations.
isid [raw_key]

* 2. Apply documented cleaning rules.
* [transformations with comments explaining why]

* 3. Validate the analysis-ready data.
isid [processed_key]
assert [required_invariant]
compress

* 4. Save one stable processed output.
save "`processed_dir'/[processed_output].dta", replace

log close
