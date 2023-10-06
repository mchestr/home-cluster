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

    if load_key(helm_values, 'controller'):
        old_values = new_helm_values.pop('controller')
        new_helm_values['controllers'] = process_controllers(old_values)

    if load_key(helm_values, 'initContainers'):
        old_values = new_helm_values.pop('initContainers')
        new_helm_values['controllers']['main']['initContainers'] = {}
        for init_container in old_values:
            new_helm_values['controllers']['main']['initContainers'][init_container] = process_init_container(old_values[init_container])

    if load_key(helm_values, 'image'):
        old_values = new_helm_values.pop('image')
        if not load_key(new_helm_values, 'controllers.main.containers'):
            new_helm_values['controllers']['main']['containers'] = {'main': {}}
        new_helm_values['controllers']['main']['containers']['main']['image'] = old_values

    if load_key(helm_values, 'envFrom'):
        old_values = new_helm_values.pop('envFrom')
        new_helm_values['controllers']['main']['containers']['main']['envFrom'] = old_values

    if load_key(helm_values, 'env'):
        old_values = new_helm_values.pop('env')
        new_helm_values['controllers']['main']['containers']['main']['env'] = old_values

    if load_key(helm_values, 'resources'):
        old_values = new_helm_values.pop('resources')
        new_helm_values['controllers']['main']['containers']['main']['resources'] = old_values

    if load_key(helm_values, 'ingress'):
        old_values = new_helm_values.pop('ingress')
        new_helm_values['ingress'] = process_ingress(load_key(helm_values, 'service'), old_values)

    if load_key(helm_values, 'podSecurityContext'):
        old_values = new_helm_values.pop('podSecurityContext')
        if not new_helm_values.get('defaultPodOptions'):
            new_helm_values['defaultPodOptions'] = {}
        new_helm_values['defaultPodOptions']['securityContext'] = old_values

    if persistence := load_key(helm_values, 'persistence'):
        for key in persistence:
            old_values = new_helm_values['persistence'].pop(key)
            new_helm_values['persistence'][key] = process_persistence(old_values)

    new['spec']['values'] = set_key_order(new_helm_values)
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
