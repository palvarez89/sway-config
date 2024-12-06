#!/bin/env python

import subprocess
import json
import xml.etree.ElementTree as ET
from xml.dom.minidom import parseString

def run_command(command):
    """Run a shell command and return the output as a string."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    result.check_returncode()  # Raise an exception if the command failed
    return result.stdout.strip()

def get_current_sink():
    """Retrieve the current default sink ID and name."""
    try:
        # Get the default sink name
        default_sink_name = run_command(
            "pw-metadata 0 'default.audio.sink' | grep 'value' | sed \"s/.* value:'//;s/' type:.*$//;\""
        )
        default_sink_name = json.loads(default_sink_name)['name']

        # Get the default sink ID
        default_sink_id = run_command(
            f"pw-dump Node Device | jq '.[].info.props|select(.\"node.name\" == \"{default_sink_name}\")|.\"object.id\"'"
        )
        return default_sink_id, default_sink_name
    except Exception as e:
        print(f"Error fetching current sink: {e}")
        return None, None

def get_other_sinks(default_sink_id):
    """Retrieve other sinks excluding the default."""
    try:
        other_sinks = run_command(
            f"pw-dump Node Device | jq '.[].info.props|select(.\"api.alsa.pcm.stream\" == \"playback\")|"
            f"select(.\"object.id\" != {default_sink_id})|{{id: .\"object.id\", nick: .\"node.nick\"}}'"
        )
        return json.loads(f"[{other_sinks}]")
    except Exception as e:
        print(f"Error fetching other sinks: {e}")
        return []

def create_gtk_menu_from_sinks(default_sink_name, other_sinks):
    """Create a GtkMenu XML based on sink information."""
    # Create the root element
    interface = ET.Element('interface')

    # Create the GtkMenu object
    gtk_menu = ET.SubElement(interface, 'object', {'class': 'GtkMenu', 'id': 'menu'})

    # Add the default sink as the first menu item
    default_sink_item = ET.SubElement(gtk_menu, 'child')
    default_sink_object = ET.SubElement(default_sink_item, 'object', {'class': 'GtkMenuItem', 'id': 'default_sink'})
    default_sink_property = ET.SubElement(default_sink_object, 'property', {'name': 'label'})
    default_sink_property.text = f"Default: {default_sink_name}"

    # Add other sinks
    for sink in other_sinks:
        sink_item = ET.SubElement(gtk_menu, 'child')
        sink_object = ET.SubElement(sink_item, 'object', {'class': 'GtkMenuItem', 'id': f"sink_{sink['id']}"})
        sink_property = ET.SubElement(sink_object, 'property', {'name': 'label'})
        sink_property.text = sink['nick']

    # Pretty print the XML
    rough_string = ET.tostring(interface, encoding='unicode', method='xml')
    pretty_xml = parseString(rough_string).toprettyxml(indent="    ")

    # Add the XML declaration manually
    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'
    formatted_xml = xml_declaration + pretty_xml.split('\n', 1)[1]
    return formatted_xml

def main():
    # Get current sink information
    default_sink_id, default_sink_name = get_current_sink()
    if not default_sink_id or not default_sink_name:
        print("Failed to retrieve the current sink.")
        return

    # Get other sinks
    other_sinks = get_other_sinks(default_sink_id)

    # Generate the XML menu
    xml_menu = create_gtk_menu_from_sinks(default_sink_name, other_sinks)

    # Print the resulting XML
    print(xml_menu)

if __name__ == "__main__":
    main()

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
