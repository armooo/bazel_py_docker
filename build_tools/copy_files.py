import argparse
import shutil


def main(args):
    with open(args.m) as manifest:
        for line in manifest:
            src, dest = line.split()
            shutil.copyfile(src, dest)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build a tar file')
    parser.add_argument('-m', required=True, help='manifest file')
    args = parser.parse_args()
    main(args)
