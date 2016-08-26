import json
import shutil
import sys
import tarfile


def load_jsons(image):
    jsons = []
    for member in image.getmembers():
        if not member.isdir():
            continue
        member = image.getmember(member.name + '/json')
        jsons.append(json.load(image.extractfile(member)))
    return jsons


def build_child_map(jsons):
    return {
        j.get('parent'): j.get('id')
        for j in jsons
    }


def main(image_path, layer_path):
    with tarfile.open(image_path) as image:
        jsons = load_jsons(image)
        child_map = build_child_map(jsons)

        with open(layer_path, 'w') as output:
            layer_id = None
            while True:
                try:
                    layer_id = child_map[layer_id]
                except KeyError:
                    break
                member = image.getmember(layer_id + '/layer.tar')
                layer = image.extractfile(member)
                shutil.copyfileobj(layer, output, 1024 * 64)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
