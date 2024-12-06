#!/bin/env python

import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

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
