install kibana:
  pkg.installed:
    - sources:
      - kibana: https://artifacts.elastic.co/downloads/kibana/kibana-6.3.2-amd64.deb

/etc/kibana/kibana.yml:
  file.managed:
    - source: salt://kibana.yml
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        elasticsearch_host: {{ pillar['elasticsearch_host'] }}

kibana:
  service.running:
    - enable: True
    - reload: True
