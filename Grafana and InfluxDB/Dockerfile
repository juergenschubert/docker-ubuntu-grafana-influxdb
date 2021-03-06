FROM ubuntu
    MAINTAINER Hitesh Jethva (hitjethva@gmail.com)RUN 
      apt-get update && apt-get -y --no-install-recommends install 
        ca-certificates 
        software-properties-common 
        python-django-tagging 
        python-simplejson 
        python-memcache 
        python-ldap 
        python-cairo 
        python-pysqlite2 
        python-support 
        python-pip 
        gunicorn 
        supervisor 
        nginx-light 
        nodejs 
        git 
        curl 
        openjdk-7-jre 
        build-essential 
        python-dev
WORKDIR /opt
    RUN 
      curl -s -o /opt/grafana-1.8.1.tar.gz http://grafanarel.s3.amazonaws.com/grafana-1.8.1.tar.gz && 
      curl -s -o /opt/influxdb_latest_amd64.deb http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && 
    mkdir /opt/grafana && 
      tar -xzvf grafana-1.8.1.tar.gz --directory /opt/grafana --strip-components=1 && 
      dpkg -i influxdb_latest_amd64.deb && 
      echo "influxdb soft nofile unlimited" >> /etc/security/limits.conf && 
      echo "influxdb hard nofile unlimited" >> /etc/security/limits.conf
ADD config.js /opt/grafana/config.js
    ADD nginx.conf /etc/nginx/nginx.conf
    ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
    ADD types.db /opt/influxdb/current/types.db
    ADD config.toml /opt/influxdb/current/config.toml
VOLUME ["/opt/influxdb/shared/data"]EXPOSE 80 8083 8086 8096
CMD ["supervisord", "-n"]
