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
 * This program is intended to run as a cmon-agent plugin. It takes one argument
 * which is a zonename. It will then look for files in:
 *
 *    /zones/<zonename>/root/var/tmp/INPUTS
 *
 * and count both the files and the number of lines contained within those
 * files. The resulting output will look like:
 *
 *    input_file_count        gauge   51922   Number of files in /var/tmp/INPUT for a Mako.
 *    instruction_file_count  gauge   5192152 Number of instruction files listed in /var/tmp/INPUT files for a Mako.
 *
 * and the result at CMON will look like:
 *
 *   # HELP plugin_mako_gc_files_input_file_count Number of files in /var/tmp/INPUT for a Mako.
 *   # TYPE plugin_mako_gc_files_input_file_count gauge
 *   plugin_mako_gc_files_input_file_count 51922
 *   # HELP plugin_mako_gc_files_instruction_file_count Number of instruction files listed in /var/tmp/INPUT files for a Mako.
 *   # TYPE plugin_mako_gc_files_instruction_file_count gauge
 *   plugin_mako_gc_files_instruction_file_count 5192152
 *
 * For testing and development you can set the environment variable INPUT_DIR to
 * the absolute path of a directory containing input files and that will be used
 * rather than looking at the /zones/<uuid>/root/var/tmp/INPUTS directory.
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

char *DEFAULT_DIR = "/var/tmp/INPUTS";
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
         * processed while we were running?
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
            "Fatal(%d): failed to build filename string '%s/%s': %s\n",
            ret, dir, file, strerror(errno));
        exit(2);
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
    char dir[PATH_MAX];
    DIR *dirp;
    struct dirent *dp;
    char *envdir = getenv("INPUT_DIR");
    int ret;
    char *zonename = argv[1];

    if (zonename == NULL) {
        fprintf(stderr, "No zonename specified. Ignoring.\n");
        exit(0);
    }

    if (envdir) {
        if (strlcpy(dir, envdir, sizeof(dir)) >= sizeof(dir)) {
            fprintf(stderr, "FATAL: Invalid INPUT_DIR in environment.\n");
            exit(1);
        }
    } else {
        errno = 0;
        ret = snprintf(dir, sizeof(dir), "/zones/%s/root%s", zonename,
            DEFAULT_DIR);
        if (ret < 1 || ret > sizeof(dir)) {
            fprintf(stderr,
                "FATAL(%d): failed to build dir string for %s: %s\n",
                ret, zonename, strerror(errno));
            exit(2);
        }
    }

    errno = 0;
    if ((dirp = opendir(dir)) == NULL) {
        if (errno == ENOENT) {
            fprintf(stderr, "INPUT dir does not exist for zone %s. Ignoring.\n",
                zonename);
            exit(0);
        }

        fprintf(stderr, "FATAL: Could not open %s: %s\n", dir, strerror(errno));
        exit(1);
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
        fprintf(stderr, "Error reading directory %s: %s\n", dir,
            strerror(errno));
    }

    (void) closedir(dirp);

    printf("input_file_count\tgauge\t%d\t%s\n", fileCount,
        INPUT_FILES_HELP);
    printf("instruction_file_count\tgauge\t%d\t%s\n", lineCount,
        INSTRUCTION_FILES_HELP);

    exit(0);
}
