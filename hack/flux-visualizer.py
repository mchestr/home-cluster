#!/usr/bin/env python
import pandas as pd
import pyvis
from pyvis.network import Network
import os
import yaml

pyvis.__version__


def extract_file(filepath):
    nodes = set()
    edges = set()
    with open(filepath, "r") as f:
        data = yaml.load_all(f, yaml.FullLoader)
        for document in data:
            if type(document) == list:
                print(f"invalid file?: {filepath}")
                continue

            if document.get("kind") == "Kustomization":
                node = document.get("metadata", {}).get("name")
                if node is None:
                    continue
                nodes.add(node)

                for dep in document.get("spec", {}).get("dependsOn", []):
                    dep_name = dep.get("name")
                    edges.add((dep_name, node))
    return nodes, edges


def parse_repository(path="."):
    nodes = set()
    edges = set()
    for root, _, files in os.walk(path):
        path = root.split(os.sep)
        for file in (f for f in files if f.endswith(".yaml")):
            filepath = os.path.join(root, file)
            try:
                file_nodes, file_edges = extract_file(filepath)
                nodes |= file_nodes
                edges |= file_edges
            except Exception as e:
                print(f"Error extracting file {filepath}: {e}")
    return nodes, edges


def main():
    nodes, edges = parse_repository()
    net = Network(
        notebook=True,
        cdn_resources="remote",
        bgcolor="#222222",
        font_color="white",
        height="750px",
        width="100%",
        select_menu=True,
        filter_menu=True,
    )
    net.add_nodes(nodes)
    net.add_edges(edges)
    net.show("graph.html")


if __name__ == "__main__":
    main()
