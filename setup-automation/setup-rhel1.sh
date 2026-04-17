#!/bin/bash

dnf remove -y tmux
systemctl stop dnf-automatic-install.timer
systemctl disable dnf-automatic-install.timer
systemctl mask dnf-automatic-install.timer

# Generate SELinux denials for lab demonstration.
# Write a script to a non-standard location and serve HTTP from a non-standard port/dir.
cat > /root/selinux-tripwire.sh << 'TRIPWIRE'
#!/bin/sh

# 1. Write web content to a location with the wrong SELinux context (home dir instead of /var/www).
mkdir -p /root/webapp
echo "<h1>Super-Business Internal Portal</h1>" > /root/webapp/index.html

# 2. Start httpd on a non-standard port (8484) serving from the wrong directory.
dnf install -y httpd
cat > /etc/httpd/conf.d/tripwire.conf << 'CONF'
Listen 8484
<VirtualHost *:8484>
    DocumentRoot "/root/webapp"
    <Directory "/root/webapp">
        Require all granted
    </Directory>
</VirtualHost>
CONF
# This will generate AVCs: httpd reading content with user_home_t and binding to a non-standard port.
systemctl restart httpd || true

# 3. Write a script into /var/www/html and try to execute it (httpd_sys_content_t can't exec).
echo '#!/bin/sh' > /var/www/html/run.sh
echo 'echo "running from webroot"' >> /var/www/html/run.sh
chmod +x /var/www/html/run.sh
/var/www/html/run.sh || true

# 4. Use netcat to listen on a privileged port from /tmp (tmp_t context).
cp /usr/bin/nc /tmp/nc-sneaky
/tmp/nc-sneaky -l 8485 &
SNEAKY_PID=$!
sleep 1
kill $SNEAKY_PID 2>/dev/null || true

TRIPWIRE

chmod +x /root/selinux-tripwire.sh
/root/selinux-tripwire.sh
