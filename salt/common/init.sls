{% set role = grains.id.split('_') | last %}

# Remove variables.txt from /tmp - This is temp
rmvariablesfile:
  file.absent:
    - name: /tmp/variables.txt

# Add socore Group
socoregroup:
  group.present:
    - name: socore
    - gid: 939

# Add socore user
socore:
  user.present:
    - uid: 939
    - gid: 939
    - home: /opt/so
    - createhome: True
    - shell: /bin/bash

soconfperms:
  file.directory:
    - name: /opt/so/conf
    - uid: 939
    - gid: 939
    - dir_mode: 770

sosaltstackperms:
  file.directory:
    - name: /opt/so/saltstack
    - uid: 939
    - gid: 939
    - dir_mode: 770

# Create a state directory
statedir:
  file.directory:
    - name: /opt/so/state
    - user: 939
    - group: 939
    - makedirs: True

salttmp:
  file.directory:
    - name: /opt/so/tmp
    - user: 939
    - group: 939
    - makedirs: True

# Install epel
{% if grains['os'] == 'CentOS' %}
epel:
  pkg.installed:
    - skip_suggestions: True
    - pkgs:
      - epel-release
{% endif %}

# Install common packages
{% if grains['os'] != 'CentOS' %}     
commonpkgs:
  pkg.installed:
    - skip_suggestions: True
    - pkgs:
      - apache2-utils
      - wget
      - ntpdate
      - jq
      - python3-docker
      - docker-ce
      - curl
      - ca-certificates
      - software-properties-common
      - apt-transport-https
      - openssl
      - netcat
      - python3-mysqldb
      - sqlite3
      - argon2
      - libssl-dev
      - python3-dateutil
      - python3-m2crypto
      - python3-mysqldb
      - git
heldpackages:
  pkg.installed:
    - pkgs:
      - containerd.io: 1.2.13-2
      - docker-ce: 5:19.03.12~3-0~ubuntu-{{ grains.oscodename }}
    - hold: True
    - update_holds: True

{% else %}
commonpkgs:
  pkg.installed:
    - skip_suggestions: True
    - pkgs:
      - wget
      - ntpdate
      - bind-utils
      - jq
      - tcpdump
      - httpd-tools
      - net-tools
      - curl
      - sqlite
      - argon2
      - mariadb-devel
      - nmap-ncat
      - python3
      - python36-docker
      - python36-dateutil
      - python36-m2crypto
      - python36-mysql
      - yum-utils
      - device-mapper-persistent-data
      - lvm2
      - openssl
      - git

heldpackages:
  pkg.installed:
    - pkgs:
      - containerd.io: 1.2.13-3.2.el7
      - docker-ce: 3:19.03.11-3.el7
    - hold: True
    - update_holds: True
{% endif %}

# Always keep these packages up to date

alwaysupdated:
  pkg.latest:
    - pkgs:
      - openssl
      - openssh-server
      - bash
    - skip_suggestions: True

# Set time to UTC
Etc/UTC:
  timezone.system

# Docker should always run
docker-ce:
  service.running:
    - enable: True

# Sync some Utilities
utilsyncscripts:
  file.recurse:
    - name: /usr/sbin
    - user: 0
    - group: 0
    - file_mode: 755
    - template: jinja
    - source: salt://common/tools/sbin

{% if role in ['eval', 'standalone', 'sensor', 'heavynode'] %}
# Add sensor cleanup
/usr/sbin/so-sensor-clean:
  cron.present:
    - user: root
    - minute: '*'
    - hour: '*'
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

sensorrotatescript:
  file.managed:
    - name: /usr/local/bin/sensor-rotate
    - source: salt://common/cron/sensor-rotate
    - mode: 755

sensorrotateconf:
  file.managed:
    - name: /opt/so/conf/sensor-rotate.conf
    - source: salt://common/files/sensor-rotate.conf
    - mode: 644

/usr/local/bin/sensor-rotate:
  cron.present:
    - user: root
    - minute: '*'
    - hour: '*'
    - daymonth: '*'
    - month: '*'
    - dayweek: '*'

{% endif %}
