import argparse
import hashlib
import os
import tarfile
import uuid


def hash_file(path):
    with open(path) as f:
        h = hashlib.sha256()
        while True:
            buf = f.read(65536)
            if not buf:
                break
            h.update(buf)
        return h.hexdigest()


def hashed_file_path(dir_name, file_hash):
    return os.path.join(dir_name, file_hash[0:4], file_hash[4:8], file_hash)


def main(args):
    hash_dir = uuid.uuid4().hex + '.contents'
    file_set = set()
    with tarfile.open(args.o, 'w') as output:
        with open(args.m) as manifest:
            for line in manifest:
                tar_name, path = line.split()
                file_hash = hash_file(path)
                hash_path = hashed_file_path(hash_dir, file_hash)

                if file_hash not in file_set:
                    file_set.add(file_hash)
                    output.add(path, hash_path)

                ln = tarfile.TarInfo(tar_name)
                ln.type = tarfile.SYMTYPE
                linkname = (['..'] * tar_name.count('/')) + [hash_path]
                ln.linkname = os.path.join(*linkname)
                output.addfile(ln)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build a tar file')
    parser.add_argument('-m', required=True, help='manifest file')
    parser.add_argument('-o', required=True, help='path to write the tar file')

    args = parser.parse_args()
    main(args)
