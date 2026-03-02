$lit='projects/01_necessity_entrepreneurs/Literature'
$items=@(
 @{url='https://www.aeaweb.org/articles/pdf/doi/10.1257/aer.20141280'; file='sedlacek_sterk_2017.pdf'; note='exact_journal'},
 @{url='https://researchdatabase.minneapolisfed.org/downloads/0v8380701'; file='donovan_lu_schoellman_2020_sr596.pdf'; note='working_paper_for_2023_qje'},
 @{url='http://researchdatabase.minneapolisfed.org/downloads/db78tc124'; file='cagetti_denardi_2003_wp620.pdf'; note='working_paper_for_2006_jpe'},
 @{url='https://papers.ssrn.com/sol3/papers.cfm?abstract_id=1504463'; file='lucas_1978_ssrn_record.html'; note='landing_only'},
 @{url='http://eprints.lse.ac.uk/1176/1/Job_creation_and_job_destruction_in_the_theory_of_unemployment.pdf'; file='mortensen_pissarides_1994_workingpaper_lse.pdf'; note='working_paper_possible'},
 @{url='https://cep.lse.ac.uk/pubs/download/dp0110.pdf'; file='mortensen_pissarides_1994_workingpaper_dp110.pdf'; note='working_paper_possible'}
)
$rows=@()
foreach($i in $items){
  $out=Join-Path $lit $i.file
  try{ Invoke-WebRequest -Uri $i.url -OutFile $out -TimeoutSec 120 -MaximumRedirection 8 } catch {}
  if(Test-Path $out){
    $len=(Get-Item $out).Length
    $head=(Get-Content -Encoding Byte -TotalCount 4 $out)
    $isPdf=($head.Length -eq 4 -and $head[0]-eq 37 -and $head[1]-eq 80 -and $head[2]-eq 68 -and $head[3]-eq 70)
    $rows += [pscustomobject]@{File=$i.file;Status=($(if($isPdf){'pdf'}else{'non_pdf'}));Bytes=$len;Note=$i.note;Url=$i.url}
  } else {
    $rows += [pscustomobject]@{File=$i.file;Status='failed';Bytes=0;Note=$i.note;Url=$i.url}
  }
}
$rows | Format-Table -AutoSize
$rows | Export-Csv -NoTypeInformation -Path 'projects/01_necessity_entrepreneurs/docs/literature/2026-02-23_pdf_additional_attempts.csv'
