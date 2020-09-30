import os, socket, platform

from flask import Flask, request, make_response, render_template


app = Flask(__name__)

@app.route('/')
def hello_world():
    name = os.environ.get('NAME', 'World')
    hostname = socket.gethostname()
    host_info = {
        'hostname': socket.gethostname(),
        'system': platform.platform(),
        'release': platform.release(),
        'version': platform.version()
    }
    user_agent = request.headers.get('User-Agent')
    return render_template('index.html', user_agent=user_agent, name=name, host_info=host_info)

@app.route('/cookie')
def set_cookie():
    response = make_response('<h1>This document carries a cookie!</h1>')
    response.set_cookie('answer', '42')
    return response

@app.route('/user/<name>')
def user(name):
    return render_template('user.html', name=name)

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))