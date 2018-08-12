install rally:
  cmd.run:
    - name: pip3 install esrally

/home/ubuntu/.rally/rally.ini:
  file.managed:
    - source: salt://rally.ini
    - user: ubuntu
    - group: ubuntu
    - mode: 644
    - template: jinja
    - makedirs: True
    - context:
        elasticsearch_host: pillar['elasticsearch_host']

/usr/bin/start-rallyd:
  file.managed:
    - source: salt://start-rallyd
    - user: root
    - group: root
    - mode: 755

/etc/systemd/system/rally.service:
  file.managed:
    - source: salt://rally.service
    - user: root
    - group: root
    - mode: 644

rally:
  service.running
