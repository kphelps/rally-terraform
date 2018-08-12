install elasticsearch:
  pkg.installed:
    - sources:
        - elasticsearch: https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.3.2.deb

/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://elasticsearch.yml
    - user: root
    - group: root
    - mode: 644

/etc/elasticsearch/jvm.options:
  file.managed:
    - source: salt://elasticsearch.jvm.options
    - user: root
    - group: root
    - mode: 644

elasticsearch:
  service.running:
    - enable: True
    - reload: True
