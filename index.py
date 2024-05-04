
# imports das libs que iremos utlizar
from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from sqlalchemy import create_engine, text

db_connect = create_engine("mysql+pymysql://root:p4ssw0rd@localhost:33061/price-compare-db-mysql?charset=utf8mb4")
app = Flask(__name__)
api = Api(app)

class Users(Resource):
    def get(self):
        conn = db_connect.connect()
        query = conn.execute(text("select * from users"))
        result = [dict(zip(tuple(query.keys()), i)) for i in query.cursor]
        return jsonify(result)

    def post(self):
        conn = db_connect.connect()
        name = request.json['name']
        email = request.json['email']

        conn.execute(
            text("insert into users values(null, '"+str(name)+"','"+str(email)+"')"))


        query = conn.execute(text('select * from users order by id desc limit 1'))
        result = [dict(zip(tuple(query.keys()), i)) for i in query.cursor]
        return jsonify(result)

    def put(self):
        conn = db_connect.connect()
        id = request.json['id']
        name = request.json['name']
        email = request.json['email']

        conn.execute(text("update users set name ='" + str(name) +
                     "', email ='" + str(email) + "'  where id =%d " % int(id)))

        query = conn.execute(text("select * from users where id=%d " % int(id)))
        result = [dict(zip(tuple(query.keys()), i)) for i in query.cursor]
        return jsonify(result)


class UserById(Resource):
    def delete(self, id):
        conn = db_connect.connect()
        conn.execute(text("delete from users where id=%d " % int(id)))
        return {"status": "success"}

    def get(self, id):
        conn = db_connect.connect()
        query = conn.execute(text("select * from users where id =%d " % int(id)))
        result = [dict(zip(tuple(query.keys()), i)) for i in query.cursor]
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