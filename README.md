FKE File Cleaner

A lightweight Windows utility for locating and optionally removing .fke files from a directory tree.

FKE File Cleaner is a self-contained Windows batch utility that combines a simple command-line interface with PowerShell to scan the directory containing the script and all of its subdirectories. It is designed to make the process of identifying and removing .fke files controlled, transparent, and easy to review before anything is deleted.

Created by Aris Patronis.

Overview

FKE File Cleaner searches recursively for files matching:

*.fke


The scan is intentionally restricted to the directory where FKE-Cleaner.bat is located and everything below it.

For example, if the script is located at:

D:\Projects\Files\FKE-Cleaner.bat


the scanner searches:

D:\Projects\Files\
D:\Projects\Files\Subfolder\
D:\Projects\Files\Subfolder\AnotherFolder\


It does not search the parent directory:

D:\Projects\


and it does not scan unrelated directories elsewhere on the drive.

This makes the location of the BAT file the explicit boundary of the operation.

Features

Recursive .fke file detection.

Scans only the BAT file's directory and its subdirectories.

No age-based filtering.

No automatic deletion during scanning.

Displays all discovered files before deletion.

Displays the number of files found and their combined size.

Requires confirmation before deletion.

Requires a second confirmation before permanently deleting files.

Displays deletion progress.

Reports successful and failed deletion attempts.

Creates a timestamped log file.

Records inaccessible locations as warnings.

Includes a configurable safety limit for unexpectedly large results.

Prevents execution when the BAT file is placed directly in a drive root.

Keeps the console window open after completion.

Uses a simple color-coded status system.

How It Works

The program follows a deliberate scan-before-delete workflow.

1. Determine the scan location

When the BAT file starts, it automatically determines its own location.

No path needs to be entered manually.

The directory containing the BAT file becomes the root of the scan.

2. Confirm the scan

Before accessing files, the program displays the directory that will be searched and asks for confirmation:

Start scan? [Y/N]:


Selecting N exits without scanning or modifying anything.

3. Scan for .fke files

After confirmation, the program recursively searches the selected directory tree for files matching:

*.fke


The scan includes hidden files and directories when the current Windows account has permission to access them.

4. Display the findings

If files are found, the program displays their complete paths.

For example:

[FOUND] D:\Files\example.fke
[FOUND] D:\Files\Archive\old-file.fke
[FOUND] D:\Files\Archive\2025\another-file.fke


It also reports the total number of matching files and their combined size.

Nothing is deleted at this stage.

5. Review and confirm deletion

After displaying the findings, the program asks whether all listed files should be deleted.

If deletion is selected, a second confirmation is required.

For example:

Delete ALL 3 listed file(s)? Enter Y or N:


The program then requires:

Type DELETE 3 FILES to confirm:


The exact confirmation must match before deletion begins.

This two-step process is intended to reduce accidental deletion.

6. Delete the selected files

Once confirmed, each discovered file is processed individually.

A PowerShell progress indicator displays the current deletion progress.

The program records whether each file was:

[DELETED]

[ALREADY GONE]


or:

[FAILED]


If a deletion fails, the associated error message is recorded.

Status Colors

The console normally uses white text.

The final status uses color to make the result immediately identifiable.

Green

Green indicates that the scan completed and no .fke files were found.

SCAN COMPLETED SUCCESSFULLY

NO FILES WERE FOUND

Red

Red indicates that one or more .fke files were found, or that the program encountered a safety limit or error.

When files are found, the user is shown the results and given the option to delete them.

Safety Measures

The utility includes several safeguards intended to prevent unintended operations.

Restricted scan scope

The program only scans the BAT file's own directory and its descendants.

It does not automatically scan an entire drive.

Drive-root protection

The script refuses to run a recursive scan when it is placed directly in a drive root such as:

C:\


or:

D:\


The BAT should instead be placed inside a normal directory.

File-count limit

A maximum number of matching files is defined in the script:

set "MAX_FILES=50000"


If more than this number of .fke files are discovered, the program stops before deletion.

No files are deleted when the safety limit is exceeded.

The limit can be adjusted in the BAT file if required.

Confirmation before deletion

Files are never deleted simply because they were discovered.

The user must explicitly confirm the deletion operation and then provide a second confirmation.

Logging

Each execution creates a timestamped log file in the directory being scanned.

Example:

FKE-Cleaner-2026-09-29_15-30-12.log


The log can contain:

Script start time

Scan location

Search pattern

Number of files found

Combined file size

Complete list of discovered files

Access warnings

Deletion results

Failed deletions and their error messages

Files that were already removed

Final statistics

Completion time

The log provides a record of what the utility discovered and what actions were performed.

Example

Suppose the following directory exists:

D:\Downloads\
│
├── FKE-Cleaner.bat
├── normal-file.txt
├── suspicious.fke
│
├── Archive\
│   ├── old.fke
│   └── document.pdf
│
└── Backup\
    └── Files\
        └── test.fke


Running the BAT from D:\Downloads\ will find:

D:\Downloads\suspicious.fke
D:\Downloads\Archive\old.fke
D:\Downloads\Backup\Files\test.fke


It will not search outside D:\Downloads\.

The user can then review the results and decide whether to remove them.

Requirements

Windows

Command Prompt

Windows PowerShell

Appropriate permissions for the directories being scanned

No external dependencies or installation process are required.

Installation

FKE File Cleaner is portable and does not require an installer.

Download FKE-Cleaner.bat.

Place it in the directory you want to scan.

Run the BAT file.

Confirm the scan.

Review any .fke files discovered.

Confirm deletion only if you want to remove the listed files.

Important

FKE File Cleaner uses PowerShell's Remove-Item to permanently delete confirmed files.

Deletion should therefore be treated as irreversible.

Always review the displayed file list before confirming the deletion operation.

The utility should only be used on directories and files that you are authorized to modify.

Project Structure
fke-file-cleaner/
│
├── FKE-Cleaner.bat
├── README.md
└── LICENSE


The BAT file creates a temporary PowerShell script during execution. The temporary script is removed after the operation finishes.

Configuration

The primary safety setting is the maximum number of files that may be processed:

set "MAX_FILES=50000"


This value can be changed if the utility is being used in an environment where a different limit is appropriate.

The search pattern is currently fixed to:

*.fke


The scan root is automatically determined from the location of the BAT file.

Author

Aris Patronis

License

Add a license appropriate to your intended use and distribution of the project.
