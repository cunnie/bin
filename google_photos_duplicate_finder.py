#!/usr/bin/env python3
#
import os
import subprocess
import time

photo_files = os.listdir(".")

for photo_file in photo_files:
    # print("file: {}".format(photo_file));
    dup_photo_file = photo_file.replace('.', ' (1).');
    if os.path.isfile(dup_photo_file):
        size_photo_file = os.stat(photo_file).st_size
        size_dup_photo_file = os.stat(dup_photo_file).st_size
        print('open -W "{}" "{}"'.format(photo_file, dup_photo_file))
        subprocess.run(["open", "-W", photo_file, dup_photo_file])
        # When the original is the keeper
        print('rm "{}"'.format(dup_photo_file))
        os.remove(dup_photo_file)
        # When (1) is the keeper
        # print('rm "{}"'.format(photo_file))
        # os.remove(photo_file)
        # print('mv "{}" "{}"'.format(dup_photo_file, photo_file))
        # os.rename(dup_photo_file, photo_file)
