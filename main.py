import os

from flask import Flask, request


app = Flask(__name__)

@app.route('/')
def hello_world():
    name = os.environ.get('NAME', 'World')
    user_agent = request.headers.get('User-Agent')
    return '<h1>Hola {}!</h1><p>Brougth to you from your browser {}</p>'.format(name, user_agent)

@app.route('/user/<name>')
def user(name):
    return '<h1>Hola, {}!</h1>'.format(name)

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))