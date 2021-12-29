#!/bin/bash
yum -y update
yum -y install httpd


myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor="black">
<h2><font color="gold">Hello to DevOps from Terraform<font color="red"> v 1.1.2</font></h2><br><p>

</body>
</html>
EOF

sudo service httpd start
chkconfig httpd on