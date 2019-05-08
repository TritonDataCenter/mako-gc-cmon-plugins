/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 *
 * Copyright 2019 Joyent, Inc.
 *
 *
 * Summary:
 *
 * This program is intended to be used when writing cmon-agent plugins. It takes
 * one argument which is a directory. It will then look for files this directory
 * and count both the files and the number of lines contained within those
 * files. The resulting output will look like:
 *
 *    51922 5192152
 *
 * with the first number being the number of files and the second number being
 * the number of lines.
 *
 * IMPORTANT: this does *not* do recursion. It only counts the files in the
 * specified dir.
 *
 */

#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <unistd.h>

char *INPUT_FILES_HELP = "Number of files in /var/tmp/INPUT for a Mako.";
char *INSTRUCTION_FILES_HELP =
    "Number of instruction files listed in /var/tmp/INPUT files for a Mako.";

int fileCount = 0;
int instructionFileCount = 0;
int lineCount = 0;
int lineSize = 0;

void findLineSize(char *filename) {
    int fd;
    int idx;
    char lineBuffer[PATH_MAX];
    int nbytes;

    errno = 0;
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "Unable to open %s: %s\n", filename, strerror(errno));
        /*
         * By returning without setting lineSize, the next file in the readdir
         * loop should end up coming back here to try again. Maybe the file was
         * consumed while we were running?
         */
        return;
    }

    errno = 0;
    nbytes = read(fd, lineBuffer, sizeof(lineBuffer));
    (void) close(fd);

    if (nbytes < 0) {
        fprintf(stderr, "Unable to read from %s: %s", filename, strerror(errno));
        /*
         * Again returning without setting lineSize so we'll try again with a
         * diff file.
         */
        return;
    }

    for (idx = 0; (lineSize == 0 && idx < nbytes); idx++) {
        if (lineBuffer[idx] == '\n') {
            lineSize = idx + 1;
        }
        /* if \n is not found, we'll not set lineSize. */
    }
}

void countFile(char *dir, char *file) {
    char filename[PATH_MAX];
    int lines;
    int ret;
    struct stat statbuf;

    errno = 0;
    ret = snprintf(filename, sizeof(filename), "%s/%s", dir, file);
    if (ret < 1 || ret > sizeof(filename)) {
        fprintf(stderr,
            "FATAL(%d): failed to build filename string '%s/%s': %s\n",
            ret, dir, file, strerror(errno));
        exit(5);
    }

    errno = 0;
    if (stat(filename, &statbuf) == -1) {
        // Just skip this one, nothing else we can do.
        fprintf(stderr, "Unable to stat '%s': %s\n", filename, strerror(errno));
        return;
    }

    if ((statbuf.st_mode&S_IFMT) != S_IFREG) {
        fprintf(stderr, "Ignoring non-file %s\n", filename);
        return;
    }

    /*
     * Per discussion among people working on GC, the paths in these files are
     * guaranteed to have the same length on a given mako. As such, we're able
     * to just figure out the line length from the first line in the first file
     * we load and then for the remaining files we don't need to read them we
     * can just divide the file size by the size of a single line.
     */
    if (lineSize == 0) {
        findLineSize(filename);
        if (lineSize == 0) {
            /* file must have gone away while reading, we'll not count it */
            return;
        }
    }

    lines = statbuf.st_size / lineSize;

    fileCount += 1;
    lineCount += lines;

    return;
}

int main(int argc, char *argv[]) {
    DIR *dirp;
    struct dirent *dp;
    char *dir = argv[1];

    if (dir == NULL) {
        fprintf(stderr, "Usage: %s <dir>.\n", argv[0]);
        exit(1);
    }

    errno = 0;
    if ((dirp = opendir(dir)) == NULL) {
        if (errno == ENOENT) {
            fprintf(stderr, "FATAL: '%s' does not exist.\n", dir);
            exit(2);
        }

        fprintf(stderr, "FATAL: Could not open %s: %s\n", dir, strerror(errno));
        exit(3);
    }

    do {
        errno = 0;
        if ((dp = readdir(dirp)) != NULL) {
            if (dp->d_name[0] == '.') {
                /* ignore files and dirs that start with '.' */
                continue;
            }
            countFile(dir, dp->d_name);
        }
    } while (dp != NULL);

    if (errno != 0) {
        fprintf(stderr, "FATAL: Error reading directory %s: %s\n", dir,
            strerror(errno));
        (void) closedir(dirp);
        exit(4);
    }

    (void) closedir(dirp);

    printf("%d %d\n", fileCount, lineCount);

    exit(0);
}
