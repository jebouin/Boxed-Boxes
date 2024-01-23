import sys
import json
from operator import itemgetter

with open(sys.argv[1], 'r') as f, open(sys.argv[2], 'w') as out:
    sheets = json.load(f)["sheets"]
    lines = []
    for sheet in sheets:
        if sheet["name"] != "musicDef":
            continue
        lines = sheet["lines"]
        break
    lines.sort(key=itemgetter('ostOrder'))
    for line in lines:
        id, name, ostOrder = line["id"], line["name"], line["ostOrder"]
        if ostOrder == 0:
            continue
        out.write(f"{id}: {name}\n")