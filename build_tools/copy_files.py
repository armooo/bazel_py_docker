import shutil
import sys


def copy(file_pairs):
    for file_pair in file_pairs:
        src, dest = file_pair.split('=')
        shutil.copyfile(src, dest)


if __name__ == '__main__':
    copy(sys.argv[1:])
