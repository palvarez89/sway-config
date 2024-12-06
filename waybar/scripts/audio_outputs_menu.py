#!/bin/env python

import subprocess
import json
import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

def get_pw_dump():
    try:
        pw_dump_output = subprocess.check_output(['pw-dump'], text=True)
        pw_dump = json.loads(pw_dump_output)
        return pw_dump
    except subprocess.CalledProcessError as e:
        print(f"Error running pw-metadata: {e}")
        return None

def get_all_sink_interfaces(pw_dump):
    all_sinks = []

    for interface in pw_dump:
        if interface['type'] != "PipeWire:Interface:Node":
            continue
        if interface['info']['props'].get('media.class', None) == "Audio/Sink":
            print(interface['info']['props']['node.nick'])
            all_sinks.append(interface)
    return all_sinks

def get_default_sink(pw_dump, interfaces):
    for interface in pw_dump:
        if interface['type'] != "PipeWire:Interface:Metadata":
            continue
        for meta_i in interface['metadata']:
            print(meta_i)
            if meta_i['key'] == "default.audio.sink":
                return(meta_i['value']['name'])

pw_dump = get_pw_dump()
all_sinks = get_all_sink_interfaces(pw_dump)
default_name = get_default_sink(pw_dump, all_sinks)
print(default_name)


exit(0)
if current_sink_id is not None:
    print(f"Current Sink ID: {current_sink_id}")
    sink_details = get_sink_details(current_sink_id)
    if sink_details:
        print("Sink Details:", sink_details)
else:
    print("Failed to determine current sink ID.")


def create_gtk_menu_xml_pretty(child_items):
    # Create the root element
    interface = ET.Element('interface')

    # Create the GtkMenu object
    gtk_menu = ET.SubElement(interface, 'object', {'class': 'GtkMenu', 'id': 'menu'})

    # Add child elements dynamically
    for item_id, label in child_items:
        child = ET.SubElement(gtk_menu, 'child')
        gtk_menu_item = ET.SubElement(child, 'object', {'class': 'GtkMenuItem', 'id': item_id})
        property_label = ET.SubElement(gtk_menu_item, 'property', {'name': 'label'})
        property_label.text = label

    # Generate the rough XML string
    rough_string = ET.tostring(interface, encoding='unicode', method='xml')

    # Parse the rough string with minidom for pretty formatting
    pretty_xml = parseString(rough_string).toprettyxml(indent="    ")

    # Add the XML declaration manually
    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'
    formatted_xml = xml_declaration + pretty_xml.split('\n', 1)[1]  # Remove default declaration
    return formatted_xml

# Example usage
child_items = [
    ('lock', 'Lock'),
    ('suspend', 'Suspend'),
    ('logout', 'Log Out')  # Add more items as needed
]

xml_output_pretty = create_gtk_menu_xml_pretty(child_items)
print(xml_output_pretty)
