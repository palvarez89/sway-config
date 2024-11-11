xdg-settings get default-web-browser
xdg-settings set default-web-browser com.google.Chrome.desktop

dnf-automatic config:

```
# /etc/dnf/automatic.conf

[commands]
# Install updates automatically when found
upgrade_type = default
apply_updates = yes

[emitters]
# Log output to syslog for tracking purposes
emit_via = syslog

[base]
# Enable automatic updates
enabled = yes

# Download updates in the background without prompting
download_updates = yes

# Automatically install downloaded updates
upgrade_type = security
random_sleep = 360

# If you want email notifications, set email_to and email_from
# email_to = admin@example.com
# email_from = dnf-automatic@example.com

[download]
# Optional: Use fastest mirror for download speed
fastestmirror = yes
```


