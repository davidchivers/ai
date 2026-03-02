# Power Automate Expressions (Copy/Paste)

## Folder path from list row

```text
items('Apply_to_each')?['FolderName']
```

## Filter list by trigger TargetEmail (Flow C)

```text
Email eq '@{triggerOutputs()?['body/TargetEmail']}'
```

## Destination path for copy (Flow C)

```text
/PromotionFiles/@{first(body('Get_items')?['value'])?['FolderName']}
```

## Email body variables (Flow B)

```text
@{items('Apply_to_each')?['Title']}
```

```text
@{items('Apply_to_each')?['FolderLink']}
```
