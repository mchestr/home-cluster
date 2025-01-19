#!/usr/bin/env python
import pandas as pd
import pyvis
from pyvis.network import Network
import os
import yaml
pyvis.__version__

nodes = set()
edges = set()
for root, dirs, files in os.walk(".."):
    path = root.split(os.sep)
    for file in (f for f in files if f.endswith('.yaml')):
        filepath = os.path.join(root, file)
        with open(filepath, 'r') as f:
            data = yaml.load_all(f, yaml.FullLoader)
            try:
              for document in data:
                  if type(document) == list:
                      print(f'invalid file?: {filepath}')
                      continue

                  if document.get('kind') == 'Kustomization':
                    node = document.get('metadata', {}).get('name')
                    if node is None:
                        continue

                    nodes.add(node)

                    for dep in document.get('spec', {}).get('dependsOn', []):
                        dep_name = dep.get('name')
                        edges.add((node, dep_name))
            except Exception as e:
                print(filepath)
                print(e)


net = Network(notebook = True, cdn_resources = "remote",
                bgcolor = "#222222",
                font_color = "white",
                height = "750px",
                width = "100%",
                select_menu=True,
                filter_menu=True,
)
net.add_nodes(nodes)
net.add_edges(edges)
net.show("graph.html")


def main():
    pass


if __name__ == "__main__":
    main()
