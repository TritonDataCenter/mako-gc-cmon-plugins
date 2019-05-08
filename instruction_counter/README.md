# instruction_counter

## Overview

This is a tool to generate a count of files and lines among those files when
pointed at a directory.

It loads the directory list and then reads the first `PATH_MAX` bytes of the
first file and determines the line length based on the position of the first
`\n` character. It *assumes files will have lines of uniform length*, so once
we know how long each line is we can from that point `stat()` all the files
and divide the file size by the number of bytes per line in order to calculate
the number of lines.

It has been tested with over 66K "INPUTS" files (>6.6M lines altogether) and
still returns in < 0.33 seconds even in a zone on a fairly busy test system.

The result is a single line with two numbers separated by a space. The first
number is the number of files found. The second number is the total number of
lines across all files.


## Testing Quickstart

```
$ make
cc -Wall -o instruction_counter instruction_counter.c
$ ./create-test-inputs.sh 999
$ ./instruction_counter $(pwd)/INPUTS
10 999
$
```
