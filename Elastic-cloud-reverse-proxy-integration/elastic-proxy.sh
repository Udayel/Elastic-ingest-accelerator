#!/bin/bash -xe
apt-get update -y
apt-get install nginx -y
apt-get install certbot python3-certbot-nginx -y
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

Elastic_Custom_URL=$(echo $Elastic_Custom_URL)
Elastic_Endpoint=$(echo $Elastic_Endpoint)
Elastic_Cluster_ID=$(echo $Elastic_Cluster_ID)
Kibana_Custom_URL=$(echo $Kibana_Custom_URL)
Kibana_Endpoint=$(echo $Kibana_Endpoint)
Kibana_Component_ID=$(echo $Kibana_Component_ID)
DashboardPreloggedInCustomDomainURL=$(echo $DashboardPreloggedInCustomDomainURL)
UserName=$(echo $UserName)
Password=$(echo $Password)
anonymous_access=$(echo $Anonymous_Access)


rm -rf /etc/nginx/nginx.conf
rm -rf /etc/nginx/sites-enabled/default

cd /etc/nginx


# Convert the input to lowercase for case-insensitive comparison
anonymous_access=$(echo "$anonymous_access" | tr '[:upper:]' '[:lower:]')

# Set the content accordingly
if [ "$anonymous_access" == "yes" ]; then
    cat << EOF > /etc/nginx/nginx.conf
# Disable server tokens to improve security
http {
    server_tokens off;
 
    # Don't allow the page to render inside a frame of an iframe
    add_header X-Frame-Options DENY;
 
    # Disable sniffing for user supplied content
    add_header X-Content-Type-Options nosniff;
 
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name _;
 
        location / {
            return 301 https://$host$request_uri;
        }
    }
 
    # Proxy Elasticsearch to have a custom URL
    server {
        listen 443 ssl;
        server_name Elastic_Custom_URL;
 
        ssl_certificate /etc/letsencrypt/live/Elastic_Custom_URL/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/Elastic_Custom_URL/privkey.pem;
 
        location / {
            proxy_pass       Elastic_Endpoint;
            proxy_set_header X-Found-Cluster Elastic_Cluster_ID;
        }
    }
 
    # Proxy Kibana to have a custom URL
    server {
        listen 443 ssl;
        server_name Kibana_Custom_URL;
 
        ssl_certificate /etc/letsencrypt/live/Kibana_Custom_URL/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/Kibana_Custom_URL/privkey.pem;        
 
        location / {
            proxy_pass       Kibana_Endpoint;
            proxy_set_header X-Found-Cluster Kibana_Component_ID;
        }
    }
 
    # Proxy Kibana to a custom URL and anonymous access
    server {
        listen 443 ssl;
        server_name DashboardPreloggedInCustomDomainURL;

        ssl_certificate /etc/letsencrypt/live/DashboardPreloggedInCustomDomainURL/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/DashboardPreloggedInCustomDomainURL/privkey.pem;

 
        location / {
            proxy_pass       Kibana_Endpoint;
            proxy_set_header X-Found-Cluster Kibana_Component_ID;
            proxy_set_header Authorization "Basic Auth_Base64";
            proxy_hide_header Kbn-License-Sig;
            proxy_hide_header Kbn-Name;
            proxy_hide_header Kbn-Xpack-Sig;
            proxy_hide_header X-Cloud-Request-Id;
            proxy_hide_header X-Found-Handling-Cluster;
            proxy_hide_header X-Found-Handling-Instance;
            proxy_hide_header X-Found-Handling-Server;
        }
    }
}
 
events {
    worker_connections 1024;
}
EOF
else
    cat << EOF > /etc/nginx/nginx.conf
# Disable server tokens to improve security
http {
    server_tokens off;
 
    # Don't allow the page to render inside a frame of an iframe
    add_header X-Frame-Options DENY;
 
    # Disable sniffing for user supplied content
    add_header X-Content-Type-Options nosniff;
 
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name _;
 
        location / {
            return 301 https://$host$request_uri;
        }
    }
 
    # Proxy Elasticsearch to have a custom URL
    server {
        listen 443 ssl;
        server_name Elastic_Custom_URL;
 
        ssl_certificate /etc/letsencrypt/live/Elastic_Custom_URL/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/Elastic_Custom_URL/privkey.pem;
 
        location / {
            proxy_pass       Elastic_Endpoint;
            proxy_set_header X-Found-Cluster Elastic_Cluster_ID;
        }
    }
 
    # Proxy Kibana to have a custom URL
    server {
        listen 443 ssl;
        server_name Kibana_Custom_URL;
 
        ssl_certificate /etc/letsencrypt/live/Kibana_Custom_URL/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/Kibana_Custom_URL/privkey.pem;        
 
        location / {
            proxy_pass       Kibana_Endpoint;
            proxy_set_header X-Found-Cluster Kibana_Component_ID;
        }
    }
}
 
events {
    worker_connections 1024;
}
EOF

fi

sudo sed -i "s/Elastic_Custom_URL/$Elastic_Custom_URL/g" /etc/nginx/nginx.conf
sudo sed -i "s|Elastic_Endpoint|$Elastic_Endpoint|g" /etc/nginx/nginx.conf
sudo sed -i "s/Elastic_Cluster_ID/$Elastic_Cluster_ID/g" /etc/nginx/nginx.conf

sudo sed -i "s/Kibana_Custom_URL/$Kibana_Custom_URL/g" /etc/nginx/nginx.conf
sudo sed -i "s|Kibana_Endpoint|$Kibana_Endpoint|g" /etc/nginx/nginx.conf
sudo sed -i "s/Kibana_Component_ID/$Kibana_Component_ID/g" /etc/nginx/nginx.conf

if [ "$anonymous_access" == "yes" ]; then
    Auth_Base64=$(echo -n "$UserName:$Password" | base64)
    sudo sed -i "s/DashboardPreloggedInCustomDomainURL/$DashboardPreloggedInCustomDomainURL/g" /etc/nginx/nginx.conf
    sudo sed -i "s/Auth_Base64/$Auth_Base64/g" /etc/nginx/nginx.conf
fi
