# Bash Autograder

A configurable, automated grading system written entirely in Bash. It processes student's
 programming submissions, compiles and executes code across multiple languages, compares output against expected results, and generates a structured marks report — handling edge cases like archive extraction, submission guideline violations, and plagiarism detection.

## Motivation

Manual grading of programming assignments is tedious and error-prone, especially at scale. This tool automates the entire pipeline — from unpacking submissions to producing a final CSV grade sheet — so that instructors only need to define a configuration file and let the script handle the rest.

## Features

- **Multi-language support** — compiles and runs C, C++, Python, and Bash submissions automatically
- **Archive handling** — extracts `zip`, `rar`, and `tar` archives with configurable toggle
- **Submission validation** — detects naming violations, incorrect directory structures, and unsupported file formats
- **Output comparison** — diffs each student's output against an expected output file and applies per-mismatch penalties
- **Execution timeout** — kills submissions that exceed a configurable time limit and marks them as TLE (Time Limit Exceeded)
- **Compilation error handling** — catches C/C++ compilation failures and routes them to issues instead of crashing
- **Score clamping** — prevents output mismatch penalties from pushing marks below zero
- **Plagiarism integration** — reads a list of flagged student IDs and applies a percentage-based penalty
- **Penalty system** — configurable deductions for wrong output, submission guideline violations, and plagiarism
- **Structured reporting** — generates a `marks.csv` with per-student breakdowns of marks, deductions, and remarks
- **Issue tracking** — moves problematic submissions to an `issues/` directory for manual review

## How It Works

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Config File     │────▶│  Autograder      │────▶│  marks.csv       │
│  (conditions)    │     │  autograder.sh   │     │  (grade report)  │
└──────────────────┘     └────────┬─────────┘     └──────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ checked/ │ │ issues/  │ │ expected │
              │ (graded) │ │ (errors) │ │ output   │
              └──────────┘ └──────────┘ └──────────┘
```

## Configuration File Format

The script reads a plain-text configuration file where each line specifies a parameter:

| Line | Parameter             | Example             | Description                                       |
|------|-----------------------|---------------------|---------------------------------------------------|
| 1    | Use Archive           | `true`              | Whether submissions are archived (`true`/`false`)  |
| 2    | Allowed Archives      | `zip rar tar`       | Space-separated archive formats                    |
| 3    | Allowed Languages     | `c cpp python sh`   | Space-separated language identifiers               |
| 4    | Total Marks           | `100`               | Maximum marks per submission                       |
| 5    | Output Penalty        | `5`                 | Marks deducted per output mismatch                 |
| 6    | Working Directory     | `/path/to/submissions` | Directory containing student submissions        |
| 7    | Student ID Range      | `2005001 2005030`   | First and last student IDs (inclusive)             |
| 8    | Expected Output File  | `/path/to/expected.txt` | Path to the reference output file              |
| 9    | Submission Penalty    | `10`                | Deduction for guideline violations                 |
| 10   | Plagiarism File       | `/path/to/plagiarism.txt` | File listing plagiarised student IDs         |
| 11   | Plagiarism Penalty    | `100`               | Percentage penalty applied to plagiarism cases     |

**Example `conditions.txt`:**

```
true
zip tar
c cpp python
100
5
/home/user/Bash_AutoGrader/sample_submissions
2005001 2005030
/home/user/Bash_AutoGrader/sample_submissions/expected_output.txt
10
/home/user/Bash_AutoGrader/plagiarism.txt
100
```

## Usage

```bash
chmod +x autograder.sh
./autograder.sh -f sample_input.txt
./autograder.sh -h
```

**Flags:**

| Flag | Description | Required |
|------|-------------|----------|
| `-f` | Path to the conditions file | Yes |
| `-h` / `--help` | Show usage instructions | No |

## Output

After execution, the working directory will contain:

- **`marks.csv`** — the final grade report with columns: `id, marks, marks_deducted, total_marks, remarks`
- **`checked/`** — successfully graded submissions
- **`issues/`** — submissions that could not be graded (wrong format, unrecognized files)

**Sample `marks.csv`:**

```
id, marks, marks_deducted, total_marks, remarks
2005001, 100, 0, 100,
2005002, 85, 10, 75, issue case #4
2005003, 0, 10, -100, missing submission plagiarism detected
```

## Issue Cases

The `remarks` column in the report uses coded labels:

| Code            | Meaning                                                        |
|-----------------|----------------------------------------------------------------|
| `issue case #1` | Submission is a raw directory instead of an archive            |
| `issue case #2` | Archive format not recognized or extraction failed             |
| `issue case #3` | Source file inside the archive has wrong name or language       |
| `issue case #4` | Extracted directory name doesn't match the student ID          |
| `TLE`           | Program exceeded the execution time limit                      |
| `compilation_error` | C/C++ source failed to compile                            |
| `missing submission` | No file or directory matching the student ID was found   |
| `plagiarism detected` | Student ID appears in the plagiarism file               |

## Prerequisites

- **Bash** 4.0+ (uses `mapfile`)
- **gcc / g++** — for C/C++ compilation
- **python3** — for Python submissions
- **unzip** — for `.zip` archives
- **unrar** — for `.rar` archives
- **tar** — for `.tar` archives (usually pre-installed)

## Project Structure

```
bash-autograder/
├── autograder.sh          # Main grading script
├── conditions.txt         # Sample configuration file
├── plagiarism.txt         # Sample plagiarism ID list
├── sample_submissions/    # Example student submissions for testing
│   ├── 2005001.zip
│   ├── 2005002.tar
│   └── 2005003.c
    ├── expected_output.txt    # Sample expected output
└── README.md
```

## Limitations and Future Work

- **No input file support** — programs that require stdin input are not currently handled
- **Single-file submissions only** — multi-file projects are not supported
- **Basic diff** — output comparison uses sorted line-level diff, not semantic comparison

Potential improvements: support for stdin test cases, parallel grading for large classes, configurable per-language timeouts, and an HTML report generator.

## License

This project is released under the [MIT License](LICENSE).