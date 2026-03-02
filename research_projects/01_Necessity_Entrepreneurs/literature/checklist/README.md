# Reference Checklist

- `reference_checklist.csv`: single checklist file. Edit this in Excel.
- `confirm_yn`:
  - `Y` or `Yes` = confirmed/done
  - blank or `N` = still open
- To view only open items in Excel, filter `confirm_yn` to exclude `Y` and `Yes`.
- Auto-clean draft flags when all rows are confirmed:

```powershell
..\..\scripts\sync_reference_flags.ps1
```
