#!/usr/bin/env python
# -*- coding: utf-8

# Required modules
import os
import json
import logger
import inspect
import datetime
import psycopg2
from pytz import timezone
from psycopg2.pool import ThreadedConnectionPool
from functools import wraps
from threading import Semaphore
from flask import Flask, request, render_template
from hashlib import sha512

########################################################################
# App settings
########################################################################
app = Flask(__name__)
# Jinja2 loopcontrols extension
app.jinja_env.add_extension('jinja2.ext.loopcontrols')
# Set debug mode to False for production
app.debug = False
# Various configuration settings belong here (optionnal)
app.config.from_pyfile('config.local.py')
# Generate a new key: head -n 4096 /dev/urandom | md5sum | cut -d' ' -f1
app.secret_key = 'd2d503ef8e9e686926be213fef06525a'
# GIS SRID used by application
app.SRID = app.config['SRID']

########################################################################
# Logger
########################################################################
Logger = logger.Logger(app.config['LOG_LEVEL'])

########################################################################
# Database connection settings
########################################################################
DB_DB = app.config['DB_DB']
DB_USER = app.config['DB_USER']
DB_PASSWORD = app.config['DB_PASSWORD']
DB_HOST = app.config['DB_HOST']

########################################################################
# Authentication key
########################################################################
AUTH_KEY = app.config['AUTH_KEY']

########################################################################
# Timezone
########################################################################
TZ = timezone('Europe/Paris')

########################################################################
# Database connection and cursor
########################################################################
class ReallyThreadedConnectionPool(ThreadedConnectionPool):
  def __init__(self, minconn, maxconn, *args, **kwargs):
      self._semaphore = Semaphore(maxconn)
      super(ReallyThreadedConnectionPool, self).__init__(minconn, maxconn, *args, **kwargs)

  def getconn(self, *args, **kwargs):
      self._semaphore.acquire()
      return super(ReallyThreadedConnectionPool, self).getconn(*args, **kwargs)

  def putconn(self, *args, **kwargs):
      super(ReallyThreadedConnectionPool, self).putconn(*args, **kwargs)
      self._semaphore.release()

try:
  app.connection_pool = ReallyThreadedConnectionPool(app.config['MIN_POOL_SIZE'],
                                                 app.config['MAX_POOL_SIZE'],
                                                 database=DB_DB,
                                                 password=DB_PASSWORD,
                                                 host=DB_HOST,
                                                 user=DB_USER)
except Exception as e:
  Logger.critical("No connection to database: %s" % e)

def get_db_connection():
  try:
    conn = app.connection_pool.getconn()
    cursor = conn.cursor()
    return (conn, cursor)
  except Exception as e:
    Logger.critical("Unable to get connection from pool: %s" % e)

def release_db_connection(conn, cursor):
  try:
    cursor.close()
    app.connection_pool.putconn(conn)
  except:
    Logger.critical("Unable to release connection: %s" % e)

def db_sanity_check():
  try:
    reqs = ["update regions set cpt = (select count(*) from protesters where rgid=regions.gid);",
            "update departements set cpt = (select count(*) from protesters where dgid=departements.gid);",
            "update communes set cpt = (select count(*) from protesters where cgid=communes.gid);"]
    connection, cursor = get_db_connection()
    for req in reqs:
      cursor.execute(req)
      connection.commit()
    release_db_connection(connection, cursor)
    Logger.warn('Database sanitized')
    return True
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.critical('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return False

########################################################################
# Format to JSON usable by JavaScript
########################################################################
class JSONEncoder(json.JSONEncoder):
  def default(self, o):
    try:
      return json.JSONEncoder.default(self, o)
    except Exception as e:
      Logger.warn('[%s]: %s' % ('JSONEncoder.default()', e))
      return str(o)
  
def jsonify(obj_type, action, result, args):
  """ JSONify response """
  response = {}
  response['type'] = obj_type
  response['action'] = action
  response['result'] = result
  response['args'] = args
  response = JSONEncoder().encode(response)
  return response

########################################################################
# Counters incrementation and decrementation
########################################################################
def increment_gids(rgid, dgid, cgid):
  try:
    reqs = []
    connection, cursor = get_db_connection()
    reqs.append(("update regions set cpt = cpt+1 where gid=%s;", rgid))
    reqs.append(("update departements set cpt = cpt+1 where gid=%s;", dgid))
    reqs.append(("update communes set cpt = cpt+1 where gid=%s;", cgid))
    for req in reqs:
      cursor.execute(req[0], (req[1],))
      connection.commit()
    release_db_connection(connection, cursor)
    return True
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return False

def decrement_gids(rgid, dgid, cgid):
  try:
    reqs = []
    connection, cursor = get_db_connection()
    reqs.append(("update regions set cpt=cpt-1 where gid=%s;", rgid))
    reqs.append(("update departements set cpt=cpt-1 where gid=%s;", dgid))
    reqs.append(("update communes set cpt=cpt-1 where gid=%s;", cgid))
    for req in reqs:
      cursor.execute(req[0], (req[1],))
      connection.commit()
    release_db_connection(connection, cursor)
    return True
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return False

def check_sign_ok(url, uid, position, auth_token):
    complete_url = url + '?' + 'uid=' + uid + '&' + 'position=' + position
    calc_auth_token = sha512(AUTH_KEY + complete_url).hexdigest()
    return calc_auth_token == auth_token

########################################################################
# Routes
########################################################################
@app.errorhandler(404)
def page_not_found(e):
  """ 404 not found """
  return jsonify('Global', 'Error', 'error', '404')

'''
# --  ------------------------------------------------------
# -- Protests ----------------------------------------------
# --  ------------------------------------------------------

@app.route("/protests/add", methods=['GET', 'POST'])
def route_add_protest():
  """ Add protest """
  try:
    nom = request.form['nom']
    description = request.form['description']
    start_date = TZ.localize(datetime.datetime.strptime(request.form['start_date'], '%Y%m%d%H%M'))
    expire_date = TZ.localize(datetime.datetime.strptime(request.form['expire_date'], '%Y%m%d%H%M'))
    req = "insert into protests (nom, description, start_date, expire_date) values (%s, %s, %s, %s) returning id;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (nom, description, start_date, expire_date))
    connection.commit()
    protest_id = cursor.fetchone()[0]
    release_db_connection(connection, cursor)
    protest = {'id': protest_id, 'nom': nom, 'description': description, 'start_date': start_date, 'expire_date': expire_date}
    return jsonify('add', 'protests', 'success', protest)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'protests', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'protests', 'error', e)

@app.route("/protests/get", methods=['GET', 'POST'])
def route_get_protest():
  """ Get protest """
  try:
    protest_id = int(request.form['id'])
    req = "select * from protests where id=%s;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protest_id,))
    protest = cursor.fetchone()
    release_db_connection(connection, cursor)
    if protest:
      r_args = {}
      r_args['id'] = protest[0]
      r_args['nom'] = protest[1]
      r_args['description'] = protest[2]
      r_args['start_date'] = protest[3]
      r_args['expire_date'] = protest[4]
      return jsonify('get', 'protests', 'success', r_args)
    raise Exception('No such a protest')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('get', 'protests', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('get', 'protests', 'error', str(e))

@app.route("/protests/update", methods=['GET', 'POST'])
def route_update_protest():
  """ Update protest """
  try:
    req_template = "UPDATE protests SET ({}) = %s WHERE id = %s returning *;"
    protest_id = int(request.form['id'])
    req_args = {}
    for key in request.form.keys():
      if key in ['start_date', 'expire_date']:
        req_args[key] = TZ.localize(datetime.datetime.strptime(request.form[key], '%Y%m%d%H%M'))
      else:
        req_args[key] = request.form[key]
    req = req_template.format(', '.join(req_args.keys()))
    args = (tuple(req_args.values()),)
    args += (protest_id, )
    connection, cursor = get_db_connection()
    cursor.execute(req, args)
    protest = cursor.fetchone()
    connection.commit()
    release_db_connection(connection, cursor)
    if protest:
      r_args = {}
      r_args['id'] = protest[0]
      r_args['nom'] = protest[1]
      r_args['description'] = protest[2]
      r_args['start_date'] = protest[3]
      r_args['expire_date'] = protest[4]
      return jsonify('get', 'protests', 'success', r_args)
    raise Exception('No such a protest')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('update', 'protests', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('update', 'protests', 'error', str(e))

@app.route("/protests/delete", methods=['GET', 'POST'])
def route_delete_protest():
  """ Delete protest """
  try:
    r_args = {}
    protest_id = int(request.form['id'])
    req = "delete from protests where id=%s returning *;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protest_id,))
    protest = cursor.fetchone()
    connection.commit()
    release_db_connection(connection, cursor)
    if protest:
      r_args = {}
      r_args['id'] = protest[0]
      r_args['nom'] = protest[1]
      r_args['description'] = protest[2]
      r_args['start_date'] = protest[3]
      r_args['expire_date'] = protest[4]
      return jsonify('delete', 'protests', 'success', r_args)
    raise Exception('No such a protest')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('delete', 'protests', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return str(jsonify('delete', 'protests', 'error', str(e)))

@app.route("/protests/list", methods=['GET', 'POST'])
def route_list_protest():
  """ List protests """
  try:
    r_args = {}
    req = "select * from protests;"
    connection, cursor = get_db_connection()
    cursor.execute(req)
    protests = cursor.fetchall()
    release_db_connection(connection, cursor)
    for protest in protests:
      p_id = protest[0]
      p_dict = {'nom': protest[1],
                'description': protest[2],
                'start_date': protest[3],
                'expire_date': protest[4],
               }
      r_args[p_id] = p_dict
    return jsonify('list', 'protests', 'success', r_args)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'protests', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'protests', 'error', str(e))
'''

# --  ------------------------------------------------------
# -- Protesters --------------------------------------------
# --  ------------------------------------------------------

@app.route("/protesters/add", methods=['GET', 'POST'])
def route_add_protester():
  """ Add protester """
  try:
    rgid, dgid, cgid = (None, None, None)
    uid = request.form['uid']
    # Authentication check
    if not check_sign_ok(request.url, uid, request.form['position'], request.form['auth_token']):
        raise Exception('Authentication FAILED while adding a protester')
    lon, lat = request.form['position'].split(',')
    position = 'POINT(%s %s)' % (lon, lat)
    connection, cursor = get_db_connection()
    # Unknown position
    if int(float(lon)) == 0 and int(float(lat)) == 0:
        rgid, dgid, cgid = -1, None, None
    else:
        req_commune = 'select rgid, dgid, gid from communes where ST_Contains(geom, ST_GeomFromText(%s, %s));'
        cursor.execute(req_commune, (position, app.SRID))
        result = cursor.fetchone()
        # Found in France or DOM/TOM
        if result:
            rgid, dgid, cgid = result
        else:
            # Not in France or DOM/TOM
            rgid, dgid, cgid = -2, None, None
    last_seen = TZ.localize(datetime.datetime.now())
    protester = {'uid': uid, 'lon': lon, 'lat': lat, 'position': position, 'last_seen': last_seen}
    if not increment_gids(rgid, dgid, cgid):
        raise Exception('Error while incrementing counters')
    req = "insert into protesters (uid, lon, lat, last_seen, rgid, dgid, cgid) values (%s, %s, %s, %s, %s, %s, %s) returning id;"
    cursor.execute(req, (uid, lon, lat, last_seen, rgid, dgid, cgid))
    protester['rgid'] = rgid
    protester['dgid'] = dgid
    protester['cgid'] = cgid
    connection.commit()
    protester_id = cursor.fetchone()[0]
    release_db_connection(connection, cursor)
    protester['id'] = protester_id
    return jsonify('add', 'protesters', 'success', protester)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    if cgid:
      Logger.error('decrementating (%d, %d, %d) due to following error:' % (rgid, dgid, cgid))
      decrement_gids(rgid, dgid, cgid)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'protesters', 'error', 'Database error')
  except Exception as e:
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'protesters', 'error', str(e))

@app.route("/protesters/get", methods=['GET', 'POST'])
def route_get_protester():
  """ Get protester """
  try:
    protester_uid = request.form['uid']
    req = "select * from protesters where uid=%s;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protester_uid,))
    protester = cursor.fetchone()
    release_db_connection(connection, cursor)
    if protester:
      r_args = {}
      r_args['id'] = protester[0]
      r_args['uid'] = protester[1]
      r_args['lon'] = protester[2]
      r_args['lat'] = protester[3]
      r_args['rgid'] = protester[4]
      r_args['dgid'] = protester[5]
      r_args['cgid'] = protester[6]
      r_args['last_seen'] = protester[7]
      return jsonify('get', 'protesters', 'success', r_args)
    raise Exception('No such a protester')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('get', 'protesters', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('get', 'protesters', 'error', str(e))

'''
@app.route("/protesters/update", methods=['GET', 'POST'])
def route_update_protester():
  """ Update protester position """
  try:
    rrgid, ddgid, ccgid = (None, None, None)
    rgid, dgid, cgid = (None, None, None)
    uid = request.form['uid']
    req_gids = "select rgid, dgid, cgid from protesters where uid=%s;"
    connection, cursor = get_db_connection()
    cursor.execute(req_gids, (uid,))
    result = cursor.fetchone()
    if result:
      rrgid, ddgid, ccgid = result
      if rrgid and ddgid and ccgid and not decrement_gids(rrgid, ddgid, ccgid):
        raise Exception("Error while decrementing counters")
    lon, lat = request.form['position'].split(',')
    position = 'POINT(%s %s)' % (lon, lat)
    req_commune = 'select rgid, dgid, gid from communes where ST_Contains(geom, ST_GeomFromText(%s, %s));'
    cursor.execute(req_commune, (position, app.SRID))
    result = cursor.fetchone()
    if result:
      rgid, dgid, cgid = result
    last_seen = TZ.localize(datetime.datetime.now())
    protester = {'uid': uid, 'lon': lon, 'lat': lat, 'position': position, 'last_seen': last_seen}
    if cgid:
      if not increment_gids(rgid, dgid, cgid):
        raise Exception('Error while incrementing counters')
    req = "update protesters set (lon, lat, last_seen, rgid, dgid, cgid) = (%s, %s, %s, %s, %s, %s) where uid=%s returning id;"
    cursor.execute(req, (lon, lat, last_seen, rgid, dgid, cgid, uid))
    protester['rgid'] = rgid
    protester['dgid'] = dgid
    protester['cgid'] = cgid
    connection.commit()
    protester_id = cursor.fetchone()
    release_db_connection(connection, cursor)
    if protester_id:
      protester['id'] = protester_id[0]
      return jsonify('update', 'protesters', 'success', protester)
    raise Exception('No such a protester')
  except psycopg2.Error as e:
    connection.rollback()
    if ccgid:
      Logger.error('incrementating (%d, %d, %d) due to following error:' % (rgid, dgid, cgid))
      increment_gids(rrgid, ddgid, ccgid)
    if cgid:
      Logger.error('decrementating (%d, %d, %d) due to following error:' % (rgid, dgid, cgid))
      decrement_gids(rrgid, ddgid, ccgid)
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('update', 'protesters', 'error', 'Database error')
  except Exception as e:
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('update', 'protesters', 'error', str(e))

@app.route("/protesters/delete", methods=['GET', 'POST'])
def route_delete_protester():
  """ Delete protester """
  try:
    args = {}
    uid = request.form['uid']
    req = "delete from protesters where uid=%s returning *;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (uid,))
    connection.commit()
    protester = cursor.fetchone()
    release_db_connection(connection, cursor)
    if protester:
      r_args = {}
      r_args['id'] = protester[0]
      r_args['uid'] = protester[1]
      r_args['lon'] = protester[2]
      r_args['lat'] = protester[3]
      r_args['rgid'] = protester[4]
      r_args['dgid'] = protester[5]
      r_args['cgid'] = protester[6]
      r_args['last_seen'] = protester[7]
      return jsonify('delete', 'protesters', 'success', r_args)
    raise Exception('No such a protester')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('delete', 'protesters', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('delete', 'protesters', 'error', str(e))
'''

'''
# --  ------------------------------------------------------
# --  Subscriptions-----------------------------------------
# --  ------------------------------------------------------

@app.route("/subscriptions/add", methods=['GET', 'POST'])
def route_add_subscription():
  """ Add subscription """
  try:
    protest_id = int(request.form['protest_id'])
    protester_id = int(request.form['protester_id'])
    subscription_date = TZ.localize(datetime.datetime.now())
    req = "insert into subscriptions (protest_id, protester_id, subscription_date) values (%s, %s, %s);"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protest_id, protester_id, subscription_date))
    connection.commit()
    release_db_connection(connection, cursor)
    subscription = {'protest_id': protest_id, 'protester_id': protester_id, 'subscription_date': subscription_date}
    return jsonify('add', 'subscriptions', 'success', subscription)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'subscriptions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('add', 'subscriptions', 'error', e)

@app.route("/subscriptions/delete", methods=['GET', 'POST'])
def route_delete_subscription():
  """ Delete subscription """
  try:
    protest_id = int(request.form['protest_id'])
    protester_id = int(request.form['protester_id'])
    req = "delete from subscriptions where protest_id=%s and  protester_id=%s returning *;"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protest_id, protester_id))
    subscription = cursor.fetchone()
    connection.commit()
    release_db_connection(connection, cursor)
    if subscription:
      r_args = {}
      r_args['protest_id'] = subscription[0]
      r_args['protester_id'] = subscription[1]
      r_args['subscription_date'] = subscription[2]
      return jsonify('delete', 'subscription', 'success', r_args)
    raise Exception('No such a subscription')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('delete', 'subscriptions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('delete', 'subscriptions', 'error', e)

@app.route("/subscriptions/list", methods=['GET', 'POST'])
def route_list_subscriptions():
  """ List subscriptions """
  try:
    protester_id = int(request.form['protester_id'])
    req = "select protest_id, subscription_date from subscriptions where protester_id = %s"
    connection, cursor = get_db_connection()
    cursor.execute(req, (protester_id,))
    subscriptions = cursor.fetchall()
    release_db_connection(connection, cursor)
    r_args = {}
    for subscription in subscriptions:
      protest_id = subscription[0]
      subscription_date = subscription[1]
      r_args[protest_id] = {'subscription_date': subscription_date}
    return jsonify('list', 'subscriptions', 'success', r_args)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'subscriptions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'subscriptions', 'error', str(e))
'''

# --  ------------------------------------------------------
# --  Regions ----------------------------------------------
# --  ------------------------------------------------------
'''
@app.route("/regions/svg", methods=['GET', 'POST'])
def route_svg_regions():
  """ Get regions SVG """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, svg from regions where gid = %s;"
      cursor.execute(req, (rgid,))
    else:
      req = "select gid, svg from regions;"
      cursor.execute(req)
    regions = cursor.fetchall()
    release_db_connection(connection, cursor)
    if len(regions) > 0:
      r_args = {}
      for region in regions:
        gid = region[0]
        path = region[1]
        r_args[gid] = {'path': path}
      return jsonify('svg', 'regions', 'success', r_args)
    raise Exception('No such a region')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'regions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'regions', 'error', str(e))
'''

@app.route("/regions/list", methods=['GET', 'POST'])
def route_regions_list():
  """ Returns regions list """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, nom, lon, lat, cpt from regions where gid = %s;"
      cursor.execute(req, (rgid,))
    else:
      req = "select gid, nom, lon, lat, cpt from regions;"
      cursor.execute(req)
    regions = cursor.fetchall()
    release_db_connection(connection, cursor)
    r_args = {}
    for region in regions:
      gid = region[0]
      nom = region[1]
      lon = region[2]
      lat = region[3]
      cpt = region[4]
      r_args[gid] = {'nom': nom, 'lon': lon, 'lat': lat, 'cpt': cpt }
    return jsonify('list', 'regions', 'success', r_args)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'regions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'regions', 'error', str(e))

@app.route("/regions/total", methods=['GET', 'POST'])
def route_regions_total():
  """ Returns overall total """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form['rgid'])
      req = 'select sum(cpt) from regions where gid = %s;'
      cursor.execute(req, (rgid,))
    else:
      req = 'select sum(cpt) from regions;'
      cursor.execute(req)
    total = cursor.fetchone()[0]
    release_db_connection(connection, cursor)
    if total is not None:
      r_args = {'total': total}
      return jsonify('regions', 'total', 'success', r_args)
    raise Exception('Not computable')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'regions', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'regions', 'error', 'Invalid input')

# --  ------------------------------------------------------
# --  Departements------------------------------------------
# --  ------------------------------------------------------
'''
@app.route("/departements/svg", methods=['GET', 'POST'])
def route_svg_departements():
  """ Get departements SVG """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, svg from departements where rgid = %s;"
      cursor.execute(req, (rgid,))
    if 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = "select gid, svg from departements where gid = %s;"
      cursor.execute(req, (dgid,))
    else:
      req = "select gid, svg from departements;"
      cursor.execute(req)
    departements = cursor.fetchall()
    release_db_connection(connection, cursor)
    if len(departements) > 0:
      r_args = {}
      for departement in departements:
        gid = departement[0]
        path = departement[1]
        r_args[gid] = {'path': path}
      return jsonify('svg', 'departements', 'success', r_args)
    raise Exception('No such a departement')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'departements', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'departements', 'error', str(e))
'''

@app.route("/departements/list", methods=['GET', 'POST'])
def route_departements_list():
  """ Returns departements list """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, nom, lon, lat, cpt from departements where rgid = %s;"
      cursor.execute(req, (rgid,))
    elif 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = "select gid, nom, lon, lat, cpt from departements where gid = %s;"
      cursor.execute(req, (dgid,))
    else:
      req = "select gid, nom, lon, lat, cpt from departements;"
      cursor.execute(req)
    departements = cursor.fetchall()
    release_db_connection(connection, cursor)
    r_args = {}
    for departement in departements:
      gid = departement[0]
      nom = departement[1]
      lon = departement[2]
      lat = departement[3]
      cpt = departement[4]
      r_args[gid] = {'nom': nom, 'lon': lon, 'lat': lat, 'cpt': cpt }
    return jsonify('list', 'departements', 'success', r_args)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'departements', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'departements', 'error', str(e))

@app.route("/departements/total", methods=['GET', 'POST'])
def route_departements_total():
  """ Returns overall total """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = 'select sum(cpt) from departements where rgid = %s;'
      cursor.execute(req, (rgid,))
    elif 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = 'select sum(cpt) from departements where gid = %s;'
      cursor.execute(req, (dgid,))
    else:
      req = 'select sum(cpt) from departements;'
      cursor.execute(req)
    total = cursor.fetchone()[0]
    release_db_connection(connection, cursor)
    if total is not None:
      r_args = {'total': total}
      return jsonify('departements', 'total', 'success', r_args)
    raise Exception('Not computable')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'departements', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'departements', 'error', 'Invalid input')

# --  ------------------------------------------------------
# --  Communes ---------------------------------------------
# --  ------------------------------------------------------
'''
@app.route("/communes/svg", methods=['GET', 'POST'])
def route_svg_communes():
  """ Get communes SVG """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, svg from communes where rgid = %s;"
      cursor.execute(req, (rgid,))
    elif 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = "select gid, svg from communes where dgid = %s;"
      cursor.execute(req, (dgid,))
    elif 'cgid' in request.form:
      cgid = int(request.form.get('cgid'))
      req = "select gid, svg from communes where gid = %s;"
      cursor.execute(req, (cgid,))
    else:
      req = "select gid, svg from communes;"
      cursor.execute(req)
    communes = cursor.fetchall()
    release_db_connection(connection, cursor)
    if len(communes) > 0:
      r_args = {}
      for commune in communes:
        gid = commune[0]
        path = commune[1]
        r_args[gid] = {'path': path}
      return jsonify('svg', 'communes', 'success', r_args)
    raise Exception('No such a commune')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'communes', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('svg', 'communes', 'error', str(e))
'''

@app.route("/communes/list", methods=['GET', 'POST'])
def route_communes_list():
  """ Returns communes list """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = "select gid, nom, lon, lat, cpt from communes where rgid = %s;"
      cursor.execute(req, (rgid,))
    elif 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = "select gid, nom, lon, lat, cpt from communes where dgid = %s;"
      cursor.execute(req, (dgid,))
    elif 'cgid' in request.form:
      cgid = int(request.form.get('cgid'))
      req = "select gid, nom, lon, lat, cpt from communes where gid = %s;"
      cursor.execute(req, (cgid,))
    else:
      req = "select gid, nom, lon, lat, cpt from communes;"
      cursor.execute(req)
    communes = cursor.fetchall()
    release_db_connection(connection, cursor)
    r_args = {}
    for commune in communes:
      gid = commune[0]
      nom = commune[1]
      lon = commune[2]
      lat = commune[3]
      cpt = commune[4]
      r_args[gid] = {'nom': nom, 'lon': lon, 'lat': lat, 'cpt': cpt }
    return jsonify('list', 'communes', 'success', r_args)
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'communes', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('list', 'communes', 'error', str(e))

@app.route("/communes/total", methods=['GET', 'POST'])
def route_communes_total():
  """ Returns communes total """
  try:
    connection, cursor = get_db_connection()
    if 'rgid' in request.form:
      rgid = int(request.form.get('rgid'))
      req = 'select sum(cpt) from communes where rgid = %s;'
      cursor.execute(req, (rgid,))
    elif 'dgid' in request.form:
      dgid = int(request.form.get('dgid'))
      req = 'select sum(cpt) from communes where dgid = %s;'
      cursor.execute(req, (dgid,))
    elif 'cgid' in request.form:
      cgid = int(request.form.get('cgid'))
      req = 'select sum(cpt) from communes where gid = %s;'
      cursor.execute(req, (cgid,))
    else:
      req = 'select sum(cpt) from communes;'
      cursor.execute(req)
    total = cursor.fetchone()[0]
    release_db_connection(connection, cursor)
    if total is not None:
      r_args = {'total': total}
      return jsonify('communes', 'total', 'success', r_args)
    raise Exception('Not computable')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'communes', 'error', 'Database error')
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('total', 'communes', 'error', 'Invalid input')

########################################################################
# Tools
########################################################################
'''
@app.route("/tools/convert/deg2dec", methods=['GET', 'POST'])
def route_convert_deg2dec():
  """ Converts coordinates from degrees/min/sec to decimal coordinates.
      Parameters:
        - latitude: String in deg.min.sec.direction format (i.e: 2.31.42.E) ;
        - longitude: String in deg.min.sec.direction format (i.e: 51.04.18.N)
  """
  directions = {'N': 1, 'S': -1, 'E': 1, 'W': -1}
  try:
    args = {}
    args['lon'] = request.form['lon'].split('.')
    args['lat'] = request.form['lat'].split('.')
    if len(args['lon']) == 4 and len(args['lat']) == 4:
      degrees, minutes, seconds, direction = args['lon']
      minutes = float(minutes)/60
      seconds = float(seconds)/3600
      args['lon'] = (float(degrees) + minutes + seconds) * directions[direction]
      degrees, minutes, seconds, direction = args['lat']
      minutes = float(minutes)/60
      seconds = float(seconds)/3600
      args['lat'] = (float(degrees) + minutes + seconds) * directions[direction]
      return jsonify('convert', 'deg2dec', 'success', args)
    raise Exception("Invalid input")
  except KeyError as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('convert', 'deg2dec', 'error', 'Invalid input')  
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('convert', 'deg2dec', 'error', str(e))  
'''

@app.route("/tools/localize", methods=['GET', 'POST'])
def route_localize():
  """ Returns rgid, dgid, cgid from position """
  try:
    connection, cursor = get_db_connection()
    rgid, dgid, cgid = (None, None, None)
    lon, lat = request.form['position'].split(',')
    position = 'POINT(%s %s)' % (lon, lat)
    req_commune = 'select rgid, dgid, gid from communes where ST_Contains(geom, ST_GeomFromText(%s, %s));'
    cursor.execute(req_commune, (position, app.SRID))
    result = cursor.fetchone()
    if result:
      rgid, dgid, cgid = result
      r_args = {'rgid': rgid, 'dgid': dgid, 'cgid': cgid, 'position': position}
      return jsonify('localize', 'localize', 'success', r_args)
    raise Exception('Out of perimeter')
  except psycopg2.Error as e:
    connection.rollback()
    release_db_connection(connection, cursor)
    Logger.error('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('localize', 'localize', 'error', 'Database error')  
  except KeyError as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('localize', 'localize', 'error', 'Invalid input')  
  except Exception as e:
    Logger.warn('[%s]: %s' % (inspect.currentframe().f_code.co_name, e))
    return jsonify('localize', 'localize', 'error', str(e))  

########################################################################
# Main
########################################################################
if __name__ == '__main__':
  if db_sanity_check():
    app.run(host=app.config['INTERFACE'], port=app.config['PORT'])
