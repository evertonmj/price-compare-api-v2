
# imports das libs que iremos utlizar
from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from json import dumps

# db_connect = create_engine('sqlite:///exemplo.db')
app = Flask(__name__)
api = Api(app)


class HealthCheck(Resource):
    def get(self):
        result = "I'm alive!"
        return jsonify(result)
    

api.add_resource(HealthCheck, '/health') 

if __name__ == '__main__':
    app.run()