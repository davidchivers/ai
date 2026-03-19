# Microsoft Form question draft

## Form title

`Department student enquiry form`

## Form introduction

Use this form for general department enquiries about modules, academic advising, assessments, attendance, timetables, systems access, and related issues.

You must be signed in with your university account to use this form. The form records your university account details automatically, so you do not need to type your username or email address. If your issue is urgent or relates to a deadline today, contact the department office directly.

If your university uses a separate formal process for extensions or mitigating circumstances, you may still need to complete that process.

Please do not include unnecessary sensitive personal or medical information in the message box.

## Questions

### 1. Stage of study

- Type: choice
- Required: yes
- Prompt:

`Stage of study`

- Options:

`Undergraduate`  
`Taught postgraduate`

### 2. Year of study

- Type: choice
- Required: yes for undergraduates
- Prompt:

`Year of study`

- Options:

`Year 1`  
`Year 2`  
`Year 3`  
`Year 4`

- Branching:

Show only if `Stage of study = Undergraduate`.

### 3. Programme of study

- Type: choice
- Required: yes
- Prompt:

`Programme of study`

- Options:

`BSc Economics`  
`BSc Economics and Management`  
`BA Economics and Politics`  
`BA PPE`  
`Masters`

- Note:

This is a checkpoint field for version 1 and can be removed later if lookup proves fully reliable.

### 4. Enquiry type

- Type: choice
- Required: yes
- Prompt:

`Enquiry type`

- Options:

`Module enquiry`  
`Academic advisor`  
`Assessment query`  
`Extension`  
`Mitigating circumstances`  
`Attendance`  
`Timetable`  
`IT / systems access`  
`Fees / finance`  
`Other`

### 5. Other enquiry type

- Type: text
- Required: yes when shown
- Prompt:

`If you selected Other, please describe the enquiry type`

- Branching:

Show only if `Enquiry type = Other`.

### 6. Message

- Type: long text
- Required: yes
- Prompt:

`Please describe your enquiry`

- Help text:

`Include enough detail for staff to understand the issue and what help you need.`

## Branching map

- If `Stage of study = Undergraduate`, go to `Year of study`, then `Programme of study`.
- If `Stage of study = Taught postgraduate`, skip `Year of study` and go to `Programme of study`.
- If `Enquiry type = Other`, show `Other enquiry type`, then `Message`.
- Otherwise, skip `Other enquiry type` and go to `Message`.

## Thank-you message

`Thank you. Your enquiry has been submitted. You will receive an acknowledgement email with a reference number.`

## Identity note

- Do not add a `University username` question in the preferred build.
- Do not add a `University email address` question in the preferred build.
- Restrict the form to signed-in university users and turn on recorded responder identity.
- Use the recorded responder email from Forms as the acknowledgement address and as the primary lookup key.
- If your tenant exposes username directly, you can use it as well, but email is the safer version 1 key.
