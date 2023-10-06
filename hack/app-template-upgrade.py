import argparse
import logging
import os
import yaml
from copy import deepcopy
from yaml.representer import Representer

LOG = logging.getLogger('app-template-upgrade')


class MyDumper(yaml.Dumper):

    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)


def setup_logging():
    LOG.setLevel(logging.DEBUG)

    # create console handler with a higher log level
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)

    LOG.addHandler(ch)


def load_key(data, path):
    value = data
    for key in path.split('.'):
        value = value.get(key, {})
    return value


def set_key(data, path, value):
    node = data
    split_path = path.split('.')
    index = 0
    while index < len(split_path) - 1:
        key = split_path[index]
        if not node.get(key, None):
            node[key] = {}
        node = node[key]
        index += 1

    node[split_path[index]] = value


def should_process_template(args, filepath, data):
    if args.skip_version_check and load_key(data, 'spec.values.controllers'):
        LOG.info(f'Probably already upgraded as "controllers" key exists, skipping {filepath}')
        return False
    return load_key(data, 'spec.chart.spec.chart') == 'app-template' and load_key(data, 'spec.chart.spec.version') < '2.0.2'


def main() :
    parser = argparse.ArgumentParser('app-template-upgrade')
    parser.add_argument('d', help='Directory to scan')
    parser.add_argument('-s', '--skip-version-check', action='store_true', help='Skip app-template version check, checks if key "controllers" exists')
    parser.add_argument('-y', '--yeet', help='YOLO the upgrade and process eveery template', action='store_true')
    args = parser.parse_args()

    for root, _, files in os.walk(args.d):
        for file in files:
            if file != 'helmrelease.yaml':
                continue
            filepath = os.path.join(root, file)
            with open(filepath) as f:
                try:
                  data = yaml.load(f, Loader=yaml.FullLoader)
                except Exception as exc:
                    LOG.error(f'failed to process: {filepath}, script is not good enough - will need manual intervention')
                    continue
            if data['kind'] != 'HelmRelease':
                continue

            if should_process_template(args, filepath, data):
                try:
                    process(filepath, data)
                except Exception as exc:
                    LOG.error(f'failed to process: {filepath}, script is not good enough - will need manual intervention', exc_info=exc)
                    continue

                if not args.yeet:
                  # Just process one file at a time, once its upgraded can run script again and onto the next.
                  return


def process(filepath, data):
    new = deepcopy(data)
    new['spec']['chart']['spec']['version'] = '2.0.2'
    helm_values = new['spec'].pop('values')
    new_helm_values = deepcopy(helm_values)

    if values := new_helm_values.pop('controller', None):
        set_key(new_helm_values, 'controllers', process_controllers(values))

    if values := new_helm_values.pop('initContainers', None):
        for init_container in values:
            set_key(new_helm_values, f'controllers.main.initContainers.{init_container}', process_init_container(values[init_container]))

    if values := new_helm_values.pop('image', None):
        set_key(new_helm_values, 'controllers.main.containers.main.image', values)

    if values := new_helm_values.pop('envFrom', None):
        set_key(new_helm_values, 'controllers.main.containers.main.envFrom', values)

    if values := new_helm_values.pop('env', None):
        set_key(new_helm_values, 'controllers.main.containers.main.env', values)

    if values := new_helm_values.pop('resources', None):
        set_key(new_helm_values, 'controllers.main.containers.main.resources', values)

    if values := new_helm_values.pop('probes', None):
        set_key(new_helm_values, 'controllers.main.containers.main.probes', values)

    if values := new_helm_values.pop('command', None):
        set_key(new_helm_values, 'controllers.main.containers.main.command', values)

    if values := new_helm_values.pop('ingress', None):
        set_key(new_helm_values, 'ingress', process_ingress(load_key(helm_values, 'service'), values))

    if values := new_helm_values.pop('podSecurityContext', None):
        set_key(new_helm_values, 'defaultPodOptions.securityContext', values)

    if values := new_helm_values.pop('securityContext', None):
        set_key(new_helm_values, 'controllers.main.containers.main.securityContext', values)

    if values := new_helm_values.pop('topologySpreadConstraints', None):
        set_key(new_helm_values, 'defaultPodOptions.topologySpreadConstraints', values)

    if values := new_helm_values.pop('nodeSelector', None):
        set_key(new_helm_values, 'defaultPodOptions.nodeSelector', values)

    if values := new_helm_values.pop('args', None):
        set_key(new_helm_values, 'controllers.main.containers.main.args', values)

    if values := new_helm_values.pop('additionalContainers', None):
        for container in values:
          set_key(new_helm_values, f'controllers.main.containers.{container}', process_init_container(values[container]))

    if values := new_helm_values.pop('affinity', None):
        set_key(new_helm_values, 'defaultPodOptions.affinity', values)

    if values := new_helm_values.pop('volumeClaimTemplates', None):
        volume_claim_templates = []
        for volume_claim in values:
            volume_claim_templates.append(process_persistence(volume_claim))
        set_key(new_helm_values, 'controllers.main.statefulset.volumeClaimTemplates', volume_claim_templates)

    if persistence := load_key(helm_values, 'persistence'):
        for key in persistence:
            old_values = new_helm_values['persistence'].pop(key)
            set_key(new_helm_values, f'persistence.{key}', process_persistence(old_values))

    new['spec']['values'] = set_key_order(new_helm_values)
    LOG.info(f"Replacing Original file: {filepath}")
    with open(filepath, 'w+') as f:
      f.write('---\n')
      f.write(yaml.dump(new, Dumper=MyDumper, sort_keys=False))


def process_controllers(data):
    return {
        'main': data
    }


def process_ingress(services, data):
    if class_name := data['main'].pop('ingressClassName', None):
        set_key(data, 'main.className', class_name)

    if data['main'].get('enabled') is False:
        return data

    first_service = next(s for s in services)
    first_port_name = next(p for p in services[first_service]['ports'])
    data['main']['hosts'][0]['paths'][0]['service'] = {
        'name': first_service,
        'port': first_port_name,
    }
    return data


def process_persistence(data):
    if mount_path := data.pop('mountPath', None):
        data['globalMounts'] = [{
            'path': mount_path
        }]
        if sub_path := data.pop('subPath', None):
            data['globalMounts'][0]['subPath'] = sub_path
    return data


def process_init_container(data):
    if image := data.pop('image', None):
        image_split = image.split(':', 1)
        data['image'] = {
            'repository': image_split[0],
            'tag': image_split[1],
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
    setup_logging()
    LOG.warning('💣 WARNING! This script will break your YAML anchors, and most likely any multiline YAML strings you have. BEWARE and audit the results!')
    LOG.warning('💣 WARNING! This script may not work for everything, but will put keys into the right spot for the most part...')
    LOG.warning('💣 WARNING! Use at your own risk')
    main()
