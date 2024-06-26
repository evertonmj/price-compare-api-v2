# imports das libs que iremos utlizar
from flask import Flask, request, jsonify
from flask_restful import Resource, Api
import mysql.connector
import os

DBHOST = os.environ["DBHOST"]
DBPORT = os.environ['DBPORT']
DBUSER = os.environ['DBUSER']
DBPASS = os.environ['DBPASS']
DBNAME = os.environ['DBNAME']

db_connect = mysql.connector.connect(
    host=DBHOST,
    port=DBPORT,
    user=DBUSER,
    password=DBPASS,
    database=DBNAME,
    charset="utf8mb4"
)

app = Flask(__name__)
api = Api(app)

class Users(Resource):
    def get(self):
        conn = db_connect.cursor()
        conn.execute("SELECT id, name, email FROM users")
        result = conn.fetchall()

        return jsonify(result)

    def post(self):
        conn = db_connect.cursor()
        name = request.json['name']
        email = request.json['email']

        insr = "insert into users (id, name, email) values(null, '"+str(name)+"','"+str(email)+"')"
        conn.execute(insr)

        conn.execute('select * from users order by id desc limit 1')
        result = conn.fetchall()
        return jsonify(result)

    def put(self):
        conn = db_connect.cursor()
        id = request.json['id']
        name = request.json['name']
        email = request.json['email']

        updt = "update users set name ='" + str(name) + "', email ='" + str(email) + "'  where id =%d " % int(id)

        conn.execute(updt)
        conn.execute("select * from users where id=%d " % int(id))
        result = conn.fetchall()
        return jsonify(result)


class UserById(Resource):
    def delete(self, id):
        conn = db_connect.cursor()
        conn.execute("delete from users where id=%d " % int(id))
        return {"status": "success"}

    def get(self, id):
        conn = db_connect.cursor()
        conn.execute("select * from users where id =%d " % int(id))
        result = conn.fetchall()
        return jsonify(result)

class HealthCheck(Resource):
    def get(self):
        result = "I'm alive!"
        return jsonify(result)
    

api.add_resource(HealthCheck, '/health')
api.add_resource(Users, '/users')
api.add_resource(UserById, '/users/<id>')

if __name__ == '__main__':
    app.run()