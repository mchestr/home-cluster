import argparse

import yaml
import os
from copy import deepcopy


class MyDumper(yaml.Dumper):

    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)


def load_key(data, path):
    value = data
    for key in path.split('.'):
        value = value.get(key, {})
    return value


def main() :
    parser = argparse.ArgumentParser('app-template-upgrade')
    parser.add_argument('d', help='Directory to scan')
    args = parser.parse_args()

    for root, _, files in os.walk(args.d):
        for file in files:
            if file != 'helmrelease.yaml':
                continue
            filepath = os.path.join(root, file)
            with open(filepath) as f:
                data = yaml.load(f, Loader=yaml.FullLoader)
            if data['kind'] != 'HelmRelease':
                continue

            if load_key(data, 'spec.chart.spec.chart') == 'app-template' and load_key(data, 'spec.chart.spec.version') < '2.0.2':
                process(filepath, data)
                # Just process one file at a time, once its upgraded can run script again and onto the next.
                return


def process(filepath, data):
    new = deepcopy(data)
    new['spec']['chart']['spec']['version'] = '2.0.2'
    helm_values = new['spec'].pop('values')
    new_helm_values = deepcopy(helm_values)

    if values := helm_values.pop('controller', None):
        new_helm_values['controllers'] = process_controllers(values)

    if values := helm_values.pop('initContainers', None):
        new_helm_values['controllers']['main']['initContainers'] = {}
        for init_container in values:
            new_helm_values['controllers']['main']['initContainers'][init_container] = process_init_container(values[init_container])

    if values := helm_values.pop('image', None):
        if not load_key(new_helm_values, 'controllers.main.containers'):
            new_helm_values['controllers']['main']['containers'] = {'main': {}}
        new_helm_values['controllers']['main']['containers']['main']['image'] = values

    if values := helm_values.pop('envFrom', None):
        new_helm_values['controllers']['main']['containers']['main']['envFrom'] = values

    if values := helm_values.pop('env', None):
        new_helm_values['controllers']['main']['containers']['main']['env'] = values

    if values := helm_values.pop('resources', None):
        new_helm_values['controllers']['main']['containers']['main']['resources'] = values

    if values := helm_values.pop('ingress', None):
        new_helm_values['ingress'] = process_ingress(load_key(helm_values, 'service'), values)

    if values := helm_values.pop('podSecurityContext', None):
        if not new_helm_values.get('defaultPodOptions'):
            new_helm_values['defaultPodOptions'] = {}
        new_helm_values['defaultPodOptions']['securityContext'] = values

    if values := helm_values.pop('probes', None):
        new_helm_values['controllers']['main']['containers']['main']['probes'] = values

    if persistence := load_key(helm_values, 'persistence'):
        for key in persistence:
            old_values = new_helm_values['persistence'].pop(key)
            new_helm_values['persistence'][key] = process_persistence(old_values)

    new['spec']['values'] = set_key_order(new_helm_values)

    print(f"# Original file: {filepath}")
    print('---')
    print(yaml.dump(new, Dumper=MyDumper, sort_keys=False))


def process_controllers(data):
    return {
        'main': data
    }


def process_ingress(services, data):
    if load_key(data, 'main.ingressClassName'):
        value = data['main'].pop('ingressClassName')
        data['main']['className'] = value

    first_service = next(s for s in services)
    first_port_name = next(p for p in services[first_service]['ports'])
    data['main']['hosts'][0]['paths'][0]['service'] = {
        'name': first_service,
        'port': first_port_name,
    }
    return data


def process_persistence(data):
    if data.get('mountPath'):
        data['globalMounts'] = [{
            'path': data.pop('mountPath')
        }]
        if data.get('subPath'):
            data['globalMounts'][0]['subPath'] = data.pop('subPath')
    return data


def process_init_container(data):
    if 'image' in data:
        old_value = data.pop('image').split(':')
        data['image'] = {
            'repository': old_value[0],
            'tag': old_value[1],
        }
    return data


def set_key_order(data):
    order = ['defaultPodOptions', 'controllers', 'service', 'ingress', 'persistence']
    new_data = {}
    for key in order:
        if key in data:
            new_data[key] = data.pop(key)
    new_data.update(data)
    return new_data

if __name__ == "__main__":
    main()
