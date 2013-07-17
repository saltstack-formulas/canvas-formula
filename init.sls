# This SLS is based on the steps outlined in:
# https://github.com/instructure/canvas-lms/wiki/Production-Start
# Because that document is based on Debian/Ubuntu, this SLS is too
# (for the moment)

include:
  - postgres
  - ruby
  - node

# Sets up the databases and users
canvas-dbuser:
  postgres_user:
    - present
    - name: canvas
    - createdb: False
    - superuser: False
    - password: badpass

canvas_production:
  postgres_database:
    - present
    - owner: canvas
    - require:
      - postgres_user: canvas-dbuser

canvas_queue_production:
  postgres_database:
    - present
    - owner: canvas
    - require:
      - postgres_user: canvas-dbuser


# The next stanzas work together to download and install the latest stable
/tmp/canvas-stable.tar.gz:
  file:
    - managed
    - source_hash: md5=ab6880705a666becfc9fb95495352291
    - source: http://www.instructure.com/code/canvas-stable.tar.gz
    - unless: "[ -e /tmp/canvas-stable.tar.gz ]"

unpack-canvas:
  cmd:
    - run
    - name: "/bin/tar -zxf /tmp/canvas-stable.tar.gz -C /tmp"
    - require:
      - file: /tmp/canvas-stable.tar.gz
    - unless: "[ -e /var/canvas/config.ru ]"

move-canvas:
  cmd:
    - run
    - name: "mv /tmp/instructure-canvas-lms* /var/canvas"
    - require:
      - cmd: unpack-canvas
    - unless: "[ -e /var/canvas/config.ru ]"

# Install canvas dependencies
python-software-properties:
  pkg.installed

brightbox/ruby-ng:
  pkgrepo.managed:
    - ppa: brightbox/ruby-ng
    - requires:
        pkg: python-software-properties

canvas-packages:
  pkg.installed:
    - pkgs:
      - zlib1g-dev
      - libxml2-dev
      - libmysqlclient-dev
      - libxslt1-dev
      - imagemagick
      - libpq-dev
      - libxmlsec1-dev
      - libcurl4-gnutls-dev
      - libxmlsec1
      - openjdk-7-jre
    - refresh: True
    - require:
      - pkgrepo: brightbox/ruby-ng

bundler:    
  gem.installed    
     
install-bundler:    
  cmd:    
    - run    
    - name: "bundle install --path vendor/bundle --without=sqlite"     
    - require:    
      - gem: bundler    
    - cwd: /var/canvas    
    - unless: "[ -e /var/canvas/.bundle/config ]"
